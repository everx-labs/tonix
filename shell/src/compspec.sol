pragma ton-solidity >= 0.53.0;

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

    function _gen_comp(string option, string pattern, mapping (uint => ItemHashMap) env_in) internal pure returns (string[] comp) {
        string option_map_name = _option_map_name(option);
        uint len = pattern.byteLength();
        bool print_all = pattern.empty();
        if (!option_map_name.empty()) {
            uint option_map_key = tvm.hash(option_map_name);
            if (env_in.exists(option_map_key))
                for ((, Item item): env_in[option_map_key].value) {
                    string item_name = item.name;
                    if (print_all || (len <= item_name.byteLength() && item_name.substr(0, len) == pattern))
                        comp.push(item.name);
                }
        }
    }

    function _try_complete(string name, mapping (uint => ItemHashMap) env_in) internal pure returns (string) {
        mapping (uint => Item) completions = env_in[tvm.hash("compspec")].value;
        uint command_key = tvm.hash(name);
        if (completions.exists(command_key))
            return completions[command_key].value;
    }

    function _comp_spec_attr(string p_option) internal pure returns (uint16) {
//        if ()uint16 constant IS_UNKNOWN      = 0;
        /*if (p_option == "b") return IS_BUILTIN;
        if (p_option == "c") return IS_COMMAND;
        if (p_option == "d") return IS_DIRNAME;
        if (p_option == "f") return IS_FILENAME; // Names of file and functions
        if (p_option == "g") return IS_GROUP; // Names of groups
        if (p_option == "j") return IS_JOB;
        if (p_option == "k") return IS_RESERVED_WORD; // Names of Shell reserved words
        if (p_option == "s") return IS_SERVICE; // Names of service
        if (p_option == "u") return IS_USER; // Names of userAlias names
        if (p_option == "v") return IS_VARIABLE; // Names of shell variables

        if (p_option == "h") return IS_HELP_TOPIC;
        if (p_option == "p") return IS_POSITIONAL;
        if (p_option == "l") return IS_LIMIT;
        if (p_option == "r") return IS_REDIRECT_OP;
        if (p_option == "i") return IS_INDEX;*/
    }

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

    function _action_map_name(string p_action) internal pure returns (string) {
        if (p_action == "alias") return "alias"; // Alias names. May also be specified as -a.
        if (p_action == "arrayvar") return "arrayvar"; // Array variable names.
        if (p_action == "binding") return "binding"; // Readline key binding names (see Bindable Readline Commands).
        if (p_action == "builtin") return "builtin"; // Names of shell builtin commands. May also be specified as -b.
        if (p_action == "command") return "command"; // Command names. May also be specified as -c.
        if (p_action == "directory") return "directory"; // Directory names. May also be specified as -d.
        if (p_action == "disabled") return "disabled"; // Names of disabled shell builtins.
        if (p_action == "enabled") return "enabled"; // Names of enabled shell builtins.
        if (p_action == "export") return "export"; // Names of exported shell variables. May also be specified as -e.
        if (p_action == "file") return "file"; // File names. May also be specified as -f.
        if (p_action == "function") return "function"; // Names of shell functions.
        if (p_action == "group") return "group"; // Group names. May also be specified as -g.
        if (p_action == "helptopic") return "helptopic"; // Help topics as accepted by the help builtin (see Bash Builtins).
        if (p_action == "hostname") return "hostname"; // Hostnames, as taken from the file specified by the HOSTFILE shell variable (see Bash Variables).
        if (p_action == "job") return "job"; // Job names, if job control is active. May also be specified as -j.
        if (p_action == "keyword") return "keyword"; // Shell reserved words. May also be specified as -k.
        if (p_action == "running") return "running"; // Names of running jobs, if job control is active.
        if (p_action == "service") return "service"; // Service names. May also be specified as -s.
        if (p_action == "setopt") return "shopt"; // Valid arguments for the -o option to the set builtin (see The Set Builtin).
        if (p_action == "shopt") return "shopt"; // Shell option names as accepted by the shopt builtin (see Bash Builtins).
        if (p_action == "signal") return "signal"; // Signal names.
        if (p_action == "stopped") return "stopped"; // Names of stopped jobs, if job control is active.
        if (p_action == "user") return "user"; // User names. May also be specified as -u.
        if (p_action == "variable") return "variable"; // Names of all shell variables. May also be specified as -v. 
    }


    function _try_expand(string arg, string arg_type, string[] e) internal pure returns (string res) {
        uint16 key_index = _map_index(arg_type);
        if (key_index > 0) {
            string map = e[key_index];
            string val = _value_of(arg, map);
            return val.empty() ? arg : val;
        }
    }

    function _map_index(string key) internal pure returns (uint16) {
        /*if (key == "integer") return IS_INTEGER;
        if (key == "builtin") return IS_BUILTIN;
        if (key == "command") return IS_COMMAND;
        if (key == "directory") return IS_DIRNAME;
        if (key == "file") return IS_FILENAME;
        if (key == "group") return IS_GROUP;
        if (key == "helptopic") return IS_HELP_TOPIC;
        if (key == "job") return IS_JOB;
        if (key == "keyword") return IS_RESERVED_WORD;
        if (key == "limit") return IS_LIMIT;
        if (key == "positional") return IS_POSITIONAL;
        if (key == "service") return IS_SERVICE;
        if (key == "user") return IS_USER;
        if (key == "option_list") return IS_OPTSTRING;
        if (key == "param_list") return IS_PARAM_LIST;
        if (key == "option_value") return IS_OPTION_VALUE;
        if (key == "pipeline") return IS_PIPELINE;*/
    }

}