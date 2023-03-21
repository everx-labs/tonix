pragma ton-solidity >= 0.67.0;

import "pbuiltin.sol";

contract unset is pbuiltin {
    using libstring for string;
    using vars for string[];
    using vars for string;
    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        uint8[] pages;
        bool unset_vars = cc.flag_set("v");
        if (unset_vars)
            pages.push(sh.VARIABLE);
        bool unset_functions = cc.flag_set("f");
        if (unset_functions)
            pages.push(sh.FUNCTION);
        string sattrs = unset_functions ? "-f" : unset_vars ? "+f" : "";

        for (uint8 n: pages) {
            string[] page = e.environ[n];
            for (string arg: cc.params()) {
                string line = vars.get_pool_record(arg, page);
                if (!line.empty()) {
                    (string attrs, ) = line.csplit(" ");
                    if (vars.match_attr_set(sattrs, attrs))
                        page.unset_var(arg);
                }
            }
            e.environ[n] = page;
        }
        rc = EXIT_SUCCESS;
    }
    function _name() internal pure override returns (string) {
        return "unset";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
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
