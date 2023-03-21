pragma ton-solidity >= 0.67.0;

import "Base.sol";
import "parg.sol";
import "utilhelp_h.sol";
import "libstring.sol";

abstract contract Utility is Base {

    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp);

    function print_usage() external pure returns (string) {
        (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
        options = libstring.translate(options, "\n", "\n  ");
        options = "Options:\n" + options;
        string usage = "Usage: " + name + " " + synopsis;
        return libstring.join_fields([usage, description, options], '\n');
    }

}