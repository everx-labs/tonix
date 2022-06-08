pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract echo is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        p.puts(libstring.join_fields(p.params(), " "));
        if (!p.flag_set("n"))
            p.puts("\n");
        sv.cur_proc = p;
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
