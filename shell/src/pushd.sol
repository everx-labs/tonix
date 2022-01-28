pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract pushd is Shell {

    function builtin_read_fs(string args, string pool, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        string page = pool;

        bool suppress_dir_change = arg.flag_set("n", flags);

        string s_attrs = "--";
        string cur_dir = vars.val("PWD", page);
        string old_wd = vars.val("OLDPWD", page);
        string home_dir = vars.val("HOME", page);
        string arg = params.empty() ? home_dir : params[0];

        uint16 wd = fs.resolve_absolute_path(cur_dir, inodes, data);

        if (arg == "~")
            arg = home_dir;
        else if (arg == "-")
            arg = old_wd;

        (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(arg, wd, inodes, data);

        if (ft == FT_DIR) {
            string new_dir = fs.get_absolute_path(index, inodes, data);
            page = vars.set_var(s_attrs, "OLDPWD=" + cur_dir, page);
            page = vars.set_var(s_attrs, "PWD=" + new_dir, page);
            page = vars.set_var(s_attrs, "WD=" + format("{}", index), page);

            res = page;
        } else if (ft == FT_UNKNOWN) {
            ec = ENOENT;
        } else {
            ec = ENOTDIR;
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"pushd",
"[-n] [+N | -N | dir]",
"Add directories to stack.",
"Adds a directory to the top of the directory stack, or rotates the stack, making the new top\n\
of the stack the current working directory.  With no arguments, exchanges the top two directories.",
"-n        Suppresses the normal change of directory when adding directories to the stack, so only the stack is manipulated.",
"+N        Rotates the stack so that the Nth directory (counting from the left of the list shown by `dirs', starting with zero) is at the top.\n\
-N        Rotates the stack so that the Nth directory (counting from the right of the list shown by `dirs', starting with zero) is at the top.\n\
dir       Adds DIR to the directory stack at the top, making it the new current working directory.\n\
The `dirs' builtin displays the directory stack.",
"Returns success unless an invalid argument is supplied or the directory change fails.");
    }
}
