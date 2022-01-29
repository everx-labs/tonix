pragma ton-solidity >= 0.56.0;

import "include/Internal.sol";
import "lib/stdio.sol";
import "lib/vars.sol";
import "lib/arg.sol";

struct BuiltinHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string arguments;
    string exit_status;
}

abstract contract Shell is Internal {

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

    function builtin_help() external pure returns (BuiltinHelp bh) {
        return _builtin_help();
    }

    function _builtin_help() internal pure virtual returns (BuiltinHelp bh);
}
