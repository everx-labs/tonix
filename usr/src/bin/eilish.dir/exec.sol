pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract exec is Shell {

    function modify(string args, s_proc p_in) external pure returns (s_proc p) {
//        (, string[] params, , ) = arg.get_env(argv);
        (string[] params, , ) = arg.get_args(args);
        p = p_in;
        /*p.execve()

        p.
    "p_pid": "0",
    "p_oppid": "0",
    "p_comm": "",
    "p_args": {
      "ar_length": "0",
      "ar_args": ""
    },*/

        for (string param: params) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {

            }
        }
    }
    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, , ) = arg.get_args(args);
//        (bool substitute_command, bool empty_env, bool prepend_dash, bool f1, bool f2, bool f3, bool f4, bool f5) = arg.flag_values("acl12345", flags);
        uint16 pos;
        if (!params.empty())
            pos = str.toi(params[0]);
        out = "";
        if (!pool.empty())
            ec = EXECUTE_SUCCESS;
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
