pragma ton-solidity >= 0.60.0;

import "Shell.sol";

abstract contract compspec is Shell {

// Values for COMPSPEC actions.  These are things the shell knows how to build internally
    uint32 constant CA_ALIAS        = 1 << 0;
    uint32 constant CA_ARRAYVAR     = 1 << 1;
    uint32 constant CA_BINDING      = 1 << 2;
    uint32 constant CA_BUILTIN      = 1 << 3;
    uint32 constant CA_COMMAND      = 1 << 4;
    uint32 constant CA_DIRECTORY    = 1 << 5;
    uint32 constant CA_DISABLED     = 1 << 6;
    uint32 constant CA_ENABLED      = 1 << 7;
    uint32 constant CA_EXPORT       = 1 << 8;
    uint32 constant CA_FILE	        = 1 << 9;
    uint32 constant CA_FUNCTION	    = 1 << 10;
    uint32 constant CA_GROUP	    = 1 << 11;
    uint32 constant CA_HELPTOPIC    = 1 << 12;
    uint32 constant CA_HOSTNAME     = 1 << 13;
    uint32 constant CA_JOB          = 1 << 14;
    uint32 constant CA_KEYWORD      = 1 << 15;
    uint32 constant CA_RUNNING      = 1 << 16;
    uint32 constant CA_SERVICE      = 1 << 17;
    uint32 constant CA_SETOPT       = 1 << 18;
    uint32 constant CA_SHOPT        = 1 << 19;
    uint32 constant CA_SIGNAL       = 1 << 20;
    uint32 constant CA_STOPPED      = 1 << 21;
    uint32 constant CA_USER         = 1 << 22;
    uint32 constant CA_VARIABLE     = 1 << 23;

// Values for COMPSPEC options field
    uint16 constant COPT_RESERVED   = 1 << 0;
    uint16 constant COPT_DEFAULT    = 1 << 1;
    uint16 constant COPT_FILENAMES  = 1 << 2;
    uint16 constant COPT_DIRNAMES   = 1 << 3;
    uint16 constant COPT_NOSPACE    = 1 << 4;

    function _option_map_name(string p_option) internal pure returns (string) {
        if (p_option == "a") return "alias"; // Names of alias
        if (p_option == "b") return "builtin"; // Names of shell builtins
        if (p_option == "c") return "command"; // Names of all commands
        if (p_option == "d") return "dirname"; // Names of directory
        if (p_option == "e") return "export"; // Names of exported shell variables
        if (p_option == "f") return "filename"; // Names of file and functions
        if (p_option == "g") return "group"; // Names of groups
        if (p_option == "j") return "job"; // Names of job
        if (p_option == "k") return "keyword"; // Names of Shell reserved words
        if (p_option == "s") return "service"; // Names of service
        if (p_option == "u") return "user"; // Names of userAlias names
        if (p_option == "v") return "variable"; // Names of shell variables

        if (p_option == "F") return "function";
        if (p_option == "h") return "helptopic";
        if (p_option == "p") return "positional";
        if (p_option == "l") return "limit";
        if (p_option == "r") return "redirect";
        if (p_option == "i") return "index";
    }
}