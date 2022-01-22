pragma ton-solidity >= 0.55.0;

import "../include/Internal.sol";
import "arguments.sol";
import "../lib/stdio.sol";

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

    function command_help() external pure returns (CommandHelp ch) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp ch);
}