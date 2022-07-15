pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "job_h.sol";
import "vars.sol";

abstract contract job_control is pbuiltin_base {
    using vars for string[];
    function main(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        uint8 rc;
        (rc, e, j) = _main(e_in, j_in);
        e.environ[sh.ERRNO].set_int_val("RETURN_CODE", rc);
        if (rc > 0) {
            e.environ[sh.ERRNO].set_val("BUILTIN_MOD", _name());
        }
    }

    function _main(shell_env e, job_list j) internal pure virtual returns (uint8 rc, shell_env, job_list);
    function _name() internal pure virtual returns (string);
}
