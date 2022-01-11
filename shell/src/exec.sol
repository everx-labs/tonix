pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract exec is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, string argv) = _get_args(e[IS_ARGS]);
        uint n_params = params.length;
        ec = EXECUTE_SUCCESS;
        bool substitute_command = _flag("a", e);
        bool empty_env = _flag("c", e);
        bool prepend_dash = _flag("l", e);
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
