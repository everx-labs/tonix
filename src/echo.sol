pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract echo is Shell {

    function print(string args, string /*pool*/) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool no_trailing_newline = arg.flag_set("n", flags);
        out = stdio.join_fields(params, " ");
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
