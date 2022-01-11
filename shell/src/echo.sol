pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract echo is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] /*wr*/) {
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);
        bool no_trailing_newline = _flag_set("n", flags);
        out = _join_fields(args, " ");
        if (!no_trailing_newline)
            out.append("\n");
        ec = EXECUTE_SUCCESS;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"echo",
"[-neE] [arg ...]",
"Write arguments to the standard output.",
"Display the ARGs, separated by a single space character and followed by a newline, on the standard output.",
"-n        do not append a newline\n\
-e        enable interpretation of the following backslash escapes\n\
-E        explicitly suppress interpretation of backslash escapes",
"",
"Returns success unless a write error occurs.");
   }
}
