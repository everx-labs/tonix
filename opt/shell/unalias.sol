pragma ton-solidity >= 0.67.0;

import "pbuiltin.sol";

contract unalias is pbuiltin {
    using vars for string[];
    using vars for string;
    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] page;
        if (!cc.flag_set("a")) {
            page = e.environ[sh.ALIAS];
            for (string param: cc.params()) {
                page.unset_var(param);
                e.environ[sh.ARRAYVAR][sh.ALIAS].arrayvar_remove(param);
            }
        }
        rc = EXIT_SUCCESS;
        e.environ[sh.ALIAS] = page;
    }
    function _name() internal pure override returns (string) {
        return "unalias";
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
"[-a] name [name ...]",
"Remove each NAME from the list of defined aliases.",
"",
"-a        remove all alias definitions",
"",
"Return success unless a NAME is not an existing alias.");
    }
}
