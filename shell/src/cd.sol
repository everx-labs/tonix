pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract cd is Shell {

    function builtin_read_fs(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, , ) = _get_args(e[IS_ARGS]);
        uint16 page_index = IS_POOL;
        string page = e[page_index];

        string s_attrs = "--";
        string cur_dir = _val("PWD", page);
        string old_wd = _val("OLDPWD", page);
        string home_dir = _val("HOME", page);
        string dbg;
        out = "";

//        if (params.empty())
//            params.push("~");
        string arg = params.empty() ? home_dir : params[0];

        uint16 wd = _resolve_absolute_path(cur_dir, inodes, data);

        if (arg == "~")
            arg = home_dir;
        else if (arg == "-")
            arg = old_wd;

        (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, wd, inodes, data);

        if (ft == FT_DIR) {
            string new_dir = _get_absolute_path(index, inodes, data);

            dbg.append("CD: " + cur_dir + " -> " + new_dir + "\n");

            page = _set_var(s_attrs, "OLDPWD=" + cur_dir, page);
            page = _set_var(s_attrs, "PWD=" + new_dir, page);
            page = _set_var(s_attrs, "WD=" + format("{}", index), page);

            if (e[page_index] != page)
                wr.push(Write(page_index, page, O_WRONLY));
        } else if (ft == FT_UNKNOWN) {
            ec = ENOENT;
        } else {
            ec = ENOTDIR;
        }

        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
    }

    function _dereference(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (Arg) {
        bool expand_symlinks = (mode & EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
        Inode inode;
        if (ino > 0 && inodes.exists(ino))
            inode = inodes[ino];
        if (expand_symlinks && ft == FT_SYMLINK) {
            (ft, s_arg, ino) = _get_symlink_target(inode, data[ino]).unpack();
        }
        return Arg(s_arg, ft, ino, parent, dir_index);
    }

//    function _get_command_info(string c) internal pure returns (string synopsis, string purpose, string description, string options, string arguments, string exit_status) {
    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"cd",
"[-L|[-P [-e]] [-@]] [dir]",
"Change the shell working directory.",
"Change the current directory to DIR. The default DIR is the value of the HOME shell variable. The variable CDPATH\n\
defines the search path for the directory containing DIR. Alternative directory names in CDPATH are separated\n\
by a colon (:). A null directory name is the same as the current directory. If DIR begins with a slash (/), then\n\
CDPATH is not used.\nIf the directory is not found, and the shell option `cdable_vars' is set, the word is assumed\n\
to be a variable name. If that variable has a value, its value is used for DIR.",
"-L        force symbolic links to be followed: resolve symbolic links in DIR after processing instances of `..'\n\
-P        use the physical directory structure without following symbolic links: resolve symbolic links in DIR\n\
before processing instances of `..'\n\
-e        if the -P option is supplied, and the current working directory cannot be determined successfully, exit with a non-zero status\n\
-@        on systems that support it, present a file with extended attributes as a directory containing the file attributes",
"The default is to follow symbolic links, as if `-L' were specified. `..' is processed by removing the immediately\n\
previous pathname component back to a slash or the beginning of DIR.",
"Returns 0 if the directory is changed, and if $PWD is set successfully when -P is used; non-zero otherwise.");
    }

}
