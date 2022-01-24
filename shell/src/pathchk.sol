pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract pathchk is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, string flags, ) = arg.get_env(argv);
//        bool posix = arg.flag_set("p", flags);
        bool leading_hyphens = arg.flag_set("P", flags);
        bool no_opts = flags.empty();

        for (string s_arg: params) {
            if (s_arg.empty()) {
                out.append("pathchk: " + (no_opts ? ("\'" + s_arg + "\': No such file or directory\n") : "empty file name\n"));
                ec = EXECUTE_FAILURE;
                continue;
            }
            string first = s_arg.substr(0, 1);
            if (first == "-" && leading_hyphens)
                out.append("pathchk: leading \'-\' in a component of file name \'" + s_arg + "\'\n");
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
