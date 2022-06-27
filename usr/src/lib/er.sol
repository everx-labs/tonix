pragma ton-solidity >= 0.61.2;

import "libstring.sol";
import "xio.sol";
import "sbuf.sol";

struct Err {
    uint8 reason;
    uint16 explanation;
    string arg;
}

library er {

    using libstring for string;
    using sbuf for s_sbuf;

    uint8 constant ESUCCESS  = 0;
    uint8 constant ENOENT    = 1;  // No such file or directory: a component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags
    uint8 constant EEXIST    = 2;  // File exists
    uint8 constant ENOTDIR   = 3;  // Not a directory: A component of the path prefix of pathname is not a directory
    uint8 constant EISDIR    = 4;  // Is a directory
    uint8 constant EACCES    = 5;  // Permission denied: search permission is denied for one of the directories in the path prefix of pathname
    uint8 constant ENOTEMPTY = 6;  // Directory not empty
    uint8 constant EPERM     = 7;  // Not owner
    uint8 constant EINVAL    = 8;  // Invalid argument
    uint8 constant EROFS     = 9;  // Read-only file system
    uint8 constant EFAULT    = 10; // Bad address
    uint8 constant EBADF     = 11; // Bad file number: fd is not a valid open file descriptor
    uint8 constant EBUSY     = 12; // Device busy
    uint8 constant ENOSYS    = 13; // Operation not applicable
    uint8 constant ENAMETOOLONG = 14; // Pathname is too long

    uint8 constant invalid_option       = 7;
    uint8 constant extra_operand        = 8;
    uint8 constant missing_file_operand = 11;
    uint8 constant invalid_mode         = 15;
    uint8 constant invalid_owner        = 16;
    uint8 constant try_help_for_info    = 21;
    uint8 constant omitting_directory   = 23;
    uint8 constant cant_overwrite_dir   = 24;
    uint8 constant command_not_found    = 25;
    uint8 constant options_l_s_incompat = 26;
    uint8 constant ln_target            = 27;
    uint8 constant failed_symlink       = 28;
    uint8 constant failed_hardlink      = 29;
    uint8 constant hard_or_symlink      = 30;
    uint8 constant no_hardlink_on_dir   = 31;
    uint8 constant mutually_exclusive_options = 32;
    uint8 constant login_data_not_found = 33;
    uint8 constant not_a_block_device   = 34;

    uint8 constant E_SUCCESS       = 0; // success
    uint8 constant E_USAGE         = 2; // invalid command syntax
    uint8 constant E_BAD_ARG       = 3; // invalid argument to option
    uint8 constant E_GID_IN_USE    = 4; // specified group doesn't exist <- copy/paste error
    uint8 constant E_NOTFOUND      = 6; // specified group doesn't exist
    uint8 constant E_NAME_IN_USE   = 9; // group name already in use
    uint8 constant E_GRP_UPDATE    = 10; // can't update group file
    uint8 constant E_CLEANUP_SERVICE = 11; // can't setup cleanup service
    uint8 constant E_PAM_USERNAME  = 12; // can't determine your username for use with pam
    uint8 constant E_PAM_ERROR     = 13; // pam returned an error, see syslog facility id groupmod for the PAM error message

    function strerror(uint8 ec) internal returns (string) {
        if (ec == ESUCCESS) return "";
        if (ec == ENOENT) return "No such file or directory";
        if (ec == EEXIST) return "File exists";
        if (ec == ENOTDIR) return "Not a directory";
        if (ec == EISDIR) return "Is a directory";
        if (ec == EACCES) return "Permission denied";
        if (ec == ENOTEMPTY) return "Directory not empty";
        if (ec == EPERM) return "Not owner";
        if (ec == EINVAL) return "Invalid argument";
        if (ec == EROFS) return "Read-only file system";
        if (ec == EFAULT) return "Bad address";
        if (ec == EBADF) return "Bad file number: fd is not a valid open file descriptor";
        if (ec == EBUSY) return "Device busy";
        if (ec == ENOSYS) return "Operation not applicable";
        if (ec == ENAMETOOLONG) return "Pathname is too long";
        return "unknown error";
    }

    function export() internal returns (s_of) {
        string status = "Success\nNo such file or directory\nFile exists\nNot a directory\nIs a directory\nPermission denied\nDirectory not empty\nNot owner\nInvalid argument\nRead-only file system\nBad address\nBad file number: fd is not a valid open file descriptor\nDevice busy\nOperation not applicable\npathname is too long\n";
        s_sbuf s;
        s.sbuf_new_auto();
        s.sbuf_cpy(status);
        s.sbuf_finish();
        return s_of(0, 0, 4, "syserr", 0, s);
    }

    /* Print error helpers */
    function print_errors(string command, Err[] errors) internal returns (string err) {
        string command_specific_reason = command_specific_reason(command);
        string reasons = "missing operand:cannot remove:cannot stat:cannot access:cannot create directory:cannot open:invalid option:extra operand:failed to remove:missing operand after:missing file operand:missing destination file operand after:invalid group:missing filename:invalid mode:invalid owner:cannot touch:cannot create regular file:too many arguments:too many operands:Try '--help' for more information:failed to access:-r not specified; omitting directory:cannot overwrite directory with non-directory:command not found:options -l and -s are incompatible:target:failed to create symbolic link:failed to create hard link:cannot make both hard and symbolic links:hard link not allowed for directory:mutually exclusive arguments -c -n -r -z:failed to locate login data:not a block device";
        string status = "No such file or directory:File exists:Not a directory:Is a directory:Permission denied:Directory not empty:Not owner:Invalid argument:Read-only file system:Bad address:Bad file number:fd is not a valid open file descriptor:Device busy:Operation not applicable:pathname is too long";
        (string[] rs, uint n_rs) = reasons.split(":");
        (string[] ss, uint n_ss) = status.split(":");
        for (Err e: errors) {
            (uint8 reason, uint16 explanation, string param) = e.unpack();
            string sreason;
            string sexplanation;
            if (reason > n_rs)
                err.append("Provided reason index is out of range: " + str.toa(reason) + "\n");
            else
                sreason = reason > 0 ? rs[reason - 1] : command_specific_reason;
            if (explanation > n_ss)
                err.append("Provided status index is out of range: " + str.toa(explanation) + "\n");
            else
                sexplanation = explanation > 0 ? ss[explanation - 1] : "no explanation provided";
            err.append(command + ": " + sreason + " " + str.squote(param));
            if (explanation > 0)
                err.append(sexplanation.empty() ? format("\n Failed expl. lookup r {} e {}\n", reason, explanation) : ": " + sexplanation);
            err.append("\n");
        }
    }

    function command_specific_reason(string c) internal returns (string) {
        if (c == "file" || c == "rev") return "cannot open";
        if (c == "head" || c == "tail") return "cannot open for reading";
        if (c == "ln") return "failed to access";
        if (c == "stat" || c == "cp" || c == "mv") return "cannot stat";
        if (c == "du" || c == "ls" || c == "chgrp" || c == "chmod" || c == "chown") return "cannot access";
        if (c == "rm") return "cannot remove";
        if (c == "rmdir") return "failed to remove";
        if (c == "mkdir") return "cannot create directory";
        if (op_format(c)) return "";
    }

    function op_format(string c) internal returns (bool) {
        return c == "cat" || c == "colrm" || c == "column" || c == "cut" || c == "expand" || c == "grep" || c == "head" || c == "look"
            || c == "mapfile" || c == "more" || c == "paste" || c == "rev" || c == "tail" || c == "tr" || c == "unexpand" || c == "wc";
    }

}
