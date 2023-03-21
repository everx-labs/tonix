pragma ton-solidity >= 0.67.0;

import "pbuiltin.sol";
contract set is pbuiltin {
    using libstring for string;
    using vars for string[];

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[][] ev = e.environ;
        string[] page = ev[sh.SETOPT];
        string shellflags = vars.val("-", ev[sh.VARIABLE]);
        string flags = vars.val("FLAGS", ev[sh.VARIABLE]);
        string attrs = vars.val("ATTRS", ev[sh.VARIABLE]);
        string[] params = cc.params();
        string o = e.opt_value("o");
        if (!o.empty()) {
            if (o == "allexport") flags.append("a");
            else if (o == "braceexpand") flags.append("B");
            else if (o == "errexit") flags.append("e");
            else if (o == "errtrace") flags.append("E");
            else if (o == "functrace") flags.append("T");
            else if (o == "hashall") flags.append("h");
            else if (o == "histexpand") flags.append("H");
            else if (o == "keyword") flags.append("k");
            else if (o == "monitor") flags.append("m");
            else if (o == "noclobber") flags.append("C");
            else if (o == "noexec") flags.append("n");
            else if (o == "noglob") flags.append("f");
            else if (o == "notify") flags.append("b");
            else if (o == "nounset") flags.append("u");
            else if (o == "onecmd") flags.append("t");
            else if (o == "physical") flags.append("P");
            else if (o == "privileged") flags.append("p");
            else if (o == "verbose") flags.append("v");
            else if (o == "xtrace") flags.append("x");
            else e.perror(o + ": invalid option value");
        }
        e.puts(libstring.join_fields(page, " "));
        e.puts(shellflags);
        e.puts(attrs);

        bytes sattrs = "abefhkmnptuvxBCEHPT";
        for (bytes1 b: sattrs) {
            if (str.strchr(flags, b) > 0 && str.strchr(attrs, b) == 0 && str.strchr(shellflags, b) == 0)
                shellflags.append(bytes(b));
            if (str.strchr(attrs, b) > 0 && str.strchr(flags, b) == 0 && str.strchr(shellflags, b) > 0)
                shellflags.translate(bytes(b), "");
        }
              /*history      enable command history
              ignoreeof    the shell will not exit upon reading EOF
              pipefail     the return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status
              posix        change the behavior of bash where the default operation differs from the Posix standard to match the standard*/
        e.environ[sh.VARIABLE].set_val("-", shellflags);
        string[] res = vars.filter(page, "-s", "", false, false);
        e.puts(_print_line(res));
        rc = 0;
    }

    function _print_line(string[] lines) internal pure returns (string res) {
        for (string line: lines)
            res.append(line + "\n");
    }

    function _name() internal pure override returns (string) {
        return "set";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
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
/*
a
b
e
f
h
k
m
n
p
t
u
v
x
B
C
E
H
P
T
*/
