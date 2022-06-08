pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract unset is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        bool unset_vars = p.flag_set("v");
        bool unset_functions = p.flag_set("f");
        string sattrs = unset_functions ? "-f" : unset_vars ? "+f" : "";
        string pool = vmem.vmem_fetch_page(sv.vmem[1], unset_functions ? 9 : 8);
        for (string arg: p.params()) {
            string line = vars.get_pool_record(arg, pool);
            if (!line.empty()) {
                (string attrs, ) = line.csplit(" ");
                if (vars.match_attr_set(sattrs, attrs)) {
                    pool.translate(line + "\n", "");
                }
            } else {
                p.perror(arg + " not found");
                // not found
            }
        }
        sv.vmem[1].vm_pages[unset_functions ? 9 : 8] = pool;
        sv.cur_proc = p;
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
