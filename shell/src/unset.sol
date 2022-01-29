pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract unset is Shell {

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool unset_vars = arg.flag_set("v", flags);
        bool unset_functions = arg.flag_set("f", flags);
        string s_attrs = unset_functions ? "-f" : unset_vars ? "+f" : "";
        string page = pool;
        for (string arg: params) {
            string line = vars.get_pool_record(arg, pool);
            if (!line.empty()) {
                (string attrs, ) = str.split(line, " ");
                if (vars.match_attr_set(s_attrs, attrs)) {
                    page = stdio.translate(page, line + "\n", "");
                }
            } else {
                ec = EXECUTE_FAILURE;
//                out.append("unset: " + arg + " not found\n");
                // not found
            }
        }
        res = page;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"unset",
"[-f] [-v] [-n] [name ...]",
"Unset values and attributes of shell variables and functions.",
"For each NAME, remove the corresponding variable or function.",
"-f        treat each NAME as a shell function\n\
-v        treat each NAME as a shell variable\n\
-n        treat each NAME as a name reference and unset the variable itself rather than the variable it references",
"Without options, unset first tries to unset a variable, and if that fails, tries to unset a function.\nSome variables cannot be unset; also see `readonly'.",
"Returns success unless an invalid option is given or a NAME is read-only.");
    }
}
