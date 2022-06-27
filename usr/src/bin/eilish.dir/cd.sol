pragma ton-solidity >= 0.61.2;

import "pbuiltin_special.sol";
import "../../lib/env.sol";

contract cd is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc) internal pure override returns (mapping (uint8 => string) pages) {
        pages[8] = e.vars;
    }

    function _update_shell_env(shell_env e_in, uint8, string page) internal pure override returns (shell_env e) {
        e = e_in;
        e.vars = page;
    }

//    function _print(s_proc p_in, string[] , string) internal pure override returns (s_proc p) {
//        p = p_in;
    function _print(s_proc , s_of f, string[] , string ) internal pure override returns (s_of res) {
        res = f;
    }

    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        page = page_in;

        s_of cur_dir = p.p_pd.pwd_cdir;
        string scur_dir = env.get("PWD", page);
        string old_cwd = env.get("OLDPWD", page);
        string home_dir = env.get("HOME", page);
        string arg = params.empty() ? home_dir : params[0];

        if (arg == "~")
            arg = home_dir;
        else if (arg == "-")
            arg = old_cwd;

        s_dirent[] dents = dirent.parse_dirents(cur_dir.buf.buf);
        for (s_dirent de: dents) {
            if (de.d_name == arg) {
                if (de.d_type != libstat.FT_DIR)
                    p.perror(arg + ": not a directory");
                else {
                    string new_dir = scur_dir + "/" + arg;
                    page = env.put("OLDPWD=" + scur_dir, page);
                    page = env.put("PWD=" + new_dir, page);
                    page = env.put("WD=" + format("{}", de.d_fileno), page);
                }
            }
        }
        p.perror(arg + ": no such file or directory");
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
