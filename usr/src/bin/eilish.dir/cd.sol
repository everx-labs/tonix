pragma ton-solidity >= 0.61.0;

import "Shell.sol";
import "../../lib/env.sol";

contract cd is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();

        string page = vmem.vmem_fetch_page(sv.vmem[1], 3);

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
                    sv.vmem[1].vm_pages[3] = page;
                }
                sv.cur_proc = p;
                return sv;
            }
        }
        p.perror(arg + ": no such file or directory");
        sv.cur_proc = p;
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
