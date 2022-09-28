pragma ton-solidity >= 0.62.0;

import "Utility.sol";
import "pw.sol";
import "unistd.sol";
//import "sbuf.sol";

contract reboot is Utility {

    using sbuf for s_sbuf;
    function _get_std(string[] names) internal pure returns (s_of[] sof) {
        s_sbuf s;
        s.sbuf_new_auto();
        s.sbuf_finish();
        uint16 i;
        for (string str: names)
            sof.push(s_of(0, io.SRD, i++, str, 0, s));
    }

    function main() external pure returns (s_proc p) {
        string p_comm = "init";
        uint16 uid = 0;
        uint16 gid = 0;
        uint16 n_ref = 1;
        uint16 pid = 1;
        s_ucred p_ucred = s_ucred(n_ref, uid, uid, uid, 1, gid, gid, "root", gid, [uint16(gid)]);
        s_of[] fdt_ofiles = _get_std(["/dev/stdin", "/dev/stdout", "/dev/stderr", "errno", "/", "/"]);
        fdt_ofiles.push(er.export());
        s_xfiledesc p_fd = s_xfiledesc(8, fdt_ofiles);
        s_xpwddesc p_pd = s_xpwddesc(fdt_ofiles[4], fdt_ofiles[5], 0x1FF);

        s_plimit p_limit;    // Resource limits.
        uint32 p_flag;       // P_* flags.
        s_pargs p_args;      // Process arguments.
        s_sysent[] p_sysent; // Syscall dispatch info.
        string[] environ;
        uint8 p_xexit;      // Exit code.
//        p = s_proc(p_ucred, p_fd, p_pd, p_limit, p_flag, pid, pid, p_comm, p_sysent, p_args, environ, p_xexit, n_ref, pid);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"reboot",
"[OPTIONS...]",
"reboot the machine",
"Reboot the system.",
"-p     reboot the machine\n\
-f      force immediate reboot\n\
-w      don't reboot, just write wtmp record\n\
-d      don't  write wtmp record",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
