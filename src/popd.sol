pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract popd is Shell {

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
            ec = er.ENOENT;
        } else {
            ec = er.ENOTDIR;
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"popd",
"[-n] [+N | -N]",
"Remove directories from stack.",
"Removes entries from the directory stack.  With no arguments, removes the top directory from the stack, and changes to the new top directory.",
"-n     Suppresses the normal change of directory when removing directories from the stack, so only the stack is manipulated.",
"+N Removes the Nth entry counting from the left of the list shown by `dirs', starting with zero.  For example:\n\
    `popd +0' removes the first directory, `popd +1' the second.\n\
-N  Removes the Nth entry counting from the right of the list shown by `dirs', starting with zero.  For example:\n\
    `popd -0' removes the last directory, `popd -1' the next to last.\n\
The `dirs' builtin displays the directory stack.",
"Returns success unless an invalid argument is supplied or the directory change fails.");
    }
}
