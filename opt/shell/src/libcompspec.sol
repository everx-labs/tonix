pragma ton-solidity >= 0.62.0;

// Values for COMPSPEC actions.  These are things the shell knows how to build internally
library libcompspec {
    uint32 constant CA_ALIAS     = 1 << 0;
    uint32 constant CA_ARRAYVAR  = 1 << 1;
    uint32 constant CA_BINDING   = 1 << 2;
    uint32 constant CA_BUILTIN   = 1 << 3;
    uint32 constant CA_COMMAND   = 1 << 4;
    uint32 constant CA_DIRECTORY = 1 << 5;
    uint32 constant CA_DISABLED  = 1 << 6;
    uint32 constant CA_ENABLED   = 1 << 7;
    uint32 constant CA_EXPORT    = 1 << 8;
    uint32 constant CA_FILE      = 1 << 9;
    uint32 constant CA_FUNCTION	 = 1 << 10;
    uint32 constant CA_GROUP	 = 1 << 11;
    uint32 constant CA_HELPTOPIC = 1 << 12;
    uint32 constant CA_HOSTNAME  = 1 << 13;
    uint32 constant CA_JOB       = 1 << 14;
    uint32 constant CA_KEYWORD   = 1 << 15;
    uint32 constant CA_RUNNING   = 1 << 16;
    uint32 constant CA_SERVICE   = 1 << 17;
    uint32 constant CA_SETOPT    = 1 << 18;
    uint32 constant CA_SHOPT     = 1 << 19;
    uint32 constant CA_SIGNAL    = 1 << 20;
    uint32 constant CA_STOPPED   = 1 << 21;
    uint32 constant CA_USER      = 1 << 22;
    uint32 constant CA_VARIABLE  = 1 << 23;

    uint8 constant CI_ALIAS     = 0;
    uint8 constant CI_ARRAYVAR  = 1;
    uint8 constant CI_BINDING   = 2;
    uint8 constant CI_BUILTIN   = 3;
    uint8 constant CI_COMMAND   = 4;
    uint8 constant CI_DIRECTORY = 5;
    uint8 constant CI_DISABLED  = 6;
    uint8 constant CI_ENABLED   = 7;
    uint8 constant CI_EXPORT    = 8;
    uint8 constant CI_FILE      = 9;
    uint8 constant CI_FUNCTION	= 10;
    uint8 constant CI_GROUP     = 11;
    uint8 constant CI_HELPTOPIC = 12;
    uint8 constant CI_HOSTNAME  = 13;
    uint8 constant CI_JOB       = 14;
    uint8 constant CI_KEYWORD   = 15;
    uint8 constant CI_RUNNING   = 16;
    uint8 constant CI_SERVICE   = 17;
    uint8 constant CI_SETOPT    = 18;
    uint8 constant CI_SHOPT     = 19;
    uint8 constant CI_SIGNAL    = 20;
    uint8 constant CI_STOPPED   = 21;
    uint8 constant CI_USER      = 22;
    uint8 constant CI_VARIABLE  = 23;
    uint8 constant CI_NONE      = 255;

// Values for COMPSPEC options field
    uint16 constant COPT_RESERVED   = 1 << 0;
    uint16 constant COPT_DEFAULT    = 1 << 1;
    uint16 constant COPT_FILENAMES  = 1 << 2;
    uint16 constant COPT_DIRNAMES   = 1 << 3;
    uint16 constant COPT_NOSPACE    = 1 << 4;

    function option_map_name(uint8 index, string p_option) internal returns (string) {
        if (index == CI_ALIAS || p_option == "a") return "alias"; // Names of alias
        if (index == CI_BUILTIN || p_option == "b") return "builtin"; // Names of shell builtins
        if (index == CI_COMMAND || p_option == "c") return "command"; // Names of all commands
        if (index == CI_DIRECTORY || p_option == "d") return "dirname"; // Names of directory
        if (index == CI_DISABLED) return "disabled";
        if (index == CI_ENABLED) return "enabled";
        if (index == CI_EXPORT || p_option == "e") return "export"; // Names of exported shell variables
        if (index == CI_FILE || p_option == "f") return "filename"; // Names of file and functions
        if (index == CI_FUNCTION || p_option == "F") return "function";
        if (index == CI_GROUP || p_option == "g") return "group"; // Names of groups
        if (index == CI_HELPTOPIC || p_option == "h") return "helptopic";
        if (index == CI_HOSTNAME || p_option == "h") return "hostname";
        if (index == CI_JOB || p_option == "j") return "job"; // Names of job
        if (index == CI_KEYWORD || p_option == "k") return "keyword"; // Names of Shell reserved words
        if (index == CI_RUNNING || p_option == "r") return "running";
        if (index == CI_SERVICE || p_option == "s") return "service"; // Names of service
        if (index == CI_SETOPT) return "setopt";
        if (index == CI_SHOPT) return "shopt";
        if (index == CI_SIGNAL) return "signal";
        if (index == CI_STOPPED) return "stopped";
        if (index == CI_USER || p_option == "u") return "user"; // Names of userAlias names
        if (index == CI_VARIABLE || p_option == "v") return "variable"; // Names of shell variables

        if (index == CI_NONE || p_option == "p") return "positional";
        if (index == CI_NONE || p_option == "l") return "limit";
        if (index == CI_NONE || p_option == "r") return "redirect";
        if (index == CI_NONE || p_option == "i") return "index";
    }

    function option_map_index(string name) internal returns (uint8 index, string p_option) {
        if (name == "alias") return (CI_ALIAS, "a"); // Names of alias
        if (name == "builtin") return (CI_BUILTIN, "b"); // Names of shell builtins
        if (name == "command") return (CI_COMMAND, "c"); // Names of all commands
        if (name == "dirname") return (CI_DIRECTORY, "d"); // Names of directory
        if (name == "disabled") return (CI_DISABLED, "d");
        if (name == "enabled") return (CI_ENABLED, "d");
        if (name == "export") return (CI_EXPORT, "e"); // Names of exported shell variables
        if (name == "filename") return (CI_FILE, "f"); // Names of file and functions
        if (name == "function") return (CI_FUNCTION, "F");
        if (name == "group") return (CI_GROUP, "g"); // Names of groups
        if (name == "helptopic") return (CI_HELPTOPIC, "h");
        if (name == "hostname") return (CI_HOSTNAME, "h");
        if (name == "job") return (CI_JOB, "j"); // Names of job
        if (name == "keyword") return (CI_KEYWORD, "k"); // Names of Shell reserved words
        if (name == "running") return (CI_RUNNING, "r");
        if (name == "service") return (CI_SERVICE, "s"); // Names of service
        if (name == "setopt") return (CI_SETOPT, "");
        if (name == "shopt") return (CI_SHOPT, "");
        if (name == "signal") return (CI_SIGNAL, "");
        if (name == "stopped") return (CI_STOPPED, "");
        if (name == "user") return (CI_USER, "u"); // Names of userAlias names
        if (name == "variable") return (CI_VARIABLE, "v"); // Names of shell variables
        if (name == "positional") return (CI_NONE, "p");
        if (name == "limit") return (CI_NONE, "l");
        if (name == "redirect") return (CI_NONE, "r");
        if (name == "index") return (CI_NONE, "i");
    }
}