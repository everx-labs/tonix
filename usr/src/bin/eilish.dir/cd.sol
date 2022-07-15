pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";

contract cd is pbuiltin_base {

    function main(shell_env e_in) external pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        s_of cur_dir = e.cwd;
        string[] page = e.environ[sh.VARIABLE];
        string scur_dir = vars.val("PWD", page);
        string old_cwd = vars.val("OLDPWD", page);
        string home_dir = vars.val("HOME", page);
        string arg = params.empty() ? home_dir : params[0];

        if (arg == "~")
            arg = home_dir;
        else if (arg == "-")
            arg = old_cwd;

        s_dirent[] dents = dirent.parse_dirents(cur_dir.buf.buf);
        for (s_dirent de: dents) {
            if (de.d_name == arg) {
                if (de.d_type != libstat.FT_DIR)
                    e.perror(arg + ": not a directory");
                else {
                    string new_dir = scur_dir + "/" + arg;
                    page = vars.set_var("", "OLDPWD=" + scur_dir, page);
                    page = vars.set_var("", "PWD=" + new_dir, page);
                    page = vars.set_var("", "WD=" + str.toa(de.d_fileno), page);
                    e.environ[sh.VARIABLE] = page;
                }
            }
        }
        e.perror(arg + ": no such file or directory");
    }

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
