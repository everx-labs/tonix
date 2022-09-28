pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libproc.sol";
import "Base.sol";

contract subr_proc is Base {
    using libshellenv for shell_env;
    using libproc for s_thread;
    function main(shell_env e_in, s_pgrp pg_in) external pure returns (shell_env e, s_pgrp pg) {
        e = e_in;
        pg = pg_in;
        s_proc p = pg.pg_members[0];
        string[] sq = e.environ[sh.DIRECTORY];
        for (string line: sq) {
            (, string name, string value) = vars.split_var_record(line);
            uint16 num = str.toi(name);
            (string[] args, ) = libstring.split(value, ' ');
            e.puts("Syscall " + name + " args: " + value);
            s_sigqueue siq;
	        uint16 code;
	        uint16 original_code;
	        s_sysent callp;
	        uint16[8] scargs;
            s_syscall_args sargs = s_syscall_args(code, original_code, callp, scargs);
            s_thread t = s_thread(p, p.p_pid + 1, siq, 0, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libproc.syscall_name(num), 0, 0, sargs, td_states.TDS_RUNNING, 0);
            t.do_syscall(num, args);
            (uint8 ec, uint32 rv, s_of[] res) = (t.td_errno, t.td_retval, t.td_proc.p_fd.fdt_ofiles);
            e.puts("Syscall [proc] " + name + " ec: " + str.toa(ec) + " result: " + str.toa(rv));
            if (ec == 0) {
//                p.p_fd.fdt_ofiles = res;
//                p.p_fd.fdt_nfiles = uint16(res.length);
            }
        }
//        e.puts(_print_proc([pg.pg_members[0], p]));
        e.puts(_print_pgroup(pg));
    }

    function bare_proc() external pure returns (s_proc p) {
        s_ucred p_ucred;
        s_xfiledesc p_fd;
        s_xpwddesc p_pd;
        s_plimit p_limit;
        uint32 p_flag;
        uint16 p_pid;
 	    ksiginfo p_ksi;
	    s_sigqueue p_sigqueue;
        uint16 p_oppid;
        string p_comm;
        s_sysentvec p_sysent;
        s_pargs p_args;
        string[] environ;
        uint8 p_xexit;
	    uint8 p_xsig;
	    uint16 p_pgrp;
        uint16 p_numthreads;
        uint16 p_leader;
        return s_proc(p_ucred, p_fd, p_pd, p_limit, p_flag, p_pid, p_ksi, p_sigqueue, p_oppid, p_comm, p_sysent, p_args, environ, p_xexit, p_xsig, p_pgrp, p_numthreads, p_leader);
    }

    function bare_pgroup() external pure returns (s_pgrp pg) {
        s_proc[] pg_members;
        s_session pg_session;
        s_sigio[] pg_sigiolst;
        uint16 pg_id;
        uint16 pg_flags;
        return s_pgrp(pg_members, pg_session, pg_sigiolst, pg_id, pg_flags);
    }

    function bare_session() external pure returns (s_session s) {
        uint16 s_count;
        uint16 s_leader;
        uint16 k_ttyvp;
        uint16 k_ttydp;
        uint16 k_ttyp;
        uint16 s_sid;
        string s_login;
        return s_session(s_count, s_leader, k_ttyvp, k_ttydp, k_ttyp, s_sid, s_login);
    }

    function _print_session(s_session s) internal pure returns (string out) {
        out.append("COUNT\tPID\tTTYVP\tTTYDP\tTTYP\tSID\tLOGIN\n");
        (uint16 s_count, uint16 s_leader, uint16 k_ttyvp, uint16 k_ttydp, uint16 k_ttyp, uint16 s_sid, string s_login) = s.unpack();
            out.append(format("{}\t{}\t{}\t{}\t{}\t{}\t{}\n",
            str.toa(s_count), str.toa(s_leader), str.toa(k_ttyvp), str.toa(k_ttydp), str.toa(k_ttyp), str.toa(s_sid), s_login));
    }

    function _print_pgroup(s_pgrp pg) internal pure returns (string out) {
        out.append("ID\tFLAGS\n");
        (s_proc[] pg_members, s_session pg_session, s_sigio[] pg_sigiolst, uint16 pg_id, uint16 pg_flags) = pg.unpack();
        out.append(format("{}\t{}\n", str.toa(pg_id), str.toa(pg_flags)));
        out.append(_print_session(pg_session));
        out.append(_print_proc(pg_members));
    }

    function _print_proc(s_proc[] ps) internal pure returns (string out) {
        out.append("COMMAND\tPID\tPPID\tUSER\tFLAGS\tEXIT CODE\tEXIT SIG\tPGROUP\tN Threads\tLeader\n");
        for (s_proc p: ps) {
            (s_ucred p_ucred, s_xfiledesc p_fd, s_xpwddesc p_pd, s_plimit p_limit, uint32 p_flag, uint16 p_pid, ksiginfo p_ksi, s_sigqueue p_sigqueue,
                uint16 p_oppid, string p_comm, s_sysentvec p_sysent, s_pargs p_args, string[] environ, uint8 p_xexit, uint8 p_xsig, uint16 p_pgrp,
                uint16 p_numthreads, uint16 p_leader) = p.unpack();
            out.append(format("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n", p_comm, str.toa(p_pid), str.toa(p_oppid), str.toa(p_ucred.cr_uid),
                str.toa(p_flag), str.toa(p_xexit), str.toa(p_xsig), str.toa(p_pgrp), str.toa(p_numthreads), str.toa(p_leader)));
        }
    }
}