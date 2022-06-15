pragma ton-solidity >= 0.61.1;

import "pbuiltin_special.sol";

contract unalias is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc p) internal pure override returns (mapping (uint8 => string) pages) {
        pages[0] = e.e_aliases;
    }

    function _update_shell_env(shell_env e_in, uint8, string page) internal pure override returns (shell_env e) {
        e = e_in;
        e.e_aliases = page;
    }

    function _print(s_proc p_in, string[] , string ) internal pure override returns (s_proc p) {
        p = p_in;
    }
    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        string alias_page = page_in;
        bool remove_all = p.flag_set("a");
        if (remove_all)
            delete page;
        else {
            string initial_val = alias_page;
            for (string token: params) {
                string record = vars.get_pool_record(token, alias_page);
                if (!record.empty())
                    alias_page.translate(record + "\n", "");
            }
            if (initial_val != alias_page)
                page.translate(page_in, alias_page);
        }
    }

function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"unalias",
"[-a] name [name ...]",
"Remove each NAME from the list of defined aliases.",
"",
"-a        remove all alias definitions",
"",
"Return success unless a NAME is not an existing alias.");
    }
}
