pragma ton-solidity >= 0.61.2;

// special: break : continue . eval exec exit export readonly return set shift times trap unset

import "pbuiltin_base.sol";
import "vars.sol";

abstract contract pbuiltin_special is pbuiltin_base {

    using libshellenv for shell_env;
    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        uint8[] pages = p.flag_set("f") ? [sh.FUNCTION] : _retrieve_pages(p);
        if (p.flag_set("p") || (p.flags_empty() && p.params().empty())) {
            for (uint8 n: pages)
                res = _print(p, res, e.environ[n]);
        } else {
            for (uint8 n: pages)
                e.environ[n] = _modify(p, e.environ[n]);
        }
        e.ofiles[libfdt.STDOUT_FILENO] = res;
        sv.cur_proc = p;
    }

    function _print(s_proc p, s_of f, string[] page) internal pure virtual returns (s_of res);
    function _modify(s_proc p, string[] page_in) internal pure virtual returns (string[]);
    function _retrieve_pages(s_proc p) internal pure virtual returns (uint8[]);
}
