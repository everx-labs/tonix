pragma ton-solidity >= 0.61.2;

// special: break : continue . eval exec exit export readonly return set shift times trap unset

import "pbuiltin_base.sol";
import "../../lib/vars.sol";

abstract contract pbuiltin_dict is pbuiltin_base {

    using libshellenv for shell_env;
    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = p.params();
        (mapping (uint8 => string) pages, bool do_print, bool do_modify, bool do_load, bool print_names, bool print_values) = _select(sv, e);
        if (do_print) {
            for ((, string page): pages)
                res = _print(p, res, params, page, print_names, print_values);
            e.ofiles[libfdt.STDOUT_FILENO] = res;
        }
        if (do_modify) {
            string page_out;
            for ((uint8 n, string page): pages) {
                (sv, page_out) = _modify(sv, params, page);
                if (page != page_out) {
                    e.puts("Updating page: " + page + " -> " + page_out);
                    e = _update_shell_env(e, sv, n, page_out);
                    e.puts("Updated env: " + e.print_shell_env());
                } else
                    e.puts("Nothing to update");
            }
        }
        if (do_load) {
            e.puts("Loading...");
            string page_out;
            for ((, string page): pages)
                (sv, e, page_out) = _load(sv, e, page);
            e.puts("Updated env: " + e.print_shell_env());
        }

    }

    function _select(svm sv, shell_env e_in) internal pure virtual returns (mapping (uint8 => string), bool, bool, bool, bool, bool);
    function _print(s_proc, s_of, string[] params, string page_in, bool, bool) internal pure virtual returns (s_of);
    function _modify(svm sv_in, string[] params, string page_in) internal pure virtual returns (svm, string);
    function _load(svm sv_in, shell_env e_in, string page_in) internal pure virtual returns (svm, shell_env, string);
    function _update_shell_env(shell_env e_in, svm sv, uint8 n, string page) internal pure virtual returns (shell_env);
}
