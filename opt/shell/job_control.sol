pragma ton-solidity >= 0.67.0;

import "pbuiltin_base.sol";
import "libjobcommand.sol";
import "vars.sol";

abstract contract job_control is pbuiltin_base {
//    using vars for string[];
    function main(shell_env e_in, job_list j_in, job_cmd cc_in) external pure returns (shell_env e, job_list j, job_cmd cc) {
        (cc.ec, e, j, cc) = _main(e_in, j_in, cc_in);
    }

    function _main(shell_env e, job_list j, job_cmd cc_in) internal pure virtual returns (uint8 rc, shell_env, job_list, job_cmd);
    function _name() internal pure virtual returns (string);
}
