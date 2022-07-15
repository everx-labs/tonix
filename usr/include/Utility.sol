pragma ton-solidity >= 0.60.0;

import "Base.sol";
import "fs.sol";
import "aio.sol";
import "er.sol";
import "fts.sol";
import "bio.sol";
import "sbuf.sol";
import "unistd.sol";
import "ucred.sol";
import "io.sol";
import "parg.sol";
import "libhelp.sol";
import "uma.sol";

struct Arg {
    string path;
    uint8 ft;
    uint16 idx;
    uint16 parent;
    uint16 dir_index;
}

abstract contract Utility is Base {

    using libstring for string;
    using str for string;
    using xio for s_of;
    using libstat for s_stat;
    using libbio for s_biobuf;
    using sbuf for s_sbuf;
    using parg for s_proc;
    using io for s_proc;
    using sucred for s_ucred;
    using vmem for s_vmem;

    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp);

    function print_usage() external pure returns (string) {
        (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
        string usage = "Usage: " + name + " " + synopsis;
        return libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
    }

}