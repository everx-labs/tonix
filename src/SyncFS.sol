pragma ton-solidity >= 0.49.0;

import "Commands.sol";
import "Map.sol";
import "Device.sol";
import "Path.sol";

struct ArgS {
    string path;
    uint8 ft;
    uint16 idx;
    uint16 parent;
    uint16 dir_index;
}

struct ErrS {
    uint8 reason;
    uint16 explanation;
    string arg;
}

struct InputS {
    uint8 command;
    string[] args;
    uint flags;
}

struct IOEventS {
    uint8 iotype;
    uint16 parent;
    ArgS[] args;
}

struct SessionS {
    uint16 pid;
    uint16 uid;
    uint16 gid;
    uint16 wd;
}

/* Common functions and definitions for file system handling and synchronization */
abstract contract SyncFS is Device, Commands, Map, Path {

    uint8 constant IO_WR_COPY       = 1;
    uint8 constant IO_ALLOCATE      = 2;
    uint8 constant IO_TRUNCATE      = 3;
    uint8 constant IO_MKFILE        = 4;
    uint8 constant IO_MKDIR         = 5;
    uint8 constant IO_HARDLINK      = 6;
    uint8 constant IO_SYMLINK       = 7;
    uint8 constant IO_UNLINK        = 8;
    uint8 constant IO_CHATTR        = 9;
    uint8 constant IO_ACCESS        = 10;
    uint8 constant IO_PERMISSION    = 11;
    uint8 constant IO_UPDATE_TIME   = 12;

    uint8 constant ENOENT   = 1; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST   = 2; // "File exists"
    uint8 constant ENOTDIR  = 3; //  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR   = 4; //"Is a directory"
    uint8 constant EACCES   = 5; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)
    uint8 constant ENOTEMPTY = 6; // "Directory not empty"
    uint8 constant EPERM    = 7; // "Not owner"
    uint8 constant EINVAL   = 8; //"Invalid argument"
    uint8 constant EROFS    = 9; //"Read-only file system"
    uint8 constant EFAULT   = 10; //Bad address.
    uint8 constant EBADF    = 11; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY    = 12; // "Device busy"
    uint8 constant ENOSYS   = 13; // "Operation not applicable"
    uint8 constant ENAMETOOLONG = 14; // pathname is too long.

    uint8 constant ERR_MSG              = 0;
    uint8 constant invalid_mode         = 15;
    uint8 constant invalid_owner        = 16;
    uint8 constant omitting_directory   = 23;
    uint8 constant cant_overwrite_dir   = 24;
    uint8 constant options_l_s_incompat = 26;
    uint8 constant ln_target            = 27;
    uint8 constant failed_symlink       = 28;
    uint8 constant failed_hardlink      = 29;
    uint8 constant hard_or_symlink      = 30;
    uint8 constant no_hardlink_on_dir   = 31;
    uint8 constant mutually_exclusive_options = 32;
    uint8 constant login_data_not_found = 33;

    function _get_login_info() internal view returns (mapping (uint16 => UserInfo) login_info) {
        string[] etc_passwd_contents = _get_file_contents("/etc/passwd");
        for (string s: etc_passwd_contents) {
            string[] fields = _read_entry(s);
            string user_name = fields[0];
            (uint res, bool success) = stoi(fields[1]);
            uint16 uid = success ? uint16(res) : GUEST_USER;
            (res, success) = stoi(fields[2]);
            uint16 gid = success ? uint16(res) : GUEST_USER_GROUP;
            string primary_group = fields.length > 2 ? fields[3] : "guest";
            string home_directory = fields[4];
            login_info[uid] = UserInfo(uid, gid, user_name, primary_group, home_directory);
        }
    }

    function _get_abs_path(uint16 dir) internal view returns (string) {
        if (dir == ROOT_DIR)
            return ROOT;
        (uint16 parent, uint8 ft) = _fetch_dir_entry("..", dir);

        if (ft != FT_DIR || parent < INODES)
            return "Failed to get absolute path";
        string dir_name;
        for (string s: _fs.inodes[parent].text_data) {
            (string file_name, uint16 file_inode, ) = _read_dir_entry(s);
            if (dir == file_inode)
                dir_name = file_name;
        }

        return (parent == ROOT_DIR ? "" : _get_abs_path(parent)) + "/" + dir_name;
    }

    function _resolve_abs_path(string dir_name) internal view returns (uint16) {
        (string dir, string not_dir) = _dir(dir_name);

        if (dir == ROOT) {
            (uint16 ino, ) = _lookup_dir_entry(not_dir, ROOT_DIR);
            return ino;
        }
        (uint16 ino, ) = _lookup_dir_entry(not_dir, _resolve_abs_path(dir));
        return ino;
    }

    function _xpath(string s_arg, uint16 wd) internal view returns (string res) {
        return _strip_path(_xpath0(s_arg, wd));
    }

    function _xpath0(string s_arg, uint16 wd) internal view returns (string res) {
        uint len = s_arg.byteLength();
        if (len > 0 && s_arg.substr(0, 1) == "/")
            return s_arg;
        string cwd = _get_abs_path(wd);
        if (len == 0 || s_arg == ".")
            return cwd;
        if (len > 1 && s_arg.substr(0, 2) == "./")
            return cwd + "/" + s_arg.substr(2, len - 2);
        if (len > 1 && s_arg.substr(0, 2) == "..") {
            (string dir_name, ) = _dir(cwd);
            if (s_arg == "..")
                return dir_name;
            if (dir_name == "/")
                dir_name = "";
            return dir_name + "/" + s_arg.substr(3, len - 3);
        }
        return cwd + "/" + s_arg;
    }

    function _get_file_contents(string path) internal view returns (string[]) {
        (string dir, string not_dir) = _dir(path);
        (uint16 inode, uint8 ft) = _lookup_dir_entry(not_dir, _resolve_abs_path(dir));
        if (inode >= INODES && ft == FT_REG_FILE)
            return _fs.inodes[inode].text_data;
    }

    function _lookup_dir_entry(string name, uint16 dir) internal view returns (uint16 inode, uint8 file_type) {
        (inode, file_type, , ) = _lookup_dir_entry_plus(name, dir);
    }

    function _dir_index(string name, uint16 dir) internal view returns (uint16) {
        return _match_line(name, _fs.inodes[dir].text_data);
    }

    /* Looks for a file name in the directory entry */
    function _fetch_dir_entry(string name, uint16 dir) internal view returns (uint16, uint8) {
        string[] text = _fs.inodes[dir].text_data;
        uint16 idx = _match_line(name, text);
        if (idx > 0) {
            (, uint16 inode, uint8 ft) = _read_dir_entry(text[idx - 1]);
            return (inode, ft);
        }
        return (ENOENT, FT_UNKNOWN);
    }

    function _lookup_dir_entry_plus(string name, uint16 dir) internal view returns
            (uint16 inode, uint8 file_type, uint16 parent, uint16 dir_index) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR, ROOT_DIR, 1);
        string path_start = name.substr(0, 1);
        uint16 dir_start = path_start == "/" ? ROOT_DIR : dir;

        (string dir_path, string base_name) = _dir(name);
        string[] parts = _disassemble_path(dir_path);
        uint len = parts.length;
        uint16 cur_dir = dir_start;

        for (uint i = len - 1; i > 0; i--) {
            (uint16 ino, uint8 ft, , uint16 idx) = _lookup_dir_entry_plus(parts[i - 1], cur_dir);
            if (ino < INODES)
                return (ino, ft, cur_dir, idx);
            if (ft == FT_DIR)
                cur_dir = ino;
            else
                break;
        }
        dir = cur_dir;

        parent = dir;
        dir_index = _dir_index(base_name, parent);
        if (dir_index > 0)
            (, inode, file_type) = _read_dir_entry(_fs.inodes[parent].text_data[dir_index - 1]);
//        (inode, file_type, parent, dir_index) = _fetch_dir_entry(base_name, dir);
    }

     function _file_type_sign_and_description(uint16 index) internal view returns (string, string) {
        string[] text = _get_file_contents("/etc/fs_types");
        if (index < text.length) {
            string entry = text[index];
            return (entry.substr(0, 1), entry.substr(1, entry.byteLength() - 1));
        }
    }

}
