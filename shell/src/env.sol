pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract env is Utility {

    function exec(Session session, InputS input) external pure returns (string out) {
        (, string[] args, ) = input.unpack();
        (, , , , string user_name, , , string cwd) = session.unpack();
        if (args.empty())
            out = format("PWD={}\nLOGNAME={}\nUSER={}\n", cwd, user_name, user_name);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("env", "run a program in a modified environment", "[OPTION]... [COMMAND [ARG]...]",
            "Run COMMAND in the environment.",
            "i0v", 1, M, [
            "start with an empty environment",
            "end each output line with NUL, not newline",
            "print verbose information for each processing step"]);
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
