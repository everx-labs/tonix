pragma ton-solidity >= 0.55.0;

import "../include/Internal.sol";
import "arguments.sol";

struct CommandHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string notes;
    string author;
    string bugs;
    string see_also;
    string version;
}

abstract contract Utility is Internal, arguments {

    struct CommandInfo {
        uint8 min_args;
        uint16 max_args;
        string options;
        string name;
    }

    function _command_info() internal pure virtual returns (string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions);

    function get_command_info() external pure returns (CommandInfo command_info) {
        (string name, , , , string option_list, uint8 min_args, uint16 max_args, ) = _command_info();
        return CommandInfo(min_args, max_args, option_list, name);
    }

    function usage() external pure returns (string out) {
        (string name, , string synopsis, string description, string option_list, , , string[] option_descriptions) = _command_info();
        string[] uses = _get_tsv(synopsis);
        string s_usage;
        for (string u: uses)
            s_usage.append("\t" + name + " " + u + "\n");
        string options = "\n";
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_list.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + s_usage + description + options;
    }

    function command_help() external pure returns (CommandHelp ch) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp ch);
}