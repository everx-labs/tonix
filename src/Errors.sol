pragma ton-solidity >= 0.48.0;

import "ISource.sol";
import "Commands.sol";
import "String.sol";
struct ErrS {
    uint8 code;
    uint8 reason;
    uint16 explanation;
    string arg;
}

abstract contract Errors is String, Commands {

    uint8 constant ENOENT   = 0; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST   = 1; // "File exists"
    uint8 constant ENOTDIR  = 2;//  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR   = 3; //"Is a directory"
    uint8 constant EACCES   = 4; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)

    uint8 constant EBADF    = 5; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY    = 6; // "Device busy"
    uint8 constant EPERM    = 7; // "Not owner"
    uint8 constant EINVAL   = 8; //"Invalid argument"
    uint8 constant EROFS    = 9; //"Read-only file system"
    uint8 constant ENOSYS   = 10; // "Operation not applicable"
    uint8 constant ENOTEMPTY = 11; // "Directory not empty"
    uint8 constant EFAULT   = 12; //Bad address.
    uint8 constant ENAMETOOLONG = 13; // pathname is too long.


    uint8 constant ERR_FIRST            = 0;
    uint8 constant ERR_MSG              = 1 + ERR_FIRST;
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

    uint8 constant ERR_MSG_LAST         = failed_to_access;

    uint8 constant ERR_DIRENT           = 1 + ERR_MSG_LAST;
    uint8 constant no_such_file_or_dir  = 0 + ERR_DIRENT;
    uint8 constant file_exists          = 1 + ERR_DIRENT;
    uint8 constant not_a_directory      = 2 + ERR_DIRENT;
    uint8 constant is_a_directory       = 3 + ERR_DIRENT;
    uint8 constant permission_denied    = 4 + ERR_DIRENT;
    uint8 constant ERR_DIRENT_LAST      = permission_denied;

    uint8 constant ERR_INT              = 1 + ERR_DIRENT_LAST;
    uint8 constant direntry_not_found   = 0 + ERR_INT;
    uint8 constant inode_not_found      = 1 + ERR_INT;
    uint8 constant parent_direntry_nf   = 2 + ERR_INT;
    uint8 constant child_direntry_nf    = 3 + ERR_INT;
    uint8 constant invalid_user_id      = 4 + ERR_INT;
    uint8 constant invalid_working_dir  = 5 + ERR_INT;
    uint8 constant ERR_INT_LAST         = invalid_working_dir;
    uint8 constant ERR_LAST             = ERR_INT_LAST;

    string[] public _error_text;
    address _cmd_source;

    function update_errors(string[] er) external accept {
        _error_text = er;
    }

    function _init_errors() internal {
        _cmd_source = address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb);
        ISource(_cmd_source).query_errors{value: 0.2 ton}();
    }

    function _command_reason(uint8 c) internal pure returns (uint8) {
        if (c == file) return cannot_open;
        if (c == ln) return failed_to_access;
        if (c == stat || c == cp || c == mv) return cannot_stat;
        if (c == cat || c == cksum || c == df || c == cmp || c == cd) return 200;   // command name
        if (c == du || c == ls || _op_access(c)) return cannot_access;
        if (c == rm) return cannot_remove;
        if (c == rmdir) return failed_to_remove;
    }

    function _error_message2(uint8 command, ErrS e) internal view returns (string s) {
        (, uint8 reason, uint16 explanation, string arg) = e.unpack();
        s = _command_names[command] + ": " + ((reason == 200) ? _command_names[command] : _error_text[reason]) + _quote(arg);
        if (explanation < _error_text.length)
            s.append(_error_text[uint8(explanation)]);
        s.append("\n");
    }

    function _internal_error_message(uint8 command, ErrS e) internal view returns (string) {
        (, uint8 reason, uint16 explanation, string arg) = e.unpack();
        return _command_names[command] + " " + _error_text[reason] + " " + format("val {} ", explanation) + arg + "\n";
    }

}
