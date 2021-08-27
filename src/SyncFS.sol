pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "Commands.sol";
import "Map.sol";
import "Device.sol";
import "IData.sol";

struct ErrS {
    uint8 reason;
    uint16 explanation;
    string arg;
}

abstract contract SyncFS is Device, Commands, Map {

    uint8 constant IO_WR_NEW        = 1;
    uint8 constant IO_WR_APPEND     = 2;
    uint8 constant IO_WR_OVERWRITE  = 3;
    uint8 constant IO_WR_COPY       = 4;
    uint8 constant IO_TRUNCATE      = 10;
    uint8 constant IO_ALLOCATE      = 11;
    uint8 constant IO_ERASE         = 12;
    uint8 constant IO_MKFILE        = 13;
    uint8 constant IO_MKDIR         = 14;
    uint8 constant IO_HARDLINK      = 15;
    uint8 constant IO_SYMLINK       = 16;
    uint8 constant IO_UNLINK        = 17;
    uint8 constant IO_CHATTR        = 18;
    uint8 constant IO_ACCESS        = 19;
    uint8 constant IO_PERMISSION    = 20;
    uint8 constant IO_UPDATE_TIME   = 21;

    uint8 constant READ_ANY     = 1;
    uint8 constant READ_INDEX   = 2;
    uint8 constant READ_ALL     = 3;
    uint8 constant READ_MERGE   = 4;
    uint8 constant READ_TEXT    = 5;
    uint8 constant READ_INODE   = 6;

    uint8 constant ENOENT   = 1; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST   = 2; // "File exists"
    uint8 constant ENOTDIR  = 3; //  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR   = 4; //"Is a directory"
    uint8 constant EACCES   = 5; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)

    uint8 constant EBADF    = 5; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY    = 6; // "Device busy"
    uint8 constant EPERM    = 7; // "Not owner"
    uint8 constant EINVAL   = 8; //"Invalid argument"
    uint8 constant EROFS    = 9; //"Read-only file system"
    uint8 constant ENOSYS   = 10; // "Operation not applicable"
    uint8 constant ENOTEMPTY = 11; // "Directory not empty"
    uint8 constant EFAULT   = 12; //Bad address.
    uint8 constant ENAMETOOLONG = 13; // pathname is too long.

    uint8 constant ERR_MSG              = 0;
    uint8 constant missing_opnd         = 0 + ERR_MSG;
    uint8 constant cannot_remove        = 1 + ERR_MSG;
    uint8 constant cannot_stat          = 2 + ERR_MSG;
    uint8 constant cannot_access        = 3 + ERR_MSG;
    uint8 constant cannot_create_dir    = 4 + ERR_MSG;
    uint8 constant cannot_open          = 5 + ERR_MSG;
    uint8 constant invalid_option       = 6 + ERR_MSG;
    uint8 constant extra_opnd           = 7 + ERR_MSG;
    uint8 constant failed_to_remove     = 8 + ERR_MSG;
    uint8 constant missing_opnd_after   = 9 + ERR_MSG;
    uint8 constant missing_file_opnd    = 10 + ERR_MSG;
    uint8 constant miss_dst_opnd_after  = 11 + ERR_MSG;
    uint8 constant invalid_group        = 12 + ERR_MSG;
    uint8 constant missing_filename     = 13 + ERR_MSG;
    uint8 constant invalid_mode         = 14 + ERR_MSG;
    uint8 constant invalid_owner        = 15 + ERR_MSG;
    uint8 constant cant_touch           = 16 + ERR_MSG;
    uint8 constant cant_create_reg_file = 17 + ERR_MSG;
    uint8 constant too_many_arguments   = 18 + ERR_MSG;
    uint8 constant too_many_operands    = 19 + ERR_MSG;
    uint8 constant try_help_for_info    = 20 + ERR_MSG;
    uint8 constant omitting_directory   = 21 + ERR_MSG;
    uint8 constant cant_overwrite_dir   = 22 + ERR_MSG;
    uint8 constant options_incompatible = 23 + ERR_MSG;
    uint8 constant failed_to_access     = 24 + ERR_MSG;

    function _command_reason(uint8 c) internal view returns (string) {
        if (c == file) return "cannot open";
        if (c == ln) return "failed to access";
        if (c == stat || c == cp || c == mv) return "cannot stat";
        if (c == cat || c == cksum || c == df || c == cmp || c == cd) return _get_command_name(c);   // command name
        if (c == du || c == ls || _op_access(c)) return "cannot access";
        if (c == rm) return "cannot remove";
        if (c == rmdir) return "failed to remove";
    }

    function _error_message(uint8 command, ErrS e) internal view returns (string s) {
        (uint8 reason, uint16 explanation, string arg) = e.unpack();
        string command_name = _get_command_name(command);
        string s_reason = reason > 0 ? _get_error_message_reason(reason) : _command_reason(command);
        string s_explanation = _get_error_message_explanation(explanation);
        s = command_name + ": " + s_reason + _quote(arg);
        if (explanation > 0) {
            if (!s_explanation.empty())
                s.append(": " + s_explanation);
            else
                s.append(format("\n Failed expl. lookup r {} e {}\n", reason, explanation));
        }
        s.append("\n");
    }

    function _get_user_name(uint16 uid) internal view returns (string) {
        return _match_value_at_index(2, format("{}", uid), 1, _get_file_contents("/etc/passwd"));
    }

    function _get_group_name(uint16 gid) internal view returns (string) {
        return _match_value_at_index(3, format("{}", gid), 4, _get_file_contents("/etc/passwd"));
    }

    function _lookup_group_id(string group_name) internal view returns (uint16 gid) {
        gid = GUEST_USER_GROUP;
        string group_id_s = _match_value_at_index(4, group_name, 3, _get_file_contents("/etc/passwd"));
        uint res;
        bool success;
        (res, success) = stoi(group_id_s);
        if (success)
            gid = uint16(res);
    }

    function _lookup_user_id(string user_name) internal view returns (uint16 uid) {
        uid = GUEST_USER;
        string user_id_s = _match_value_at_index(1, user_name, 2, _get_file_contents("/etc/passwd"));
        uint res;
        bool success;
        (res, success) = stoi(user_id_s);
        if (success)
            uid = uint16(res);
    }

    function _get_command_name(uint8 index) internal view returns (string) {
        return _element_at(1, index, _get_file_contents("/etc/commands"), "\t");
    }

    function _command_by_name(string s) internal view returns (uint8) {
        uint8 idx = uint8(_lookup_field(s, _get_file_contents("/etc/commands")));
        return idx > 0 ? idx : CMD_UNKNOWN;
    }

    function _get_error_message_reason(uint16 index) internal view returns (string) {
        return _element_at(1, index, _get_file_contents("/usr/share/errors/reasons"), "\t");
    }

    function _get_error_message_explanation(uint16 index) internal view returns (string) {
        return _element_at(1, index, _get_file_contents("/usr/share/errors/status"), "\t");
    }

    function _get_abs_path(uint16 dir) internal view returns (string) {
        if (dir == ROOT_DIR)
            return "/";
        uint16 parent = _inode_in_dir("..", dir);
        string dir_name;
        for (string s: _get_lines(_fs.inodes[parent].text_data)) {
            (string file_name, uint16 file_inode, ) = _read_de(s);
            if (dir == file_inode)
                dir_name = file_name;
        }

        return (parent == ROOT_DIR ? "" : _get_abs_path(parent)) + "/" + dir_name;
    }

    function _resolve_abs_path(string dir_name) internal view returns (uint16) {
        if (dir_name == "/")
            return ROOT_DIR;
        string dir = _dir(dir_name);
        string not_dir = _not_dir(dir_name);
        if (dir == "/")
            return _inode_in_dir(not_dir, ROOT_DIR);
        uint16 dir_id = _resolve_abs_path(dir);
        return _inode_in_dir(not_dir, dir_id);
    }

    function _inode_in_dir(string path, uint16 dir) internal view returns (uint16 inode) {
        (inode, ) = _inode_and_type(path, dir);
    }

    function _inode_at_path(string path) internal view returns (uint16 inode) {
        return _inode_in_dir(_not_dir(path), _resolve_abs_path(_dir(path)));
    }

    function _get_file_contents(string path) internal view returns (string) {
        uint16 inode = _inode_at_path(path);
        if (inode >= INODES)
            return _fs.inodes[inode].text_data;
    }

    function _inode_and_type(string path, uint16 dir) internal view returns (uint16 inode, uint8 file_type) {
        if (path == "/")
            return (ROOT_DIR, FT_DIR);
        if (path == "~")
            return (_inode_in_dir("home", ROOT_DIR), FT_DIR);

        string name = path;
        uint16 p = _strchr(path, "/");
        if (p > 0) {
            uint16 q = _strrchr(path, "/");
            if (p == 1) {
                dir = q == 1 ? ROOT_DIR : _resolve_abs_path(_dir(path));
                name = _not_dir(path);
            } else {
                name = path.substr(0, p - 1);
                dir = _inode_in_dir(name, dir);
            }
        }

        for (string s: _get_lines(_fs.inodes[dir].text_data)) {
            (string file_name, uint16 inode_sub, uint8 ft) = _read_de(s);
            if (file_name == name) {
                inode = inode_sub;
                file_type = ft;
            }
        }
    }

}
