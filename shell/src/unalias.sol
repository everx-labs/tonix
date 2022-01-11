pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract unalias is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        string hashmap_page = e[IS_POOL];
        string alias_page = _get_map_value("TOSH_ALIASES", hashmap_page);
        ec = 0;
        bool remove_all = _flag_set("a", flags);

        if (remove_all)
            hashmap_page = _translate(hashmap_page, alias_page, "");
        else {
            string initial_val = alias_page;
            for (string token: params) {
                string cur_val = _val(token, alias_page);
                if (cur_val.empty())
                    out.append("-tosh: unalias: " + token + ": not found\n");
                else {
                    string record = _wrap(token, W_SQUARE) + "=" + _wrap(cur_val, W_DQUOTE);
                    alias_page = _trim_spaces(_translate(alias_page, record, ""));
                }
            }
            if (initial_val != alias_page) {
                hashmap_page = _translate(hashmap_page, initial_val, alias_page);
                wr.push(Write(IS_POOL, hashmap_page, O_WRONLY));
            }
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
