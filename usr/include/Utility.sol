pragma ton-solidity >= 0.60.0;

import "Base.sol";
import "parg.sol";
import "utilhelp_h.sol";
import "proc_h.sol";
import "sb_h.sol";
abstract contract Utility is Base {

    using libstring for string;
    using str for string;
    using xio for s_of;
    using parg for s_proc;
    using io for s_proc;

    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp);

    function print_usage() external pure returns (string) {
        (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
        options.translate("\n", "\n  ");
        options = "Options:\n" + options;
        string usage = "Usage: " + name + " " + synopsis;
        return libstring.join_fields([usage, description, options], '\n');
    }

}