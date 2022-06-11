pragma ton-solidity >= 0.61.0;

import "putil.sol";

contract pathchk is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
//        bool posix = arg.flag_set("p", flags);
        bool leading_hyphens = p.flag_set("P");
        bool no_opts = p.flags_empty();

        for (string param: params) {
            if (param.empty()) {
                p.perror(no_opts ? ("\'" + param + "\': No such file or directory\n") : "empty file name");
                continue;
            }
            string first = param.substr(0, 1);
            if (first == "-" && leading_hyphens)
                p.puts("leading \'-\' in a component of file name \'" + param + "\'");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"pathchk",
"[OPTION]... NAME...",
"check whether file names are valid or portable",
"Diagnose invalid or unportable file names.",
"-p      check for most POSIX systems\n\
-P      check for empty names and leading \"-\"",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
