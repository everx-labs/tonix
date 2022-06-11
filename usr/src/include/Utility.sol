pragma ton-solidity >= 0.60.0;

import "fs_types.sol";
import "Base.sol";
import "../lib/arg.sol";
import "../lib/fs.sol";
import "../lib/aio.sol";
import "../lib/er.sol";
import "../lib/libstatmode.sol";
import "../lib/fts.sol";
import "../lib/bio.sol";
import "../lib/sbuf.sol";
import "../lib/unistd.sol";
import "../lib/ucred.sol";
import "../lib/io.sol";
import "../lib/parg.sol";
import "../lib/libhelp.sol";
import "../sys/sys/uma.sol";

/*struct CommandHelp {
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
}*/

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
//    using std for s_of[];
    using libstatmode for uint16;
    using libstat for s_stat;
    using libbio for s_biobuf;
    using sbuf for s_sbuf;
    using parg for s_proc;
    using io for s_proc;
    using sucred for s_ucred;
//    using libzone for uma_zone;
//    using libuma for uma_zone[];
//    using libkeg for uma_keg;
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