pragma ton-solidity >= 0.61.2;

import "pbuiltin.sol";

contract echo is pbuiltin {

    function _main(s_proc p, string[] params, shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        e.puts(libstring.join_fields(params, " "));
        if (!p.flag_set('n'))
            e.putchar('\n');
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"echo",
"[-neE] [arg ...]",
"Write arguments to the standard output.",
"Display the ARGs, separated by a single space character and followed by a newline, on the standard output.",
"-n        do not append a newline\n\
-e        enable interpretation of the backslash escapes\n\
-E        explicitly suppress interpretation of backslash escapes",
"",
"Returns success unless a write error occurs.");
   }
}
