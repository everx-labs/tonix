pragma ton-solidity >= 0.61.2;

import "pbuiltin_special.sol";
import "compspec.sol";

contract set is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc) internal pure override returns (mapping (uint8 => string) pages) {
        pages[libcompspec.CI_FILE] = e.functions;
        pages[libcompspec.CI_EXPORT] = e.vars;
        pages[libcompspec.CI_FUNCTION] = e.functions;
        pages[libcompspec.CI_HELPTOPIC] = e.dirstack;
        pages[libcompspec.CI_ALIAS]     = e.aliases;
//        pages[libcompspec.CI_ARRAYVAR]  = 1;
//        pages[libcompspec.CI_BINDING]   = 2;
        pages[libcompspec.CI_BUILTIN]   = e.read_file("builtin");
        pages[libcompspec.CI_COMMAND]   = e.read_file("command");
        pages[libcompspec.CI_DIRECTORY] = e.read_file("dirname");
        pages[libcompspec.CI_DISABLED]  = "";
        pages[libcompspec.CI_ENABLED]   = e.read_file("builtin");
        pages[libcompspec.CI_EXPORT]    = e.exports;
        pages[libcompspec.CI_FILE]      = e.read_file("filename");
        pages[libcompspec.CI_FUNCTION]  = e.functions;
        pages[libcompspec.CI_GROUP]     = e.read_file("group");
//        pages[libcompspec.CI_HELPTOPIC] = 12;
//        pages[libcompspec.CI_HOSTNAME]  = 13;
//        pages[libcompspec.CI_JOB]       = 14;
        pages[libcompspec.CI_KEYWORD]   = e.read_file("keyword");
//        pages[libcompspec.CI_RUNNING]   = 16;
//        pages[libcompspec.CI_SERVICE]   = 17;
//        pages[libcompspec.CI_SETOPT]    = 18;
//        pages[libcompspec.CI_SHOPT]     = 19;
//        pages[libcompspec.CI_SIGNAL]    = 20;
//        pages[libcompspec.CI_STOPPED]   = 21;
        pages[libcompspec.CI_USER]      = e.read_file("user");
        pages[libcompspec.CI_VARIABLE]  = e.vars;

    }

    function _update_shell_env(shell_env e_in, uint8, string ) internal pure override returns (shell_env e) {
        e = e_in;
    }

//    function _print(s_proc p_in, string[] params, string page) internal pure override returns (s_proc p) {
//        p = p_in;
    function _print(s_proc, s_of f, string[] , string page) internal pure override returns (s_of res) {
        res = f;
        res.fputs(page);
    }
    function _modify(s_proc p_in, string[] , string page_in) internal pure override returns (s_proc p, string page) {
        page = page_in;
        p = p_in;
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"set",
"[-abefhkmnptuvxBCHP] [--] [arg ...]",
"Set or unset values of shell options and positional parameters.",
"Change the value of shell attributes and positional parameters, or display the names and values of shell variables.",
"-a  Mark variables which are modified or created for export.\n\
-b  Notify of job termination immediately.\n\
-e  Exit immediately if a command exits with a non-zero status.\n\
-f  Disable file name generation (globbing).\n\
-h  Remember the location of commands as they are looked up.\n\
-k  All assignment arguments are placed in the environment for a command, not just those that precede the command name.\n\
-m  Job control is enabled.\n\
-n  Read commands but do not execute them.\n\
-p  Turned on whenever the real and effective user ids do not match. Disables processing of the $ENV file and importing\n\
    of shell functions.  Turning this option off causes the effective uid and gid to be set to the real uid and gid.\n\
-t  Exit after reading and executing one command.\n\
-u  Treat unset variables as an error when substituting.\n\
-v  Print shell input lines as they are read.\n\
-x  Print commands and their arguments as they are executed.\n\
-B  the shell will perform brace expansion\n\
-C  If set, disallow existing regular files to be overwritten by redirection of output.\n\
-E  If set, the ERR trap is inherited by shell functions.\n\
-H  Enable ! style history substitution.  This flag is on by default when the shell is interactive.\n\
-P  If set, do not resolve symbolic links when executing commands such as cd which change the current directory.\n\
-T  If set, the DEBUG and RETURN traps are inherited by shell functions.\n\
--  Assign any remaining arguments to the positional parameters. If there are no remaining arguments, the positional\n\
    parameters are unset.\n\
-   Assign any remaining arguments to the positional parameters. The -x and -v options are turned off.",
"Using + rather than - causes these flags to be turned off. The flags can also be used upon invocation of the shell.\n\
The current set of flags may be found in $-. The remaining n ARGs are positional parameters and are assigned, in order,\n\
to $1, $2, .. $n. If no ARGs are given, all shell variables are printed.",
"Returns success unless an invalid option is given.");
    }
}
