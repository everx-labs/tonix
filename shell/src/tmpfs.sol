pragma ton-solidity >= 0.55.0;

import "../lib/SyncFS.sol";
import "Utility.sol";

contract tmpfs is Utility {

    function fopen(Session session, ParsedCommand pc, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 device_id;
        string path = pc.stdout_redirect;
        inodes = inodes_in;
        data = data_in;
        (, uint16 uid, uint16 gid, , , , , ) = session.unpack();
        (, , uint16 parent, uint16 dir_index) = _resolve_relative_path(path, session.wd, inodes_in, data_in);
        if (dir_index == 0) {
            ic = _get_inode_count(inodes);
            (inodes[ic], data[ic]) = _get_any_node(FT_REG_FILE, uid, gid, device_id, 0, path, "");
            string dirent = _dir_entry_line(ic, path, FT_REG_FILE);
            data[parent].append(dirent);
            Inode parent_dir_node = inodes[parent];
            parent_dir_node.file_size = dirent.byteLength();
            parent_dir_node.n_links++;
            inodes[parent] = parent_dir_node;
            inodes[SB_INODES] = _claim_inodes_and_blocks(inodes[SB_INODES], 1, 0);
        }
    }

    function fwrite(Session /*session*/, ParsedCommand /*pc*/, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in, uint16 ic, string text) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        inodes = inodes_in;
        data = data_in;
        data[ic].append(text);
    }

    function fclose(Session /*session*/, ParsedCommand /*pc*/, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in, uint16 ic) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        inodes = inodes_in;
        data = data_in;
        Inode inode = inodes[ic];
        bytes bts = data[ic];
        uint data_size = bts.length;
        inode.file_size = uint32(data_size);
        uint16 block_size = 100;
        uint16 n_blocks = uint16(data_size / block_size + 1);
        inode.n_blocks = n_blocks;
        inode.modified_at = now;
        inode.last_modified = now;
        inodes[ic] = inode;
        inodes[SB_INODES] = _claim_inodes_and_blocks(inodes[SB_INODES], 0, n_blocks);
    }

    function handle_action(string env, Action file_action, Ar[] ars, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 device_id;
        uint16 block_size = 100;
        (uint16 uid, uint16 gid) = _get_user_data(env);
        (uint8 at, uint16 n_files) = file_action.unpack();
        inodes = inodes_in;
        data = data_in;
        mapping (uint16 => Inode) inodes_diff;
        mapping (uint16 => bytes) data_diff;
        uint16 inode_count = _get_inode_count(inodes);
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
                    uint16 n_blocks = uint16(text.byteLength() / block_size + 1);
                    (inodes_diff[counter], data[counter]) = _get_any_node(FT_REG_FILE, uid, gid, device_id, n_blocks, path, text);
                    counter++;
                    total_blocks += n_blocks;
                }
                else if (ar_type == IO_MKDIR) {
                    (inodes_diff[counter], data[counter]) = _get_any_node(FT_DIR, uid, gid, device_id, 1, path, text);
                    total_blocks++;
                    counter++;
                } else if (ar_type == IO_SET_ARCHIVE_HEADER) {
                    Inode archive_node = inodes[index];
                    archive_node.file_size = text.byteLength();
                    inodes_diff[index] = archive_node;
                    data_diff[index] = text;
                } else if (ar_type == IO_ADD_DIR_ENTRY) {
                    Inode parent_dir_node = inodes[index];
                    bytes parent_dir_data = data[index];
                    parent_dir_node.file_size += text.byteLength();
                    parent_dir_node.n_links += n_files;
                    parent_dir_node.modified_at = now;
                    parent_dir_node.last_modified = now;
                    inodes_diff[index] = parent_dir_node;
                    parent_dir_data.append(text);
                    data_diff[index] = parent_dir_data;
                } else if (ar_type == IO_UPDATE_DIR_ENTRY || ar_type == IO_UPDATE_TEXT_DATA) {
                    Inode parent_dir_node = inodes[index];
                    parent_dir_node.file_size = text.byteLength();
                    inodes_diff[index] = parent_dir_node;
                    data_diff[index] = text;
                } else if (ar_type == IO_BASELINE) {
                } else if (ar_type == IO_WR_COPY) {
                    uint b_count;
                    bytes b_contents;

                    if (index > 0)
                        b_contents = data[index];
                    total_blocks += b_count;

                    Inode file_copy_inode = inodes[index];
                    file_copy_inode.modified_at = now;
                    file_copy_inode.last_modified = now;
                    file_copy_inode.owner_id = uid;
                    file_copy_inode.group_id = gid;
                    file_copy_inode.file_name = path;
                    inodes_diff[counter] = file_copy_inode;
                    data_diff[counter] = b_contents;
                    counter++;
                } else if (ar_type == IO_UNLINK) {
                    Inode victim_inode = inodes[index];
                    victim_inode.n_links--;
                    if (victim_inode.n_links == 0) {
                        delete inodes[index];
                        delete data[index];
                    } else
                        inodes_diff[index] = victim_inode;
                } else if (ar_type == IO_HARDLINK) {
                    Inode source_inode = inodes[index];
                    source_inode.n_links++;
                    source_inode.last_modified = now;
                    inodes_diff[index] = source_inode;
                } else if (ar_type == IO_UPDATE_TIME) {
                    Inode source_inode = inodes[index];
                    source_inode.last_modified = now;
                    inodes_diff[index] = source_inode;
                } else if (ar_type == UA_ADD_USER || ar_type == UA_ADD_GROUP) {
                    Inode passwd_node = inodes[index];
                    bytes passwd_data = data[index];
                    passwd_node.file_size += text.byteLength();
                    uint16 n_blocks = uint16(text.byteLength() / block_size + 1);
                    passwd_node.n_links += n_files;
                    passwd_node.n_blocks = n_blocks;
                    total_blocks += n_blocks;
                    passwd_node.modified_at = now;
                    passwd_node.last_modified = now;
                    inodes_diff[index] = passwd_node;
                    passwd_data.append(text);
                    data_diff[index] = passwd_data;
                }
            }
        }
        inodes_diff[SB_INODES] = _claim_inodes_and_blocks(inodes[SB_INODES], n_files, uint16(total_blocks));

        for ((uint16 index, Inode inode): inodes_diff)
            inodes[index] = inode;
        for ((uint16 index, bytes b_data): data_diff)
            data[index] = b_data;
    }

    /* Mount a set of index nodes to the specified mount point of the primary file system */
    function mount_dir(uint16 mount_point_index, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        mapping (uint16 => Inode) inn = inodes_in;
        mapping (uint16 => bytes) b_data = data_in;
        uint16 inode_count = _get_inode_count(inodes_in);
        uint16 block_size;// = block_size;
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
//        inn[SB_INODES] = _claim_inodes_and_blocks(inodes[SB_INODES], n_inodes, total_blocks);

        for ((uint16 index, Inode inode): inn)
            inodes[index] = inode;
        for ((uint16 index, bytes bts): data)
            data[index] = bts;
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("tmpfs", "emporary file system", "[OPTION]... FILE...",
            "Used for file system operations testing.",
            "cm", 1, M, [
            "do not create any files",
            "change only the modification time"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tmpfs",
"[OPTION]... FILE...",
"temporary file system",
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
