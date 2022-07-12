pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "vars.sol";

abstract contract pbuiltin is pbuiltin_base {
    using vars for string[];
    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
//        s_proc p = sv.cur_proc;
        uint8 rc;
        (rc, e) = _main(e_in);
        e.environ[sh.ERRNO].set_int_val("RETURN_CODE", rc);
        if (rc > 0) {
            e.environ[sh.ERRNO].set_val("BUILTIN_MOD", _name());
        }
    }

    function _main(shell_env e) internal pure virtual returns (uint8 rc, shell_env);
    function _name() internal pure virtual returns (string);
}
