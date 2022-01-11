pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract history is Shell {

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        /*return BuiltinHelp(
            "type",
            "[-afptP] name [name ...]",
            "Display information about command type.",
            "For each NAME, indicate how it would be interpreted if used as a command name.",
            "\
-a        display all locations containing an executable named NAME; includes aliases, builtins, and functions, if and only if\n\
          the `-p' option is not also used\n\
-f        suppress shell function lookup\n\
-P        force a PATH search for each NAME, even if it is an alias, builtin, or function, and returns the name of the disk file\n\
          that would be executed\n\
-p        returns either the name of the disk file that would be executed, or nothing if `type -t NAME' would not return `file'\n\
-t        output a single word which is one of `alias', `keyword', `function', `builtin', `file' or `', if NAME is an alias, shell\n\
reserved word, shell function, shell builtin, disk file, or not found, respectively",
            "NAME      Command name to be interpreted.",
            "Returns success if all of the NAMEs are found; fails if any are not found.");*/
    }
}
