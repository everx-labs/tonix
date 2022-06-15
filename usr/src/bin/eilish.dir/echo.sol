pragma ton-solidity >= 0.61.1;

import "pbuiltin.sol";

contract echo is pbuiltin {

    function _main(s_proc p_in, string[] params, shell_env) internal pure override returns (s_proc p) {
        p = p_in;
        p.puts(libstring.join_fields(params, " "));
        if (!p_in.flag_set("n"))
            p.puts("\n");
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
