pragma ton-solidity >= 0.63.0;

import "pbuiltin_base.sol";
import "vars.sol";
import "job_h.sol";

abstract contract pbuiltin is pbuiltin_base {
    using vars for string[];
    using libjobcommand for job_cmd;
    function main(shell_env e_in, job_cmd cc_in) external pure returns (shell_env e, job_cmd cc) {
        cc = cc_in;
        (cc.ec, e) = _main(e_in, cc_in);
    }

    function _main(shell_env e, job_cmd cc) internal pure virtual returns (uint8 rc, shell_env);
    function _name() internal pure virtual returns (string);
}
