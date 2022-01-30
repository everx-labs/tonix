pragma ton-solidity >= 0.56.0;

import "stdio.sol";
struct Err {
    uint8 reason;
    uint16 explanation;
    string arg;
}

library er {
    uint8 constant ENOENT       = 1; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST       = 2; // "File exists"
    uint8 constant ENOTDIR      = 3; //  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR       = 4; //"Is a directory"
    uint8 constant EACCES       = 5; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)
    uint8 constant ENOTEMPTY    = 6; // "Directory not empty"
    uint8 constant EPERM        = 7; // "Not owner"
    uint8 constant EINVAL       = 8; //"Invalid argument"
    uint8 constant EROFS        = 9; //"Read-only file system"
    uint8 constant EFAULT       = 10; //Bad address.
    uint8 constant EBADF        = 11; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY        = 12; // "Device busy"
    uint8 constant ENOSYS       = 13; // "Operation not applicable"
    uint8 constant ENAMETOOLONG = 14; // pathname is too long.

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

    /* Print error helpers */
    function print_errors(string command, Err[] errors) internal returns (string err) {
        string command_specific_reason = command_specific_reason(command);
        string reasons = "missing operand:cannot remove:cannot stat:cannot access:cannot create directory:cannot open:invalid option:extra operand:failed to remove:missing operand after:missing file operand:missing destination file operand after:invalid group:missing filename:invalid mode:invalid owner:cannot touch:cannot create regular file:too many arguments:too many operands:Try '--help' for more information:failed to access:-r not specified; omitting directory:cannot overwrite directory with non-directory:command not found:options -l and -s are incompatible:target:failed to create symbolic link:failed to create hard link:cannot make both hard and symbolic links:hard link not allowed for directory:mutually exclusive arguments -c -n -r -z:failed to locate login data:not a block device";
        string status = "No such file or directory:File exists:Not a directory:Is a directory:Permission denied:Directory not empty:Not owner:Invalid argument:Read-only file system:Bad address:Bad file number:fd is not a valid open file descriptor:Device busy:Operation not applicable:pathname is too long";
        (string[] rs, uint n_rs) = stdio.split(reasons, ":");
        (string[] ss, uint n_ss) = stdio.split(status, ":");
        for (Err e: errors) {
            (uint8 reason, uint16 explanation, string param) = e.unpack();
            string s_reason;
            string s_explanation;
            if (reason > n_rs)
                err.append("Provided reason index is out of range: " + str.toa(reason) + "\n");
            else
                s_reason = reason > 0 ? rs[reason - 1] : command_specific_reason;
            if (explanation > n_ss)
                err.append("Provided status index is out of range: " + str.toa(explanation) + "\n");
            else
                s_explanation = explanation > 0 ? ss[explanation - 1] : "no explanation provided";
            err.append(command + ": " + s_reason + str.quote(param));
            if (explanation > 0)
                err.append(s_explanation.empty() ? format("\n Failed expl. lookup r {} e {}\n", reason, explanation) : ": " + s_explanation);
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
