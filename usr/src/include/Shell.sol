pragma ton-solidity >= 0.61.2;

import "Base.sol";
//import "../lib/arg.sol";
import "../lib/fs.sol";
import "../lib/io.sol";
import "../lib/parg.sol";

struct BuiltinHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string arguments;
    string exit_status;
}

abstract contract Shell is Base {

    // Special exit statuses used by the shell, internally and externally
    uint8 constant EX_BINARY_FILE   = 126;
    uint8 constant EX_NOEXEC        = 127;
    uint8 constant EX_NOINPUT       = 128;
    uint8 constant EX_NOTFOUND      = 129;
    uint8 constant EX_SHERRBASE     = 192;	//all special error values are > this
    uint8 constant EX_BADSYNTAX     = 193;	// shell syntax error
    uint8 constant EX_USAGE         = 194;	// syntax error in usage
    uint8 constant EX_REDIRFAIL     = 195;	// redirection failed
    uint8 constant EX_BADASSIGN     = 196;	// variable assignment error
    uint8 constant EX_EXPFAIL       = 197;	// word expansion failed

    string constant FLAG_ON = '-';
    string constant FLAG_OFF = '+';

    using libstring for string;
    using str for string;
    using xio for s_of;
    using io for s_proc;
    using parg for s_proc;
//    using uma_keg for s_uma_keg;

    function builtin_help() external pure returns (BuiltinHelp bh) {
        return _builtin_help();
    }

    function _builtin_help() internal pure virtual returns (BuiltinHelp bh);
}
