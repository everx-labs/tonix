pragma ton-solidity >= 0.62.0;

import "proc_h.sol";
import "libstring.sol";
struct s_xsession {
    uint16 s_count;      // Ref cnt; pgrps in session - atomic.
    s_proc s_leader;     // Session leader.
    uint16 k_ttyp;        // Controlling tty.
    uint16 s_sid;        // Session ID.
    string s_login;      // Setlogin() name:
}
struct s_xpgrp {
    s_proc[] pg_members;   // Pointer to pgrp members.
    s_xsession pg_session;  // Pointer to session.
    uint16 pg_id;          // Process group id.
    uint16 pg_flags;       // PGRP_ flags
}

library libpgroup {

    function leader(s_xpgrp pg) internal returns (s_proc) {
        return pg.pg_session.s_leader;
    }

    function name(s_xpgrp pg) internal returns (string) {
        return pg.pg_session.s_login;
    }

    function as_row(s_session s) internal returns (string[]) {
        (uint16 s_count, uint16 s_leader, uint16 s_ttyvp, uint16 s_ttydp, uint16 s_ttyp, uint16 s_sid, string s_login) = s.unpack();
        return [str.toa(s_count), str.toa(s_leader), str.toa(s_ttyvp), str.toa(s_ttydp), str.toa(s_ttyp), str.toa(s_sid), s_login];
    }
    function print_session(s_session s) internal returns (string) {
        string[] header = ["count:", "leader:", "ttyvp:", "ttydp:", "ttyp:", "sid:", "login:"];
        string[] row = as_row(s);
        return (libstring.join_fields(header, '\t') + '\n' + libstring.join_fields(row, '\t'));
    }

    function bare_proc(uint16 ppid, uint16 pid, string comm) internal returns (s_proc p) {
        s_ucred p_ucred;
        s_xfiledesc p_fd;
        s_xpwddesc p_pd;
        s_plimit p_limit;
        uint32 p_flag;
 	    ksiginfo p_ksi;
	    s_sigqueue p_sigqueue;
        s_sysentvec p_sysent;
        s_pargs p_args;
        string[] environ;
        return s_proc(p_ucred, p_fd, p_pd, p_limit, p_flag, pid, p_ksi, p_sigqueue, ppid, comm, p_sysent, p_args, environ, 0, 0, ppid, 1, ppid);
    }
    function bare_pgroup() internal returns (s_pgrp pg) {
        s_proc[] pg_members;
        s_session pg_session;
        s_sigio[] srcs;
        uint16 pg_id;
        uint16 pg_flags;
        return s_pgrp(pg_members, pg_session, srcs, pg_id, pg_flags);
    }
    function bare_session(uint16 pid, string logname) internal returns (s_session s, s_pgrp pg, s_proc p) {
        p = bare_proc(pid, pid, "login");
        s = s_session(1, pid, 0, 0, 0, pid, logname);
        s_sigio srcs;
        pg = s_pgrp([p], s, [srcs], pid, 0);
    }
    function _print_session(s_session s) internal returns (string out) {
        out.append("COUNT\tPID\tTTYVP\tTTYDP\tTTYP\tSID\tLOGIN\n");
        (uint16 s_count, uint16 s_leader, uint16 k_ttyvp, uint16 k_ttydp, uint16 k_ttyp, uint16 s_sid, string s_login) = s.unpack();
            out.append(format("{}\t{}\t{}\t{}\t{}\t{}\t{}\n",
            str.toa(s_count), str.toa(s_leader), str.toa(k_ttyvp), str.toa(k_ttydp), str.toa(k_ttyp), str.toa(s_sid), s_login));
    }
    function print_pgroup(s_pgrp pg) internal returns (string out) {
        out.append("ID\tFLAGS\n");
        (s_proc[] pg_members, s_session pg_session, , uint16 pg_id, uint16 pg_flags) = pg.unpack();
        out.append(format("{}\t{}\n", str.toa(pg_id), str.toa(pg_flags)));
        out.append(_print_session(pg_session));
        out.append(_print_proc(pg_members));
    }
    function _print_proc(s_proc[] ps) internal returns (string out) {
        out.append("COMMAND\tPID\tPPID\tUSER\tFLAGS\tECOD\tESIG\tPGROUP\tN Thr\tLeader\n");
        for (s_proc p: ps) {
            (s_ucred p_ucred, , , , uint32 p_flag, uint16 p_pid, , ,
                uint16 p_oppid, string p_comm, , , , uint8 p_xexit, uint8 p_xsig, uint16 p_pgrp,
                uint16 p_numthreads, uint16 p_leader) = p.unpack();
            out.append(format("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n", p_comm, str.toa(p_pid), str.toa(p_oppid), str.toa(p_ucred.cr_uid),
                str.toa(p_flag), str.toa(p_xexit), str.toa(p_xsig), str.toa(p_pgrp), str.toa(p_numthreads), str.toa(p_leader)));
        }
    }

}