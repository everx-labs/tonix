pragma ton-solidity >= 0.61.2;

import "pbuiltin_special.sol";

contract unset is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc p) internal pure override returns (mapping (uint8 => string) pages) {
        if (p.flag_set("f"))
            pages[9] = e.functions;
        else
            pages[8] = e.vars;
    }

    function _update_shell_env(shell_env e_in, uint8 n, string page) internal pure override returns (shell_env e) {
        e = e_in;
        if (n == 8)
            e.vars = page;
        else if (n == 9)
            e.functions = page;
    }

    function _print(s_proc p, s_of f, string[] , string page) internal pure override returns (s_of res) {
        res = f;
        p.puts(page);
    }

    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        bool unset_vars = p.flag_set("v");
        bool unset_functions = p.flag_set("f");
        string sattrs = unset_functions ? "-f" : unset_vars ? "+f" : "";
        page = page_in;
            for (string arg: params) {
                string line = vars.get_pool_record(arg, page);
                if (!line.empty()) {
                    (string attrs, ) = line.csplit(" ");
                    if (vars.match_attr_set(sattrs, attrs)) {
                        page.translate(line + "\n", "");
                    }
                } else
                    p.perror(arg + " not found");
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
