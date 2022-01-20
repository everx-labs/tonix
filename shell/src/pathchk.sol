pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract pathchk is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, string flags, ) = _get_env(argv);
//        bool posix = _flag_set("p", flags);
        bool leading_hyphens = _flag_set("P", flags);
        bool no_opts = flags.empty();

        for (string arg: params) {
            if (arg.empty()) {
                out.append("pathchk: " + (no_opts ? ("\'" + arg + "\': No such file or directory\n") : "empty file name\n"));
                ec = EXECUTE_FAILURE;
                continue;
            }
            string first = arg.substr(0, 1);
            if (first == "-" && leading_hyphens)
                out.append("pathchk: leading \'-\' in a component of file name \'" + arg + "\'\n");
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("pathchk", "check whether file names are valid or portable", "[OPTION]... NAME...",
            "Diagnose invalid or unportable file names.",
            "pP", 1, M, [
            "check for most POSIX systems",
            "check for empty names and leading \"-\""]);
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
