pragma ton-solidity >= 0.61.1;

import "pbuiltin_base.sol";

abstract contract pbuiltin is pbuiltin_base {

    function main(svm sv_in, shell_env e_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        p = _main(p, p.params(), e_in);
        sv.cur_proc = p;
    }

    function _main(s_proc p_in, string[] params, shell_env e) internal pure virtual returns (s_proc);
}
