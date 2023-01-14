pragma ton-solidity >= 0.57.0;

import "udirent.sol";
import "path.sol";
import "libstat.sol";

library fs {

    using libstat for s_stat;
    uint16 constant FS_IO_BLOCK     = 100;

    /*function fstat(Inode ino) internal returns (s_stat buf) {
        buf = fd.stat(ino);
    }*/

//    function lstat(string path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint8 ec, s_stat buf) {
//    }

    // Some defines for calling file status functions.
    uint16 constant FS_EXISTS	    = 1;
    uint16 constant FS_EXECABLE     = 2;
    uint16 constant FS_EXEC_PREF    = 4;
    uint16 constant FS_EXEC_ONLY    = 8;
    uint16 constant FS_DIRECTORY	= 16;
    uint16 constant FS_NODIRS       = 32;

    function read_fs(bytes binodes, bytes[] blocks) internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
//    function read_fs(uint[] nodes, bytes[] blocks) internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        s_stat s;
//        uint[] nodes;
        uint len = binodes.length;
        uint nnodes = len / 32;
        for (uint16 i = 0; i < nnodes; i++) {
            uint start = i * 32;
            uint end = start + 32;
            bytes bb = binodes[start:end];
            bytes32 b32 = bytes32(bb);
            uint att = uint(b32);
            if (att > 0) {
                s.stt(att);
                (uint16 st_dev, , uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, ,
                 uint32 st_size, , uint16 st_blocks, uint32 st_mtim, uint32 st_ctim) = s.unpack();
                inodes[i] = Inode(st_mode, st_uid, st_gid, st_nlink, st_dev, st_blocks, st_size, st_mtim, st_ctim, "");
                data[i] = blocks[i];
            }
        }
    }
    function istat(Inode ino) internal returns (s_stat) {
        uint16 blk_size = sb.DEF_BLOCK_SIZE;
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
        return s_stat(device_id, 0, mode, n_links, owner_id, group_id, device_id, file_size, blk_size, n_blocks, modified_at, last_modified);
    }

    /* Look for a file name in the directory entry. Return file index and file type */
    function fetch_dir_entry(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16, uint8) {
        if (name == "/")
            return (sb.ROOT_DIR, libstat.FT_DIR);
        if (!inodes.exists(dir))
            return (err.ENOENT, libstat.FT_UNKNOWN);
        Inode ino = inodes[dir];
        //if (libstat.mode_to_file_type(ino.mode) != libstat.FT_DIR)
        if (!libstat.is_dir(ino.mode))
            return (err.ENOTDIR, libstat.FT_UNKNOWN);
        return lookup_dir(ino, data[dir], name);
    }

    function resolve_absolute_path(string spath, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16) {
        if (spath == "/")
            return sb.ROOT_DIR;
        string s = "." + spath;
        (string[] parts, uint n_parts) = libstring.split(s, "/");
        uint16 cur_dir = sb.ROOT_DIR;
        for (uint i = 0; i < n_parts; i++) {
            (uint16 index, uint8 t, uint16 dir_idx) = lookup_dir_ext(inodes[cur_dir], data[cur_dir], parts[i]);
            if (dir_idx == 0)
                return err.ENOENT;
            if (t != libstat.FT_DIR)
                return index;
            cur_dir = index;
        }
        return cur_dir;
    }

    function xpath(string param, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        return path.strip_path(xpath0(param, wd, inodes, data));
    }

    function xpath0(string param, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        uint len = param.byteLength();
        if (len > 0 && param.substr(0, 1) == "/")
            return param;
        string cwd = get_absolute_path(wd, inodes, data);
        if (len == 0 || param == ".")
            return cwd;
        if (len > 1 && param.substr(0, 2) == "./")
            return cwd + "/" + param.substr(2);
        if (len > 1 && param.substr(0, 2) == "..") {
            (string dir_name, ) = path.dir(cwd);
            if (param == "..")
                return dir_name;
            if (dir_name == "/")
                dir_name = "";
            return dir_name + "/" + param.substr(3);
        }
        return cwd + "/" + param;
    }

    function get_absolute_path(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        if (dir == sb.ROOT_DIR)
            return "/";
        (uint16 parent, uint8 t) = fetch_dir_entry("..", dir, inodes, data);
        if (t != libstat.FT_DIR)
            return "/";

        return (parent == sb.ROOT_DIR ? "" : get_absolute_path(parent, inodes, data)) + "/" + inodes[dir].file_name;
    }

    function get_file_contents_at_path(string spath, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        (string dir_name, string file_name) = path.dir(spath);
        uint16 dir_index = resolve_absolute_path(dir_name, inodes, data);
        (uint16 file_index, uint8 t) = lookup_dir(inodes[dir_index], data[dir_index], file_name);
        if (t == libstat.FT_UNKNOWN)
            return "Failed to read file " + file_name + " at path " + dir_name + "\n";
        return get_file_contents(file_index, inodes, data);
    }

    function get_file_contents(uint16 file_index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        if (!inodes.exists(file_index))
            return format("Inode {} does not exist\n", file_index);
        if (!data.exists(file_index))
            return format("Data {} does not exist\n", file_index);
        return data[file_index];
    }

    function get_passwd_group(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string, string, uint16, uint16) {
        uint16 etc_dir = resolve_absolute_path("/etc", inodes, data);
        (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        if (passwd_dir_idx > 0 && passwd_file_type == libstat.FT_REG_FILE && group_dir_idx > 0 && group_file_type == libstat.FT_REG_FILE)
            return (get_file_contents(passwd_index, inodes, data), get_file_contents(group_index, inodes, data), passwd_index, group_index);
    }

    /* Looks for a file name in the directory entry. Returns file index */
    function resolve_relative_path(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns
            (uint16 index, uint8 file_type, uint16 parent, uint16 dir_index) {
        if (name == "/")
            return (sb.ROOT_DIR, libstat.FT_DIR, sb.ROOT_DIR, 1);
        parent = name.substr(0, 1) == "/" ? sb.ROOT_DIR : dir;

        (string dir_path, string base_name) = path.dir(name);
        string[] parts = path.disassemble_path(dir_path);
        uint len = parts.length;

        for (uint i = len - 1; i > 0; i--) {
            (uint16 ino, uint8 t, , uint16 dir_idx) = resolve_relative_path(parts[i - 1], parent, inodes, data);
            if (dir_idx == 0)
                return (ino, t, parent, dir_idx);
            else if (t == libstat.FT_DIR)
                parent = ino;
            else
                break;
        }
        (index, file_type, dir_index) = lookup_dir_ext(inodes[parent], data[parent], base_name);
    }

    function lookup_dir(Inode inode, bytes data, string file_name) internal returns (uint16 index, uint8 file_type) {
        (index, file_type, ) = lookup_dir_ext(inode, data, file_name);
    }

    function lookup_dir_ext(Inode ino, bytes data, string file_name) internal returns (uint16 index, uint8 file_type, uint16 dir_idx) {
        if (!libstat.is_dir(ino.mode))
            return (err.ENOTDIR, libstat.FT_UNKNOWN, 0);
        (DirEntry[] contents, int16 status) = udirent.read_dir(ino, data);
        if (status < 0)
            return (uint16(-status), libstat.FT_UNKNOWN, 0);
        else {
            for (uint i = 0; i < uint(status); i++) {
                (uint8 t, string name, uint16 idx) = contents[i].unpack();
                if (name == file_name)
                    return (idx, t, uint16(i + 1));
            }
            return (err.ENOENT, libstat.FT_UNKNOWN, 0);
        }
    }
}
