pragma ton-solidity >= 0.55.0;

import "../include/Internal.sol";
//import "arguments.sol";
import "../lib/stdio.sol";
import "../lib/arg.sol";
import "../lib/vars.sol";

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

//abstract contract Utility is Internal, arguments {
abstract contract Utility is Internal {

    function command_help() external pure returns (CommandHelp ch) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp ch);
}