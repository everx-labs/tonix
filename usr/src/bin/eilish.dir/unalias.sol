pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract unalias is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string alias_page = vmem.vmem_fetch_page(sv.vmem[1], 0);

        bool remove_all = p.flag_set("a");
        if (remove_all)
            delete sv.vmem[1].vm_pages[0];
        else {
            string initial_val = alias_page;
            for (string token: p.params()) {
                string record = vars.get_pool_record(token, alias_page);
                if (!record.empty())
                    alias_page.translate(record + "\n", "");
            }
            if (initial_val != alias_page)
                sv.vmem[1].vm_pages[0] = alias_page;
        }
        sv.cur_proc = p;
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
