pragma ton-solidity >= 0.62.0;

import "Utility.sol";
import "aio.sol";
import "fs.sol";
/* Generic block device hosting a generic file system */
contract tfs is Utility {

    mapping (uint16 => Inode) _inodes;
    mapping (uint16 => bytes) public _data;
    uint16 _block_size;
    uint16 _device_id;

    function get_inodes() external view returns (mapping (uint16 => Inode) inodes) {
        inodes = _inodes;
    }

    function init_fs(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external accept {
        _inodes = inodes;
        _data = data;
        _device_id = inodes[sb.SB_INFO].device_id;
        _block_size = inodes[sb.SB_INFO].n_blocks;
    }

    function apply_changes(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external accept {
        for ((uint16 index, Inode inode): inodes)
            _inodes[index] = inode;
        for ((uint16 index, bytes bts): data)
            _data[index] = bts;
    }

    function handle_action(string env, Ar[] ars) external accept {
        _handle_action(env, ars);
    }

    function dump_fs_out(uint16 mode) external view returns (string out) {
        uint16 level = mode & 0xFF;
        uint16 form = (mode >> 8) & 0xFF;
        return inode.dumpfs(level, form, _inodes, _data);
    }

    function _handle_action(string env, Ar[] ars) internal {
        /*string[] ev = e.get_env();
        uint16 uid = libenv.getuid(ev);
        uint16 eid = libenv.geteuid(ev);
        uint16 gid = libenv.getgid(ev);*/

        //(uint16 uid, uint16 gid) = arg.get_user_data(env);
        uint16 uid;
        uint16 gid;
        uint16 n_files;
        mapping (uint16 => Inode) inn;
        mapping (uint16 => bytes) data;
        uint16 inode_count = sb.get_inode_count(_inodes);
        uint16 counter = inode_count;

        uint total_blocks;

        uint n_ars = ars.length;
        for (uint i = 0; i < n_ars; i++) {
            (uint8 ar_type, uint16 index, string path, string text) = ars[i].unpack();
            if (ar_type == aio.MKFILE) {
                (inn[counter], data[counter]) = inode.get_any_node(libstat.FT_REG_FILE, uid, gid, _device_id, uint16(text.byteLength() / _block_size), path, text);
                counter++;
            } else if (ar_type == aio.MKDIR) {
                (inn[counter], data[counter]) = inode.get_any_node(libstat.FT_DIR, uid, gid, _device_id, 1, path, text);
                counter++;
            } else if (ar_type == aio.ADD_DIR_ENTRY) {
                Inode parent_dir_node = _inodes[index];
                bytes parent_dir_data = _data[index];
                parent_dir_node.file_size += text.byteLength();
                inn[index] = parent_dir_node;
                parent_dir_data.append(text);
                data[index] = parent_dir_data;
            } else if (ar_type == aio.UPDATE_DIR_ENTRY || ar_type == aio.UPDATE_TEXT_DATA) {
                Inode parent_dir_node = _inodes[index];
                parent_dir_node.file_size = text.byteLength();
                inn[index] = parent_dir_node;
                data[index] = text;
            } else if (ar_type == aio.WR_COPY) {
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
            } else if (ar_type == aio.UNLINK) {
                Inode victim_inode = _inodes[index];
                victim_inode.n_links--;
                if (victim_inode.n_links == 0) {
                    delete _inodes[index];
                    delete _data[index];
                } else
                    inn[index] = victim_inode;
            } else if (ar_type == aio.HARDLINK) {
                Inode source_inode = _inodes[index];
                source_inode.n_links++;
                source_inode.modified_at = now;
                inn[index] = source_inode;
            } else if (ar_type == aio.UPDATE_TIME) {
                Inode source_inode = _inodes[index];
                source_inode.modified_at = now;
                inn[index] = source_inode;
            }
        }
        inn[sb.SB_INODES] = sb.claim_inodes_and_blocks(_inodes[sb.SB_INODES], n_files, uint16(total_blocks));
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
        inn[mount_point_index] = inodes[sb.ROOT_DIR];
        inn[sb.SB_INODES] = sb.claim_inodes_and_blocks(_inodes[sb.SB_INODES], n_inodes, total_blocks);

        for ((uint16 index, Inode inode): inn)
            _inodes[index] = inode;
        for ((uint16 index, bytes bts): data)
            _data[index] = bts;
    }

    /*function write_to_file(string env, string path, string text) external accept {
        (uint16 uid, uint16 gid) = arg.get_user_data(env);
        uint16 counter = sb.get_inode_count(_inodes);

        (_inodes[counter], _data[counter]) = inode.get_any_node(libstat.FT_REG_FILE, uid, gid, _device_id, uint16(text.byteLength() / _block_size), path, text);
    }*/

    function remove_node(uint16 parent, uint16 victim) external accept {
        delete _inodes[victim];

        if (_inodes[parent].n_links < 2)
            delete _inodes[parent];
    }

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return inode.dump_fs(level, _inodes, _data);
    }

    /* Index node operations helpers */
    function _is_add(uint8 t) internal pure returns (bool) {
        return t == aio.WR_COPY || t == aio.MKFILE || t == aio.ALLOCATE || t == aio.MKDIR || t == aio.SYMLINK;
    }

    function _is_update(uint8 t) internal pure returns (bool) {
        return t == aio.CHATTR || t == aio.ACCESS || t == aio.PERMISSION || t == aio.UPDATE_TIME || t == aio.UNLINK || t == aio.HARDLINK || t == aio.TRUNCATE || t == aio.UPDATE_TEXT_DATA;
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
"0.03");
    }
}
