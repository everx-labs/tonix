pragma ton-solidity >= 0.53.0;

import "Shell.sol";
import "compspec.sol";

contract type_ is Shell, compspec {

    uint8 constant COMMAND_UNKNOWN  = 0;
    uint8 constant COMMAND_ALIAS    = 1;
    uint8 constant COMMAND_KEYWORD  = 2;
    uint8 constant COMMAND_FUNCTION = 3;
    uint8 constant COMMAND_BUILTIN  = 4;
    uint8 constant COMMAND_FILE     = 5;
    uint8 constant COMMAND_NOT_FOUND= 6;

    uint8 constant FORMAT_DEFAULT       = 1;
    uint8 constant FORMAT_TERSE         = 2;
    uint8 constant FORMAT_DISK_FILE_NAME = 3;
    uint8 constant FORMAT_ALL_LOCATIONS = 4;

    function b_exec(string[] e) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);

//        bool all_locations = _flag("a", env_in);
//        bool func_lookup = _flag("f", env_in);
        bool terse = _flag_set("t", flags);
//        bool disk_file_name = _flag("p", env_in);
//        bool path_search = _flag("P", env_in);

        string hashes = e[IS_BINPATH];

        for (string arg: params) {
            string t = _get_array_name(arg, e[IS_INDEX]);
            string value;
            if (t == "keyword")
                value = terse ? "keyword" : (arg + " is a shell keyword");
            else if (t == "alias")
                value = terse ? "alias" : (arg + " is aliased to `" + _val(arg, _get_map_value("TOSH_ALIASES", e[IS_POOL])) + "\'");
            else if (t == "function") {
//                value = terse ? "function" : (arg + " is a function\n" + _function_body(arg, e[IS_POOL]));
                value = terse ? "function" : (arg + " is a function\n" + _print_reusable(_get_pool_record(arg, e[IS_POOL])));
            } else if (t == "builtin")
                value = terse ? "builtin" : (arg + " is a shell builtin");
            else if (t == "command") {
                string path = _get_array_name(arg, hashes);
                if (!path.empty())
                    value = terse ? "file" : (arg + " is hashed (" + path + "/" + arg + ")");
                else
                    value = terse ? "file" : (arg + " is " + _get_array_name(arg, e[IS_BINPATH]) + "/" + arg);
            } else
                value = "-tosh: type: " + arg + ": not found";
            out.append(value + "\n");
        }
        ec = 0;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"type",
"[-afptP] name [name ...]",
"Display information about command type.",
"For each NAME, indicate how it would be interpreted if used as a command name.",
"-a        display all locations containing an executable named NAME; includes aliases, builtins, and functions, if and only if\n\
          the `-p' option is not also used\n\
-f        suppress shell function lookup\n\
-P        force a PATH search for each NAME, even if it is an alias, builtin, or function, and returns the name of the disk file\n\
          that would be executed\n\
-p        returns either the name of the disk file that would be executed, or nothing if `type -t NAME' would not return `file'\n\
-t        output a single word which is one of `alias', `keyword', `function', `builtin', `file' or `', if NAME is an alias, shell\n\
reserved word, shell function, shell builtin, disk file, or not found, respectively",
"NAME      Command name to be interpreted.",
"Returns success if all of the NAMEs are found; fails if any are not found.");
    }
}
