pragma ton-solidity >= 0.61.0;

import "stypes.sol";

library libproc {
    function cred(s_proc p) internal returns (s_ucred) {
        return p.p_ucred;
    }

    function fdt(s_proc p) internal returns (s_xfiledesc) {
        return p.p_fd;
    }

    function cwd(s_proc p) internal returns (s_xpwddesc) {
        return p.p_pd;
    }

    function limits(s_proc p) internal returns (s_plimit) {
        return p.p_limit;
    }

    function command(s_proc p) internal returns (string) {
        return p.p_comm;
    }

    function sysent(s_proc p) internal returns (s_sysent[]) {
        return p.p_sysent;
    }

    function args(s_proc p) internal returns (s_pargs) {
        return p.p_args;
    }

    function env(s_proc p) internal returns (string[]) {
        return p.environ;
    }

}