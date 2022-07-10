pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "vars.sol";

abstract contract pbuiltin is pbuiltin_base {

    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = _main(p, p.params(), e_in);
        sv.cur_proc = p;
    }

    function _main(s_proc p_in, string[] params, shell_env e) internal pure virtual returns (shell_env);
}
