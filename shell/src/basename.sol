pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract basename is Utility {

    function exec(string[] e) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);

        bool multiple_args = _flag_set("a", flags);
        string line_terminator = _flag_set("z", flags) ? "\x00" : "\n";

        if (multiple_args)
            for (string s: args) {
                (, string not_dir) = _dir(s);
                out.append(not_dir + line_terminator);
            }
        else {
            (, out) = _dir(args[0]);
            out.append(line_terminator);
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("basename", "strip directory and suffix from filenames", "NAME",
            "Print NAME with any leading directory components removed.",
            "asz", 1, M, [
            "support multiple arguments and treat each as a NAME",
            "remove a trailing SUFFIX; implies -a",
            "end each output line with NUL, not newline"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
