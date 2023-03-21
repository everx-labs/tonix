pragma ton-solidity >= 0.67.0;

import "pbuiltin_base.sol";

contract exec is pbuiltin_base {

    function main(shell_env e_in, job_cmd cc) external pure returns (shell_env e) {
        e = e_in;
//        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
//        string[] params = e.params();
//        (bool substitute_command, bool empty_env, bool prepend_dash, , , , , ) = e.flag_values("acl");
        /*if (empty_env)
            delete e.environ;
        if (substitute_command) {
            string sub = e.opt_value("a");
            e.p_comm = sub;
        }
        if (prepend_dash)
            p.p_comm = "-" + p.p_comm;*/
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"exec",
"[-cl] [-a name] [command [arguments ...]] [redirection ...]",
"Replace the shell with the given command.",
"Execute COMMAND, replacing this shell with the specified program. ARGUMENTS become the arguments to COMMAND. If COMMAND is not specified,\n\
any redirections take effect in the current shell.",
"-a name   pass NAME as the zeroth argument to COMMAND\n\
-c        execute COMMAND with an empty environment\n\
-l        place a dash in the zeroth argument to COMMAND",
"If the command cannot be executed, a non-interactive shell exits, unless the shell option `execfail' is set.",
"Returns success unless COMMAND is not found or a redirection error occurs.");
    }
}
