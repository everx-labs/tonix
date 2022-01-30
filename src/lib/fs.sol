pragma ton-solidity >= 0.56.0;

import "dirent.sol";

library fs {

    uint16 constant ROOT_DIR = 11;

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;
    uint8 constant FT_LAST      = FT_SYMLINK;

    uint16 constant DEF_BLOCK_SIZE = 100;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 60;
    uint16 constant MAX_BLOCKS = 4000;
    uint16 constant MAX_INODES = 600;

    // Some defines for calling file status functions.
    uint16 constant FS_EXISTS	    = 1;
    uint16 constant FS_EXECABLE     = 2;
    uint16 constant FS_EXEC_PREF    = 4;
    uint16 constant FS_EXEC_ONLY    = 8;
    uint16 constant FS_DIRECTORY	= 16;
    uint16 constant FS_NODIRS       = 32;

    /* Look for a file name in the directory entry. Return file index and file type */
    function fetch_dir_entry(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16, uint8) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR);
        if (!inodes.exists(dir))
            return (er.ENOENT, FT_UNKNOWN);
        Inode ino = inodes[dir];
        if (inode.mode_to_file_type(ino.mode) != FT_DIR)
            return (er.ENOTDIR, FT_UNKNOWN);
        return lookup_dir(ino, data[dir], name);
    }

    function resolve_abs_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16) {
        if (s_path == "/")
            return ROOT_DIR;
        (string s_dir, string s_not_dir) = path.dir(s_path);
        (uint16 ino, ) = fetch_dir_entry(s_not_dir, resolve_abs_path(s_dir, inodes, data), inodes, data);
        return ino;
    }

    function resolve_absolute_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16) {
        if (s_path == "/")
            return ROOT_DIR;
        string s = "." + s_path;
        (string[] parts, uint n_parts) = stdio.split(s, "/");
        uint16 cur_dir = ROOT_DIR;
        for (uint i = 0; i < n_parts; i++) {
            (uint16 index, uint8 ft, uint16 dir_idx) = lookup_dir_ext(inodes[cur_dir], data[cur_dir], parts[i]);
            if (dir_idx == 0)
                return er.ENOENT;
            if (ft != FT_DIR)
                return index;
            cur_dir = index;
        }
        return cur_dir;
    }

    function xpath(string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        return path.strip_path(xpath0(s_arg, wd, inodes, data));
    }

    function xpath0(string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        uint len = s_arg.byteLength();
        if (len > 0 && s_arg.substr(0, 1) == "/")
            return s_arg;
        string cwd = get_absolute_path(wd, inodes, data);
        if (len == 0 || s_arg == ".")
            return cwd;
        if (len > 1 && s_arg.substr(0, 2) == "./")
            return cwd + "/" + s_arg.substr(2);
        if (len > 1 && s_arg.substr(0, 2) == "..") {
            (string dir_name, ) = path.dir(cwd);
            if (s_arg == "..")
                return dir_name;
            if (dir_name == "/")
                dir_name = "";
            return dir_name + "/" + s_arg.substr(3);
        }
        return cwd + "/" + s_arg;
    }

    function get_absolute_path(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        if (dir == ROOT_DIR)
            return "/";
        (uint16 parent, uint8 ft) = fetch_dir_entry("..", dir, inodes, data);
        if (ft != FT_DIR)
            return "/";

        return (parent == ROOT_DIR ? "" : get_absolute_path(parent, inodes, data)) + "/" + inodes[dir].file_name;
    }

    function get_file_contents_at_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        (string dir_name, string file_name) = path.dir(s_path);
        uint16 dir_index = resolve_absolute_path(dir_name, inodes, data);
        (uint16 file_index, uint8 ft) = lookup_dir(inodes[dir_index], data[dir_index], file_name);
        if (ft == FT_UNKNOWN)
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

    function get_passwd_group(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string, string) {
        uint16 etc_dir = resolve_absolute_path("/etc", inodes, data);
        (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        if (passwd_dir_idx > 0 && passwd_file_type == FT_REG_FILE && group_dir_idx > 0 && group_file_type == FT_REG_FILE)
            return (get_file_contents(passwd_index, inodes, data), get_file_contents(group_index, inodes, data));
    }

    /* Looks for a file name in the directory entry. Returns file index */
    function resolve_relative_path(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns
            (uint16 index, uint8 file_type, uint16 parent, uint16 dir_index) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR, ROOT_DIR, 1);
        parent = name.substr(0, 1) == "/" ? ROOT_DIR : dir;

        (string dir_path, string base_name) = path.dir(name);
        string[] parts = path.disassemble_path(dir_path);
        uint len = parts.length;

        for (uint i = len - 1; i > 0; i--) {
            (uint16 ino, uint8 ft, , uint16 dir_idx) = resolve_relative_path(parts[i - 1], parent, inodes, data);
            if (dir_idx == 0)
                return (ino, ft, parent, dir_idx);
            else if (ft == FT_DIR)
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
        if (inode.mode_to_file_type(ino.mode) != FT_DIR)
            return (er.ENOTDIR, FT_UNKNOWN, 0);
        (DirEntry[] contents, int16 status) = dirent.read_dir(ino, data);
        if (status < 0)
            return (uint16(-status), FT_UNKNOWN, 0);
        else {
            for (uint i = 0; i < uint(status); i++) {
                (uint8 ft, string name, uint16 idx) = contents[i].unpack();
                if (name == file_name)
                    return (idx, ft, uint16(i + 1));
            }
            return (er.ENOENT, FT_UNKNOWN, 0);
        }
    }
}
