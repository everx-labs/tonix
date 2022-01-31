pragma ton-solidity >= 0.56.0;

import "include/Internal.sol";
import "lib/arg.sol";
import "lib/fs.sol";

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

    function _file_stati(string[] names, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        for (string s: names) {
            uint16 index;
            uint8 ft;
            if (s.substr(0, 1) == "/") {
                index = fs.resolve_absolute_path(s, inodes, data);
                if (index >= INODES && inodes.exists(index))
                    ft = inode.mode_to_file_type(inodes[index].mode);
            } else
                (index, ft, , ) = fs.resolve_relative_path(s, wd, inodes, data);
            out.append(vars.var_record(inode.file_type_sign(ft), s, str.toa(index)) + "\n");
        }
    }

    function builtin_help() external pure returns (BuiltinHelp bh) {
        return _builtin_help();
    }

    function _builtin_help() internal pure virtual returns (BuiltinHelp bh);
}
