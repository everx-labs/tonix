pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract echo is Shell {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        p.puts(libstring.join_fields(p.params(), " "));
        if (!p.flag_set("n"))
            p.puts("\n");
    }

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool no_trailing_newline = arg.flag_set("n", flags);
        out = libstring.join_fields(params, " ");
        if (!no_trailing_newline)
            out.append("\n");
        if (!pool.empty())
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
