pragma ton-solidity >= 0.61.2;

// special: break : continue . eval exec exit export readonly return set shift times trap unset

import "pbuiltin_base.sol";
import "../../lib/vars.sol";

abstract contract pbuiltin_special is pbuiltin_base {

    using libshellenv for shell_env;
    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        mapping (uint8 => string) pages = _retrieve_pages(e, p);

        string[] params = p.params();
        if (p.flag_set("p") || (p.flags_empty() && params.empty())) {
            for ((, string page): pages)
                res = _print(p, res, params, page);
        } else {
            string page_out;
            for ((uint8 n, string page): pages) {
                (p, page_out) = _modify(p, params, page);
                if (page != page_out) {
                    res.fputs("Updating page: " + page + " -> " + page_out);
                    e = _update_shell_env(e, n, page_out);
                    res.fputs("Updated env: " + e.print_shell_env());
                } else
                    res.fputs("Nothing to update");
            }
        }
        e.ofiles[libfdt.STDOUT_FILENO] = res;
        sv.cur_proc = p;
    }

    function _print(s_proc p_in, s_of res, string[] params, string page_in) internal pure virtual returns (s_of);
    function _modify(s_proc p_in, string[] params, string page_in) internal pure virtual returns (s_proc, string);
    function _update_shell_env(shell_env e_in, uint8 n, string page) internal pure virtual returns (shell_env);
    function _retrieve_pages(shell_env e_in, s_proc p_in) internal pure virtual returns (mapping (uint8 => string));
}
