pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract unset is pbuiltin_special {

    function _retrieve_pages(s_proc p) internal pure override returns (uint8[]) {
        return [p.flag_set("f") ? sh.FUNCTION : sh.VARIABLE];
    }

    function _print(s_proc, s_of f, string[]) internal pure override returns (s_of res) {
        res = f;
    }

    function _modify(s_proc p, string[] page_in) internal pure override returns (string[] page) {
        bool unset_vars = p.flag_set("v");
        bool unset_functions = p.flag_set("f");
        string sattrs = unset_functions ? "-f" : unset_vars ? "+f" : "";
        page = page_in;
        for (string arg: p.params()) {
            string line = vars.get_pool_record(arg, page);
            if (!line.empty()) {
                (string attrs, ) = line.csplit(" ");
                if (vars.match_attr_set(sattrs, attrs))
                    page = vars.unset_var(arg, page);
            }
        }
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
