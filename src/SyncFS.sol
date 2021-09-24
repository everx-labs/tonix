pragma ton-solidity >= 0.49.0;

import "Internal.sol";
import "Commands.sol";

/* Common functions and definitions for file system handling and synchronization */
abstract contract SyncFS is Internal, Commands {

    FileSystem _fs;
    mapping (uint16 => ProcessInfo) public _proc;
    mapping (uint16 => UserInfo) public _users;
    mapping (uint16 => GroupInfo) public _groups;

    function _get_login_info() internal view returns (bool /*found*/, mapping (uint16 => UserInfo) login_info) {
        string[] etc_passwd_contents = _get_file_contents("/etc/passwd");

        for (string s: etc_passwd_contents) {
            string[] fields = _get_tsv(s);
            string user_name = fields[0];
            (uint res, bool success) = stoi(fields[1]);
            uint16 uid = success ? uint16(res) : GUEST_USER;
            (res, success) = stoi(fields[2]);
            uint16 gid = success ? uint16(res) : GUEST_USER_GROUP;
            string primary_group = fields.length > 2 ? fields[3] : "guest";
            login_info[uid] = UserInfo(gid, user_name, primary_group);
        }
    }

    function _get_absolute_path(uint16 dir) internal view returns (string) {
        if (dir == ROOT_DIR)
            return ROOT;
        (uint16 parent, uint8 ft) = _fetch_dir_entry("..", dir);
        if (ft != FT_DIR)
            return "Failed to get absolute path: not a directory";

        return (parent == ROOT_DIR ? "" : _get_absolute_path(parent)) + "/" + _fs.inodes[dir].file_name;
    }

    function _resolve_absolute_path(string path) internal view returns (uint16) {
        if (path == ROOT)
            return ROOT_DIR;
        (string dir, string not_dir) = _dir(path);
        return _fetch_file_index(not_dir, _resolve_absolute_path(dir));
    }
    /*function _resolve_absolute_path(string dir_name) internal view returns (uint16) {
        (string dir, string not_dir) = _dir(dir_name);

        if (dir == ROOT) {
            (uint16 ino, ) = _fetch_dir_entry(not_dir, ROOT_DIR);
            return ino;
        }
        (uint16 ino, ) = _fetch_dir_entry(not_dir, _resolve_absolute_path(dir));
        return ino;
    }*/

    function _xpath(string s_arg, uint16 wd) internal view returns (string res) {
        return _strip_path(_xpath0(s_arg, wd));
    }

    function _xpath0(string s_arg, uint16 wd) internal view returns (string res) {
        uint len = s_arg.byteLength();
        if (len > 0 && s_arg.substr(0, 1) == "/")
            return s_arg;
        string cwd = _get_absolute_path(wd);
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
        /*(string dir, string not_dir) = _dir(path);
        (uint16 index, uint8 ft) = _fetch_dir_entry(not_dir, _resolve_absolute_path(dir));
        if (ft > FT_UNKNOWN)
            return _fs.inodes[index].text_data;*/
        uint16 index = _get_file_index(path);
        if (index > INODES && _fs.inodes.exists(index))
            return _fs.inodes[index].text_data;
    }

    function _get_file_index(string path) internal view returns (uint16) {
        if (path.empty())
            return ENOENT;
        if (path == ROOT)
            return ROOT_DIR;
        (string dir, string not_dir) = _dir(path);
        return _fetch_file_index(not_dir, _resolve_absolute_path(dir));
//        (uint16 index, uint8 ft) = _fetch_dir_entry(not_dir, _resolve_absolute_path(dir));
//        return ft > FT_UNKNOWN ? index : ENOENT;
    }

    function _dir_index(string name, uint16 dir) internal view returns (uint16) {
        string[] dir_text = _fs.inodes[dir].text_data;
        uint len = name.byteLength();
        for (uint16 i = 0; i < dir_text.length; i++) {
            string line = dir_text[i];
            if (line.byteLength() > len && line.substr(1, len) == name)
                return i + 1;
        }
    }

    /* Looks for a file name in the directory entry. Return file index and file type */
    function _fetch_dir_entry(string name, uint16 dir) internal view returns (uint16 ino, uint8 ft) {
        if (!_fs.inodes.exists(dir))
            return (ENOTDIR, FT_UNKNOWN);
        Inode inode = _fs.inodes[dir];
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return (ENOTDIR, FT_UNKNOWN);
        uint16 dir_index = _dir_index(name, dir);
        if (dir_index == 0)
            return (ENOENT, FT_UNKNOWN);
        (, ino, ft) = _read_dir_entry(inode.text_data[dir_index - 1]);
    }

    /* Looks for a file name in the directory entry. Returns file index */
    function _fetch_file_index(string name, uint16 dir) internal view returns (uint16 ino) {
        if (!_fs.inodes.exists(dir))
            return ENOTDIR;
        Inode inode = _fs.inodes[dir];
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return ENOTDIR;
        uint16 dir_index = _dir_index(name, dir);
        if (dir_index == 0)
            return ENOENT;
        (, ino, ) = _read_dir_entry(inode.text_data[dir_index - 1]);
    }

    function _resolve_relative_path(string name, uint16 dir) internal view returns
            (uint16 inode, uint8 file_type, uint16 parent, uint16 dir_index) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR, ROOT_DIR, 1);
        string path_start = name.substr(0, 1);
        uint16 cur_dir = path_start == "/" ? ROOT_DIR : dir;

        (string dir_path, string base_name) = _dir(name);
        string[] parts = _disassemble_path(dir_path);
        uint len = parts.length;

        for (uint i = len - 1; i > 0; i--) {
            (uint16 ino, uint8 ft, , uint16 dir_idx) = _resolve_relative_path(parts[i - 1], cur_dir);
            if (dir_idx == 0)
                return (ino, ft, cur_dir, dir_idx);
            if (ft == FT_DIR)
                cur_dir = ino;
            else
                break;
        }
        parent = cur_dir;
        dir_index = _dir_index(base_name, parent);
        if (dir_index > 0)
            (, inode, file_type) = _read_dir_entry(_fs.inodes[parent].text_data[dir_index - 1]);
    }

     function _file_type_sign_and_description(uint16 index) internal view returns (string, string) {
        string[] text = _get_file_contents("/etc/fs_types");
        if (index < text.length) {
            string entry = text[index];
            return (entry.substr(0, 1), entry.substr(1, entry.byteLength() - 1));
        }
    }

}
