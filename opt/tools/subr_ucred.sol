pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libucred.sol";
import "Base.sol";

contract subr_ucred is Base {

    uint16 constant SYS_getpid      = 20;
    uint16 constant SYS_setuid      = 23;
    uint16 constant SYS_getuid      = 24;
    uint16 constant SYS_geteuid     = 25;
    uint16 constant SYS_getppid     = 39;
    uint16 constant SYS_getegid     = 43;
    uint16 constant SYS_getgid      = 47;

    uint16 constant SYS_getgroups   = 79;
    uint16 constant SYS_setgroups   = 80;
    uint16 constant SYS_getpgrp     = 81;
    uint16 constant SYS_setpgid     = 82;
    uint16 constant SYS_setreuid    = 126;
    uint16 constant SYS_setregid    = 127;
    uint16 constant SYS_setsid      = 147;
    uint16 constant SYS_setgid      = 181;
    uint16 constant SYS_setegid     = 182;
    uint16 constant SYS_seteuid     = 183;

    uint16 constant SYS_setresuid   = 311;
    uint16 constant SYS_setresgid   = 312;
    uint16 constant SYS_getresuid   = 360;
    uint16 constant SYS_getresgid   = 361;

    using libucred for s_thread;
//    using libucred for s_proc;
    using libshellenv for shell_env;

    function main(shell_env e_in, s_proc p_in) external pure returns (shell_env e, s_proc p) {
        e = e_in;
        p = p_in;
        s_ucred[] ucs;
        for (string line: e.environ[sh.SIGNAL]) {
            (, string name, string value) = vars.split_var_record(line);
            uint16 num = str.toi(name);
            string[] args;
            if (!value.empty())
                (args, ) = libstring.split(value, ' ');
            e.puts("Syscall [ucred] " + name + " args: " + value);
            s_sigqueue siq;
	        uint16 code;
	        uint16 original_code;
	        s_sysent callp;
	        uint16[8] scargs;
            s_syscall_args sargs = s_syscall_args(code, original_code, callp, scargs);
            s_thread t = s_thread(p, p.p_pid + 1, siq, 0, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libproc.syscall_name(num), 0, 0, sargs, td_states.TDS_RUNNING, 0);            
//            s_thread t;// = s_thread(p, p.p_pid + 1, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libucred.syscall_name(num), 0, td_states.TDS_RUNNING, 0);
            t.do_syscall(num, args);
            (uint8 ec, uint32 rv, s_ucred nc) = (t.td_errno, t.td_retval, t.td_ucred);
            e.puts("Syscall [ucred] " + name + " ec: " + str.toa(ec) + " result: " + str.toa(rv));
            if (ec == 0) {
                p = t.td_proc;
            } else {
                e.set_err(ec, "Syscall" + name);
            }
            ucs.push(nc);
        }
        e.puts(_print_ucred(ucs));
    }

    function print_ucred(s_ucred[] ucs) external pure returns (string) {
        return _print_ucred(ucs);
    }
    function _print_ucred(s_ucred[] ucs) internal pure returns (string) {
        string[][] table = [["users", "uid", "ruid", "svuid", "ngroups", "rgid", "svgid", "loginclass", "flags", "groups"]];
        for (s_ucred cr: ucs) {
            (uint16 cr_users, uint16 cr_uid, uint16 cr_ruid, uint16 cr_svuid, uint8 cr_ngroups, uint16 cr_rgid, uint16 cr_svgid, string cr_loginclass, uint16 cr_flags, uint16[] cr_groups) = cr.unpack();
            string grps;
            for (uint16 g: cr_groups)
                grps.append(str.toa(g) + " ");
            table.push([str.toa(cr_users), str.toa(cr_uid), str.toa(cr_ruid), str.toa(cr_svuid), str.toa(cr_ngroups), str.toa(cr_rgid), str.toa(cr_svgid), cr_loginclass, str.toa(cr_flags), grps]);
        }
        return libtable.format_rows(table, [uint(4), 5, 5, 5, 2, 5, 5, 5, 20, 10, 40], libtable.CENTER);
    }

}