pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract unalias is Shell {

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = _get_args(args);
        string alias_page = pool;
        bool remove_all = _flag_set("a", flags);
        ec = EXECUTE_SUCCESS;
        if (remove_all)
//            res = _translate(pool, alias_page, "");
            res = "";
        else {
            string initial_val = alias_page;
            for (string token: params) {
                string record = _get_pool_record(token, alias_page);
                if (!record.empty()) {
                    alias_page = _translate(alias_page, record + "\n", "");
                } else
                    ec = EXECUTE_FAILURE;
            }
            if (initial_val != alias_page)
                res = alias_page;
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
