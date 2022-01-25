pragma ton-solidity >= 0.51.0;

import "../lib/SyncFS.sol";
import "Utility.sol";

/* Generic block device hosting a generic file system */
contract tfs is SyncFS, Utility {

    uint16 constant STG_NONE    = 0;
    uint16 constant STG_PRIMARY = 1;
    uint16 constant STG_INODE   = 2;
    uint16 constant STG_ALT     = 4;
    uint16 constant STG_LOCAL   = 8;
    uint16 constant STG_SYNC    = 16;
    uint16 constant STG_TMP     = 32;
    uint16 constant STG_RO      = 64;

    function handle_action(Session session, Action file_action, Ar[] ars) external accept {
        _handle_action(session, file_action, ars);
    }

    function dump_fs_out(uint16 mode) external view returns (string out) {
        uint16 level = mode & 0xFF;
        uint16 form = (mode >> 8) & 0xFF;
        return fs.dumpfs(level, form, _inodes, _data);
    }

    function _handle_action(Session session, Action file_action, Ar[] ars) internal {
        (, uint16 uid, uint16 gid, , , , , ) = session.unpack();
        (uint8 at, uint16 n_files) = file_action.unpack();
        mapping (uint16 => Inode) inn;
        mapping (uint16 => bytes) data;
        uint16 inode_count = sb.get_inode_count(_inodes);
        uint16 counter = inode_count;

        uint total_blocks;

        uint n_ars = ars.length;
        if (at == IO_CREATE_ARCHIVE || at == IO_ADD_FILES_TO_ARCHIVE || at == IO_APPEND_ARCHIVE || at == IO_CREATE_FILES || at == IO_UPDATE_NODE ||
            at == IO_COPY_FILES || at == IO_MOVE_FILES || at == IO_HARDLINK_FILES || at == IO_SYMLINK_FILES || at == IO_UNLINK_FILES ||
            at == IO_CHANGE_OWNER || at == IO_CHANGE_GROUP || at == IO_CHANGE_MODE || at == UA_ADD_USER || at == UA_ADD_GROUP || at == UA_DELETE_USER ||
            at == UA_DELETE_GROUP || at == UA_UPDATE_USER || at == UA_UPDATE_GROUP || at == UA_RENAME_GROUP || at == UA_CHANGE_GROUP_ID) {
            for (uint i = 0; i < n_ars; i++) {
                (uint8 ar_type, , uint16 index, /*uint16 dir_index*/, string path, string text) = ars[i].unpack();
                if (ar_type == IO_MKFILE) {
                    (inn[counter], data[counter]) = inode.get_any_node(FT_REG_FILE, uid, gid, _device_id, uint16(text.byteLength() / _block_size), path, text);
                    counter++;
                }
                else if (ar_type == IO_MKDIR) {
                    (inn[counter], data[counter]) = inode.get_any_node(FT_DIR, uid, gid, _device_id, 1, path, text);
                    counter++;
                } else if (ar_type == IO_SET_ARCHIVE_HEADER) {
                    Inode archive_node = _inodes[index];
                    archive_node.file_size = text.byteLength();
                    inn[index] = archive_node;
                    data[index] = text;
                } else if (ar_type == IO_ADD_DIR_ENTRY) {
                    Inode parent_dir_node = _inodes[index];
                    bytes parent_dir_data = _data[index];
                    parent_dir_node.file_size += text.byteLength();
                    parent_dir_node.n_links += n_files;
                    inn[index] = parent_dir_node;
                    parent_dir_data.append(text);
                    data[index] = parent_dir_data;
                } else if (ar_type == IO_UPDATE_DIR_ENTRY || ar_type == IO_UPDATE_TEXT_DATA) {
                    Inode parent_dir_node = _inodes[index];
                    parent_dir_node.file_size = text.byteLength();
                    inn[index] = parent_dir_node;
                    data[index] = text;
                } else if (ar_type == IO_BASELINE) {
                } else if (ar_type == IO_WR_COPY) {
                    uint b_count;
                    bytes b_contents;

                    if (index > 0)
                        b_contents = _data[index];
                    total_blocks += b_count;

                    Inode file_copy_inode = _inodes[index];
                    file_copy_inode.modified_at = now;
                    file_copy_inode.last_modified = now;
                    file_copy_inode.owner_id = uid;
                    file_copy_inode.group_id = gid;
                    file_copy_inode.file_name = path;
                    inn[counter] = file_copy_inode;
                    data[counter] = b_contents;
                    counter++;
                } else if (ar_type == IO_UNLINK) {
                    Inode victim_inode = _inodes[index];
                    victim_inode.n_links--;
                    if (victim_inode.n_links == 0) {
                        delete _inodes[index];
                        delete _data[index];
                    } else
                        inn[index] = victim_inode;
                } else if (ar_type == IO_HARDLINK) {
                    Inode source_inode = _inodes[index];
                    source_inode.n_links++;
                    source_inode.modified_at = now;
                    inn[index] = source_inode;
                } else if (ar_type == IO_UPDATE_TIME) {
                    Inode source_inode = _inodes[index];
                    source_inode.modified_at = now;
                    inn[index] = source_inode;
                } else if (ar_type == UA_ADD_USER || ar_type == UA_ADD_GROUP) {
                    Inode passwd_node = _inodes[index];
                    bytes passwd_data = _data[index];
                    passwd_node.file_size += text.byteLength();
                    passwd_node.n_links += n_files;
                    inn[index] = passwd_node;
                    passwd_data.append(text);
                    data[index] = passwd_data;
                }
            }
        }
        inn[SB_INODES] = sb.claim_inodes_and_blocks(_inodes[SB_INODES], n_files, uint16(total_blocks));

        for ((uint16 index, Inode inode): inn)
            _inodes[index] = inode;
        for ((uint16 index, bytes b_data): data)
            _data[index] = b_data;
    }

    /* Mount a set of index nodes to the specified mount point of the primary file system */
    function mount_dir(uint16 mount_point_index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external accept {
        mapping (uint16 => Inode) inn;
        mapping (uint16 => bytes) b_data;
        uint16 inode_count = sb.get_inode_count(_inodes);
        uint16 block_size = _block_size;
        uint16 counter = inode_count;
        uint total_blocks;
        uint n_inodes;

        for ((uint16 i, Inode inode): inodes) {
            inn[counter + i] = inode;
            n_inodes++;
        }
        for ((uint16 i, bytes bts): data) {
            b_data[counter + i] = bts;
            total_blocks += bts.length / block_size + 1;
        }
        inn[mount_point_index] = inodes[ROOT_DIR];
        inn[SB_INODES] = sb.claim_inodes_and_blocks(_inodes[SB_INODES], n_inodes, total_blocks);

        for ((uint16 index, Inode inode): inn)
            _inodes[index] = inode;
        for ((uint16 index, bytes bts): data)
            _data[index] = bts;
    }

    function write_to_file(Session session, string path, string text) external accept {
        (uint16 uid, uint16 gid, ) = (session.uid, session.gid, session.wd);
        uint16 counter = sb.get_inode_count(_inodes);

        (_inodes[counter], _data[counter]) = inode.get_any_node(FT_REG_FILE, uid, gid, _device_id, uint16(text.byteLength() / _block_size), path, text);
//        _append_dir_entry(wd, counter, path, FT_REG_FILE);
    }

    function remove_node(uint16 parent, uint16 victim) external accept {
        delete _inodes[victim];

        if (_inodes[parent].n_links < 2)
            delete _inodes[parent];
    }

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return fs.dump_fs(level, _inodes, _data);
    }

    /* Index node operations helpers */
    function _is_add(uint8 t) internal pure returns (bool) {
        return t == IO_WR_COPY || t == IO_MKFILE || t == IO_ALLOCATE || t == IO_MKDIR || t == IO_SYMLINK;
    }

    function _is_update(uint8 t) internal pure returns (bool) {
        return t == IO_CHATTR || t == IO_ACCESS || t == IO_PERMISSION || t == IO_UPDATE_TIME || t == IO_UNLINK || t == IO_HARDLINK || t == IO_TRUNCATE || t == IO_UPDATE_TEXT_DATA;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tfs",
"[OPTION]... FILE...",
"test file system",
"Used for file system operations testing.",
"-c      do not create any files\n\
-m      change only the modification time",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
