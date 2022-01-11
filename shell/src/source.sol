pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract source is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, string argv) = _get_args(e[IS_ARGS]);
        ec = EXECUTE_SUCCESS;

        string dbg;
        string cmd = "mapfile";
        string cmd_arg = argv;
        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"source",
"filename [arguments]",
"Execute commands from a file in the current shell.",
"Read and execute commands from FILENAME in the current shell. The entries in $PATH are used to find the directory containing FILENAME. If any ARGUMENTS are supplied, they become the positional parameters when FILENAME is executed.",
"",
"",
"Returns the status of the last command executed in FILENAME; fails if FILENAME cannot be read.");
    }
}
