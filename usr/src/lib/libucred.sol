pragma ton-solidity >= 0.64.0;

import "liberr.sol";
import "proc_h.sol";
import "libproc.sol";
import "str.sol";
import "param.sol";
import "priv.sol";
import "vars.sol";

library libucred {

    uint8 constant XU_NGROUPS = 16;

    using libucred for s_proc;
    using libucred for s_ucred;
    using libucred for s_thread;
    using vars for string[];

    uint16 constant SYS_getpid    = 20;
    uint16 constant SYS_setuid    = 23;
    uint16 constant SYS_getuid    = 24;
    uint16 constant SYS_geteuid   = 25;
    uint16 constant SYS_getppid   = 39;
    uint16 constant SYS_getegid   = 43;
    uint16 constant SYS_getgid    = 47;
    uint16 constant SYS_getgroups = 79;
    uint16 constant SYS_setgroups = 80;
    uint16 constant SYS_getpgrp   = 81;
    uint16 constant SYS_setpgid   = 82;
    uint16 constant SYS_setreuid  = 126;
    uint16 constant SYS_setregid  = 127;
    uint16 constant SYS_setsid    = 147;

    uint16 constant SYS_setgid    = 181;
    uint16 constant SYS_setegid   = 182;
    uint16 constant SYS_seteuid   = 183;

    uint16 constant SYS_getresuid = 360;
    uint16 constant SYS_getresgid = 361;

    function check_priv(s_ucred cred, uint16 ppriv) internal returns (uint8) {
        return priv.priv_check_cred(cred, ppriv);
    }

    function syscall_ids() internal returns (uint16[]) {
        return [SYS_getpid, SYS_setuid, SYS_getuid, SYS_geteuid, SYS_getegid, SYS_getgid, SYS_getresuid, SYS_getresgid, SYS_setgid, SYS_setegid, SYS_seteuid];
    }
    function syscall_name(uint16 number) internal returns (string) {
        return
        number == SYS_getpid ? "getpid" :
        number == SYS_setuid ? "setuid" :
        number == SYS_getuid ? "getuid" :
        number == SYS_geteuid ? "geteuid" :
        number == SYS_getegid ? "getegid" :
        number == SYS_getgid ? "getgid" :
        number == SYS_getresuid ? "getresuid" :
        number == SYS_getresgid ? "getresgid" :
        number == SYS_setgid ? "setgid" :
        number == SYS_setegid ? "setegid" :
        number == SYS_seteuid ? "seteuid" : "";
    }

    function syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS_getpid || n == SYS_getuid || n == SYS_geteuid || n == SYS_getegid || n == SYS_getgid || n == SYS_getresuid || n == SYS_getresgid)
            return 0;
        else if (n == SYS_setgid || n == SYS_setegid || n == SYS_seteuid || n == SYS_setuid)
            return 1;
    }

    function getuid(s_ucred cr) internal returns (uint16) {
        return cr.cr_ruid;
    }
    function geteuid(s_ucred cr) internal returns (uint16) {
        return cr.cr_uid;
    }
    function getgid(s_ucred cr) internal returns (uint16) {
        return cr.cr_rgid;
    }
    function getegid(s_ucred cr) internal returns (uint16) {
        return cr.cr_groups[0];
    }
    function setuid(s_ucred cr, uint16 uid) internal returns (uint8) {
        uint16 eu = cr.cr_uid;
        if (uid == eu || uid == cr.cr_ruid) {
            cr.cr_svuid = cr.cr_uid;
            cr.cr_uid = uid;
        } else
            return err.EPERM;
    }
    function seteuid(s_ucred cr, uint16 euid) internal returns (uint8) {
        cr.cr_uid = euid;
    }

    function setgid(s_ucred cr, uint16 gid) internal returns (uint8 ec) {
        ec = check_priv(cr, priv.PRIV_CRED_SETGID);
        if (ec == 0) {
            cr.cr_svgid = cr.cr_rgid;
            cr.cr_rgid = gid;
        }
    }

    /*uint16 constant PRIV_CRED_SETUID        = 50;  // setuid.
    uint16 constant PRIV_CRED_SETEUID       = 51;  // seteuid to !ruid and !svuid.
    uint16 constant PRIV_CRED_SETGID        = 52;  // setgid.
    uint16 constant PRIV_CRED_SETEGID       = 53;  // setgid to !rgid and !svgid.
    uint16 constant PRIV_CRED_SETGROUPS     = 54;  // Set process additional groups.
    uint16 constant PRIV_CRED_SETREUID      = 55;  // setreuid.
    uint16 constant PRIV_CRED_SETREGID      = 56;  // setregid.
    uint16 constant PRIV_CRED_SETRESUID     = 57;  // setresuid.
    uint16 constant PRIV_CRED_SETRESGID     = 58;  // setresgid.*/

    function setegid(s_ucred cr, uint16 gid) internal returns (uint8) {
        cr.cr_groups[0] = gid;
    }

    function setreuid(s_ucred cr, uint16 ruid, uint16 euid) internal returns (uint8) {
        cr.cr_svuid = cr.cr_ruid;
        cr.cr_ruid = ruid;
        cr.cr_uid = euid;
    }

    function setregid(s_ucred cr, uint16 rgid, uint16 egid) internal returns (uint8) {
        cr.cr_svgid = cr.cr_rgid;
        cr.cr_rgid = rgid;
        cr.cr_groups[0] = egid;
    }

    function getgroups(s_ucred cr, uint8 gidsetlen) internal returns (uint16[] gidset, uint8 ngroups) {
        if (gidsetlen == 0)
            ngroups = cr.cr_ngroups - 1;
        else {
            if (gidsetlen < ngroups)
                ngroups = err.EINVAL;
            else
            gidset = cr.cr_groups;
            ngroups = cr.cr_ngroups;
        }
    }

    function setgroups(s_ucred cr, uint8 ngroups, uint16[] gidset) internal returns (uint8 e) {
//        if (ngroups > param.NGROUPS)
//            return err.EINVAL;
        if (cr.cr_uid > 0)
            return err.EPERM;
        cr.cr_groups = gidset;
        cr.cr_ngroups = ngroups;
    }

    function issetugid(s_ucred cr) internal returns (uint16) {

    }

    function ucred_syscall(s_thread td, uint16 number, string[] args) internal {
        td.do_syscall(number, args);
    }
    function do_syscall(s_thread td, uint16 number, string[] args) internal {
        uint8 ec;
        uint n_args = args.length;
        string sarg1 = n_args > 0 ? args[0] : "";
        string sarg2 = n_args > 1 ? args[1] : "";
        uint16 arg1 = n_args > 0 ? str.toi(sarg1) : 0;
        uint16 arg2 = n_args > 1 ? str.toi(sarg2) : 0;
        s_ucred nc;
        if (number == SYS_getuid || number == SYS_geteuid || number == SYS_getgid || number == SYS_getegid || number == SYS_getpid ||
            number == SYS_getppid || number == SYS_getpgrp || number == SYS_setsid) {
            if (number == SYS_getpid)
                ec = td.sys_getpid();
            else if (number == SYS_getuid)
                ec = td.sys_getuid();
            else if (number == SYS_geteuid)
                ec = td.sys_geteuid();
            else if (number == SYS_getppid)
                ec = td.sys_getppid();
            else if (number == SYS_getegid)
                ec = td.sys_getegid();
            else if (number == SYS_getgid)
                ec = td.sys_getgid();
            else if (number == SYS_getpgrp)
                ec = td.sys_getpgrp();
            else if (number == SYS_setsid)
                ec = td.sys_setsid();
        } else if (number == SYS_setuid || number == SYS_seteuid || number == SYS_setgid || number == SYS_setegid) {
            if (number == SYS_setuid)
                ec = td.sys_setuid(arg1);
            else if (number == SYS_setgid)
                ec = td.sys_setgid(arg1);
            else if (number == SYS_setegid)
                ec = td.sys_setegid(arg1);
            else if (number == SYS_seteuid)
                ec = td.sys_seteuid(arg1);
            if (ec == 0)
                td.td_ucred = nc;
        } else if (number == SYS_setpgid || number == SYS_setreuid || number == SYS_setregid) {
            if (number == SYS_setpgid)
                ec = td.sys_setpgid(arg1, arg2);
            else if (number == SYS_setreuid)
                ec = td.sys_setreuid(arg1, arg2);
            else if (number == SYS_setregid)
                ec = td.sys_setregid(arg1, arg2);
            if (ec == 0)
                td.td_ucred = nc;
        } else
            ec = err.ENOSYS;
        td.td_errno = ec;
    }

    //function pgfind(uint16) internal returns (s_pgrp) {}            // Find process group by id.
    //function pfind(uint16) internal returns (s_proc) {}             // Find process by id.
    function inferior(s_proc p) internal returns (bool) {}
    function enterpgrp(s_proc p, uint16 pgid, s_pgrp pgrp, s_session sess) internal returns (uint8) {
    }

    function enterthispgrp(s_proc p, s_pgrp pgrp) internal returns (uint8) {}
    function p_cansee(s_thread td, s_proc p) internal returns (uint8) {}
    function copyout(uint16, uint16, uint16) internal returns (uint8) {}
    function sys_getpid(s_thread td) internal returns (uint8) {
        td.td_retval = td.td_proc.p_pid;
    }

    function sys_getppid(s_thread td) internal returns (uint8) {
        td.td_retval = kern_getppid(td);
    }

    function kern_getppid(s_thread td) internal returns (uint16) {
        return td.td_proc.p_oppid;
    }

    function sys_getpgrp(s_thread td) internal returns (uint8) {
        td.td_retval = td.td_proc.p_leader;//p.p_pgrp.pg_id;
    }

    // Get an arbitrary pid's process group id
    function sys_getpgid(s_thread td, uint16 pid) internal returns (uint8 error) {
        s_proc p;
        if (pid == 0) {
            p = td.td_proc;
        } else {
            p = pfind(pid);
            if (p.p_pid == 0)
                return err.ESRCH;
            error = p_cansee(td, p);
            if (error > 0)
                return error;
        }
        td.td_retval = p.p_leader;//p.p_pgrp.pg_id;
    }

    // Get an arbitrary pid's session id.
    function sys_getsid(s_thread td, uint16 pid) internal returns (uint8) {
        return kern_getsid(td, pid);
    }

    function kern_getsid(s_thread td, uint16 pid) internal returns (uint8 error) {
        s_proc p;
        if (pid == 0) {
            p = td.td_proc;
        } else {
 //         p = pfind(pid);
            if (p.p_pid == 0)
                return err.ESRCH;
            error = p_cansee(td, p);
            if (error > 0)
                return error;
        }
        //td.td_retval = p.p_session.s_sid;
    }

    function sys_getuid(s_thread td) internal returns (uint8) {
        td.td_retval = td.td_ucred.cr_ruid;
    }

    function sys_geteuid(s_thread td) internal returns (uint8)  {
        td.td_retval = td.td_ucred.cr_uid;
    }

    function sys_getgid(s_thread td) internal returns (uint8) {
        td.td_retval = td.td_ucred.cr_rgid;
    }

    // Get effective group ID.  The "egid" is groups[0], and could be obtained via getgroups.  This syscall exists because it is somewhat painful to do
    // correctly in a library function.
    function sys_getegid(s_thread td) internal returns (uint8) {
        td.td_retval = td.td_ucred.cr_groups[0];
    }

    struct getgroups_args {
        uint8 gidsetsize;
        uint16[] gidset;
    }
    function sys_getgroups(s_thread td, getgroups_args uap) internal returns (uint8 error) {
        s_ucred cred = td.td_ucred;
        uint8 ngrp = cred.cr_ngroups;
        if (uap.gidsetsize == 0)
            error = 0;
        else {
            if (uap.gidsetsize < ngrp)
                return err.EINVAL;
//          error = copyout(cred.cr_groups, uap.gidset, ngrp * 16);
        }
        td.td_retval = ngrp;
    }

    function sys_setsid(s_thread td) internal returns (uint8 error) {
        s_proc p = td.td_proc;
        s_pgrp pgrp = pgfind(p.p_pid);
        s_pgrp newpgrp;
        s_session newsess;
//       newpgrp = uma_zalloc(pgrp_zone, M_WAITOK);
//       newsess = malloc(sizeof(struct session), M_SESSION, M_WAITOK | M_ZERO);
        if (p.p_leader == p.p_pid || pgrp.pg_id != 0)
            error = err.EPERM;
        else {
            enterpgrp(p, p.p_pid, newpgrp, newsess);
            td.td_retval = p.p_pid;
            delete newpgrp;
            delete newsess;
        }
//      uma_zfree(pgrp_zone, newpgrp);
///    	free(newsess, M_SESSION);
    }

    // set process group (setpgid/old setpgrp) caller does setpgid(targpid, targpgid)
    // pid must be caller or child of caller (ESRCH) if a child
    //	pid must be in same session (EPERM) pid can't have done an exec (EACCES)
    // if pgid != pid there must exist some pid in same session having pgid (EPERM)
    // pid must not be session leader (EPERM)
    function sys_setpgid(s_thread td, uint16 pid, uint16 pgid) internal returns (uint8 error) {
        s_proc curp = td.td_proc;
        s_proc targp;	// target process
        s_pgrp pgrp;	// target pgrp
        s_pgrp newpgrp;
        s_session none;
//      s_pgrp no_pgrp;
        if (pgid < 0)
            return err.EINVAL;
//          newpgrp = uma_zalloc(pgrp_zone, M_WAITOK);
        if (pid > 0 && pid != curp.p_pid) {
                targp = pfind(pid);
                if (targp.p_pid == 0)
                    return err.ESRCH;
                if (!inferior(targp))
                    return err.ESRCH;
                error = p_cansee(td, targp);
//          	if (targp.p_leader == 0 || targp.p_session != curp.p_session)
//          	    return err.EPERM;
                if ((targp.p_flag & libproc.P_EXEC) > 0)
                    return err.EACCES;
        } else
            targp = curp;
//          if (SESS_LEADER(targp))
//              return err.EPERM;
            if (pgid == 0)
                pgid = targp.p_pid;
            pgrp = pgfind(pgid);
            if (pgrp.pg_id == 0) {
                if (pgid == targp.p_pid) {
                    error = enterpgrp(targp, pgid, newpgrp, none);
                    if (error == 0)
                        delete newpgrp;
                } else
                    return err.EPERM;
            } else {
//          if (pgrp == targp.p_pgrp) {
//              goto done;
//          }
                if (pgrp.pg_id != targp.p_pid) {
//                  && pgrp.pg_session != curp.p_session) {
                    return err.EPERM;
                }
                error = enterthispgrp(targp, pgrp);
            }
//      KASSERT((error == 0) || (newpgrp != NULL), ("setpgid failed and newpgrp is NULL"));
//      uma_zfree(pgrp_zone, newpgrp);
    }

    // Use the clause in B.4.2.2 that allows setuid/setgid to be 4.2/4.3BSD compatible.  It says that setting the uid/gid to euid/egid is a special
    // case of "appropriate privilege".  Once the rules are expanded out, this basically means that setuid(nnn) sets all three id's, in all permitted
    // cases unless _POSIX_SAVED_IDS is enabled.  In that case, setuid(getuid()) does not set the saved id - this is dangerous for traditional BSD
    // programs.  For this reason, we *really* do not want to set _POSIX_SAVED_IDS and do not want to clear POSIX_APPENDIX_B_4_2_2.
    function sys_setuid(s_thread td, uint16 uid) internal returns (uint8 error) {
        s_ucred newcred = crget();
        // Copy credentials so other references do not see our changes.
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        s_uidinfo uip = uifind(uid);
        // Notes on the logic.  We do things in three steps.
        // 1: We determine if the euid is going to change, and do EPERM right away.  We unconditionally change the euid later if this test is satisfied, simplifying that part of the logic.
        // 2: We determine if the real and/or saved uids are going to change.  Determined by compile options.
        // 3: Change euid last. (after tests in #2 for "appropriate privs")
        // allow setuid(getuid()), allow setuid(geteuid())
        if (uid != oldcred.cr_ruid && uid != oldcred.cr_uid && (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETUID)) > 0)
            return error;
        // Set the real uid and transfer proc count to new user.
        if (uid != oldcred.cr_ruid) {
            newcred.change_ruid(uip);
            td.setsugid();
        }
        // Set saved uid
        if (uid != oldcred.cr_svuid) {
            newcred.change_svuid(uid);
            td.setsugid();
        }
        // In all permitted cases, we are changing the euid.
        if (uid != oldcred.cr_uid) {
            newcred.change_euid(uip);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    function sys_seteuid(s_thread td, uint16 euid) internal returns (uint8 error) {
        s_ucred newcred = crget();
        s_uidinfo euip = uifind(euid);
        // Copy credentials so other references do not see our changes.
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        // allow seteuid(getuid()) allow seteuid(saved uid)
        if (euid != oldcred.cr_ruid && euid != oldcred.cr_svuid && (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETEUID)) > 0)
            return error;
        // Everything's okay, do it.
        if (oldcred.cr_uid != euid) {
            newcred.change_euid(euip);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    function sys_setgid(s_thread td, uint16 gid) internal returns (uint8 error) {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        // allow setgid(getgid()) allow setgid(getegid())
        if (gid != oldcred.cr_rgid && gid != oldcred.cr_groups[0] && (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETGID)) > 0)
            return error;
   	    // Set real gid
   	    if (oldcred.cr_rgid != gid) {
   	        newcred.change_rgid(gid);
   	        td.setsugid();
   	    }
   	    // Set saved gid
   	    if (oldcred.cr_svgid != gid) {
   	        newcred.change_svgid(gid);
   	        td.setsugid();
   	    }
        // In all cases permitted cases, we are changing the egid. Copy credentials so other references do not see our changes.
        if (oldcred.cr_groups[0] != gid) {
            newcred.change_egid(gid);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    function sys_setegid(s_thread td, uint16 egid) internal returns (uint8 error) {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        // allow setegid(getgid()), allow setegid(saved gid)
        if (egid != oldcred.cr_rgid && egid != oldcred.cr_svgid && (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETEGID)) > 0)
            return error;
        if (oldcred.cr_groups[0] != egid) {
            newcred.change_egid(egid);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    function sys_setgroups(s_thread td, uint8 gidsetsize, uint16[] gidset) internal returns (uint8 error) {
//        uint16[XU_NGROUPS] smallgroups;
        uint16[] groups;
        if (gidsetsize > XU_NGROUPS + 1 || gidsetsize < 0)
            return err.EINVAL;
//      if (gidsetsize > XU_NGROUPS)
            //groups = malloc(gidsetsize * sizeof(gid_t), M_TEMP, M_WAITOK);
//       else
//            groups = smallgroups;
        //error = copyin(gidset, groups, gidsetsize * 16);
        if (error == 0)
            error = kern_setgroups(td, gidsetsize, gidset);
        if (gidsetsize > XU_NGROUPS)
   	        delete groups;
    }

    function kern_setgroups(s_thread td, uint8 ngrp, uint16[] groups) internal returns (uint8 error) {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
//      MPASS(ngrp <= ngroups_max + 1);
//      crextend(newcred, ngrp);
        error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETGROUPS);
        if (error > 0)
            return error;
        if (ngrp == 0) {
            // setgroups(0, NULL) is a legitimate way of clearing the groups vector on non-BSD systems (which generally do not
            // have the egid in the groups[0]).  We risk security holes when running non-BSD software if we do not do the same.
            newcred.cr_ngroups = 1;
        } else {
//           crsetgroups(newcred, ngrp, groups);
            newcred.cr_ngroups = ngrp;
            newcred.cr_groups = groups;
        }
        td.setsugid();
        td.td_proc.p_ucred = newcred;
    }

    function sys_setreuid(s_thread td, uint16 ruid, uint16 euid) internal returns (uint8 error)  {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        s_uidinfo euip = uifind(euid);
        s_uidinfo ruip = uifind(ruid);
        if (((ruid > 0 && ruid != oldcred.cr_ruid && ruid != oldcred.cr_svuid) ||
             (euid > 0 && euid != oldcred.cr_uid && euid != oldcred.cr_ruid && euid != oldcred.cr_svuid)) &&
            (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETREUID)) > 0)
            return error;
        if (euid > 0 && oldcred.cr_uid != euid) {
            newcred.change_euid(euip);
            td.setsugid();
        }
        if (ruid > 0 && oldcred.cr_ruid != ruid) {
            newcred.change_ruid(ruip);
            td.setsugid();
        }
        if ((ruid > 0 || newcred.cr_uid != newcred.cr_ruid) &&
            newcred.cr_svuid != newcred.cr_uid) {
            newcred.change_svuid(newcred.cr_uid);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    function sys_setregid(s_thread td, uint16 rgid, uint16 egid) internal returns (uint8 error) {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        if (((rgid > 0 && rgid != oldcred.cr_rgid && rgid != oldcred.cr_svgid) ||
            (egid > 0 && egid != oldcred.cr_groups[0] && egid != oldcred.cr_rgid && egid != oldcred.cr_svgid)) &&
            (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETREGID)) > 0)
                return error;
            if (egid > 0 && oldcred.cr_groups[0] != egid) {
            newcred.change_egid(egid);
            td.setsugid();
        }
        if (rgid > 0 && oldcred.cr_rgid != rgid) {
            newcred.change_rgid(rgid);
            td.setsugid();
        }
        if ((rgid > 0 || newcred.cr_groups[0] != newcred.cr_rgid) && newcred.cr_svgid != newcred.cr_groups[0]) {
            newcred.change_svgid(newcred.cr_groups[0]);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    // setresuid(ruid, euid, suid) is like setreuid except control over the saved uid is explicit.
    function sys_setresuid(s_thread td, uint16 ruid, uint16 euid, uint16 suid) internal returns (uint8 error)  {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        s_uidinfo euip = uifind(euid);
        s_uidinfo ruip = uifind(ruid);
        if (((ruid > 0 && ruid != oldcred.cr_ruid && ruid != oldcred.cr_svuid && ruid != oldcred.cr_uid) ||
             (euid > 0 && euid != oldcred.cr_ruid && euid != oldcred.cr_svuid && euid != oldcred.cr_uid) ||
             (suid > 0 && suid != oldcred.cr_ruid && suid != oldcred.cr_svuid && suid != oldcred.cr_uid)) &&
            (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETRESUID)) > 0)
               	return error;
            if (euid > 0 && oldcred.cr_uid != euid) {
                newcred.change_euid(euip);
                td.setsugid();
            }
        if (ruid > 0 && oldcred.cr_ruid != ruid) {
            newcred.change_ruid(ruip);
            td.setsugid();
        }
        if (suid > 0 && oldcred.cr_svuid != suid) {
            newcred.change_svuid(suid);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    // setresgid(rgid, egid, sgid) is like setregid except control over the saved gid is explicit.
    function sys_setresgid(s_thread td, uint16 egid, uint16 rgid, uint16 sgid) internal returns (uint8 error) {
        s_ucred newcred = crget();
        s_ucred oldcred = newcred.crcopysafe(td.td_proc);
        if (((rgid > 0 && rgid != oldcred.cr_rgid && rgid != oldcred.cr_svgid && rgid != oldcred.cr_groups[0]) ||
             (egid > 0 && egid != oldcred.cr_rgid && egid != oldcred.cr_svgid && egid != oldcred.cr_groups[0]) ||
             (sgid > 0 && sgid != oldcred.cr_rgid && sgid != oldcred.cr_svgid && sgid != oldcred.cr_groups[0])) &&
            (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETRESGID)) > 0)
                return error;
            if (egid > 0 && oldcred.cr_groups[0] != egid) {
            newcred.change_egid(egid);
            td.setsugid();
        }
        if (rgid > 0 && oldcred.cr_rgid != rgid) {
            newcred.change_rgid(rgid);
            td.setsugid();
        }
        if (sgid > 0 && oldcred.cr_svgid != sgid) {
            newcred.change_svgid(sgid);
            td.setsugid();
        }
        td.td_proc.p_ucred = newcred;
    }

    struct getresuid_args {
        uint16 ruid;
        uint16 euid;
        uint16 suid;
    }
    function sys_getresuid(s_thread td, getresuid_args uap) internal returns (uint8) {
        s_ucred cred = td.td_ucred;
        uint8 error1;
        uint8 error2;
        uint8 error3;
        if (uap.ruid > 0)
            error1 = copyout(cred.cr_ruid, uap.ruid, 16);
        if (uap.euid > 0)
            error2 = copyout(cred.cr_uid,uap.euid, 16);
        if (uap.suid > 0)
            error3 = copyout(cred.cr_svuid, uap.suid, 16);
        return error1 > 0 ? error1 : error2 > 0 ? error2 : error3;
    }

    struct getresgid_args {
        uint16 rgid;
        uint16 egid;
        uint16 sgid;
    }
    function sys_getresgid(s_thread td, getresgid_args uap) internal returns (uint8) {
        s_ucred cred = td.td_ucred;
        uint8 error1;
        uint8 error2;
        uint8 error3;
        if (uap.rgid > 0)
            error1 = copyout(cred.cr_rgid, uap.rgid, 16);
        if (uap.egid > 0)
            error2 = copyout(cred.cr_groups[0], uap.egid, 16);
        if (uap.sgid > 0)
            error3 = copyout(cred.cr_svgid, uap.sgid, 16);
        return error1 > 0 ? error1 : error2 > 0 ? error2 : error3;
    }

    function sys_issetugid(s_thread td) internal returns (uint8) {
        td.td_retval = (td.td_proc.p_flag & libproc.P_SUGID) > 0 ? 1 : 0;
    }

    function sys___setugid(s_thread td, uint16 flag) internal returns (uint8) {
        if (flag == 0) {
            td.td_proc.p_flag &= ~libproc.P_SUGID;
            return 0;
        } else if (flag == 1) {
            td.td_proc.p_flag |= libproc.P_SUGID;
            return 0;
        }
        return err.EINVAL;
    }

    // Check if gid is a member of the group set.
    function groupmember(uint16 gid, s_ucred cred) internal returns (uint8) {
        uint16 l = 1;
        uint16 h = cred.cr_ngroups;
        uint16 m;
        if (cred.cr_groups[0] == gid)
            return 1;
        // If gid was not our primary group, perform a binary search of the supplemental groups.  This is possible because we sort the groups in crsetgroups().
        while (l < h) {
            m = l + ((h - l) / 2);
            if (cred.cr_groups[m] < gid)
                l = m + 1;
            else
                h = m;
        }
        if ((l < cred.cr_ngroups) && (cred.cr_groups[l] == gid))
            return 1;
        return 0;
    }

    function uifind(uint16 uid) internal returns (s_uidinfo ui) {
        ui.ui_uid = uid;
    }

    function crget() internal returns (s_ucred) {

    }
    function crcopy(s_ucred dest, s_ucred src) internal {
//	    KASSERT(dest.cr_ref == 1, ("crcopy of shared ucred"));
        dest = src;
//	    crsetgroups(dest, src.cr_ngroups, src.cr_groups);
    }

    function setsugid(s_thread t) internal {
        t.td_proc.p_flag |= libproc.P_SUGID;
    }

    // Change a process's effective uid. Side effects: newcred->cr_uid and newcred->cr_uidinfo will be modified.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_euid(s_ucred newcred, s_uidinfo euip) internal {
        newcred.cr_uid = euip.ui_uid;
        //newcred.cr_uidinfo = euip;
    }

    // Change a process's effective gid. Side effects: newcred->cr_gid will be modified.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_egid(s_ucred newcred, uint16 egid) internal {
        newcred.cr_groups[0] = egid;
    }

    // Change a process's real uid. Side effects: newcred->cr_ruid will be updated, newcred->cr_ruidinfo will be updated, and the old and new cr_ruidinfo proc counts will be updated.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_ruid(s_ucred newcred, s_uidinfo ruip) internal {
//      chgproccnt(newcred.cr_ruidinfo, -1, 0);
        newcred.cr_ruid = ruip.ui_uid;
        // /newcred.cr_ruidinfo = ruip;
//    	chgproccnt(newcred.cr_ruidinfo, 1, 0);
    }

    // Change a process's real gid. Side effects: newcred->cr_rgid will be updated.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_rgid(s_ucred newcred, uint16 rgid) internal {
        newcred.cr_rgid = rgid;
    }

    // Change a process's saved uid. Side effects: newcred->cr_svuid will be updated.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_svuid(s_ucred newcred, uint16 svuid) internal {
        newcred.cr_svuid = svuid;
    }

    // Change a process's saved gid. Side effects: newcred->cr_svgid will be updated.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_svgid(s_ucred newcred, uint16 svgid) internal {
        newcred.cr_svgid = svgid;
    }
    // Change process credentials. Callers are responsible for providing the reference for passed credentials and for freeing old ones.
    // Process has to be locked except when it does not have credentials (as it should not be visible just yet) or when newcred is NULL (as this can be
    // only used when the process is about to be freed, at which point it should not be visible anymore).
    function proc_set_cred(s_proc p, s_ucred newcred) internal {
//    	s_ucred cr = p.p_ucred;
//    	MPASS(cr != NULL);
//    	KASSERT(newcred.cr_users == 0, ("%s: users %d not 0 on cred %p", __func__, newcred.cr_users, newcred));
//    	KASSERT(cr.cr_users > 0, ("%s: users %d not > 0 on cred %p", __func__, cr.cr_users, cr));
//    	if (cr.cr_users > 0)
//        cr.cr_users--;
    	newcred.cr_users = 1;
    	p.p_ucred = newcred;
    }

    function proc_unset_cred(s_proc p) internal {
//    	s_ucred cr;
//    	MPASS(p.p_state == PRS_ZOMBIE || p.p_state == PRS_NEW);
//    	cr = p.p_ucred;
        delete p.p_ucred;
//    	KASSERT(cr.cr_users > 0, ("%s: users %d not > 0 on cred %p", __func__, cr.cr_users, cr));
//    	cr.cr_users--;
//    	if (cr.cr_users == 0)
//    	KASSERT(cr.cr_ref > 0, ("%s: ref %d not > 0 on cred %p", __func__, cr.cr_ref, cr));
    }

    function crcopysafe(s_ucred cr, s_proc p) internal returns (s_ucred oldcred) {
        oldcred = p.p_ucred;
        cr.crcopy(oldcred);
//    	int groups;
//    	while (cr.cr_agroups < oldcred.cr_agroups) {
//    	    groups = oldcred.cr_agroups;
 //   	    crextend(cr, groups);
//    	    oldcred = p.p_ucred;
//    	}
    }

    function curthread() internal returns (s_thread) {}

    function sigiofree(s_sigio sigio) internal {
    	crfree(sigio.sio_ucred);
//    	free(sigio, M_SIGIO);
    }
    function funsetown_locked(s_sigio sigio) internal returns (s_sigio) {
        if (sigio.sio_myref == 0)
            return sigio;
        sigio.sio_myref = 0;
        delete sigio.sio_myref;
        if (sigio.sio_pgid < 0) {
//            s_pgrp pg = pgfind(sigio.sio_pgrp);
//          SLIST_REMOVE(pg.pg_sigiolst, sigio, sigio, sio_pgsigio);
        } else {
//            s_proc p = pfind(sigio.sio_proc);
//          SLIST_REMOVE(p.p_sigiolst, sigio, sigio, sio_pgsigio);
        }
        return sigio;
    }
    // If sigio is on the list associated with a process or process group, disable signalling from the device, remove sigio from the list and free sigio.
    function funsetown(s_sigio sigiop) internal {
        // Racy check, consumers must provide synchronization.
        if (sigiop.sio_myref == 0)
            return;
        s_sigio sigio = funsetown_locked(sigiop);
        if (sigio.sio_myref > 0)
            sigiofree(sigio);
    }
    // This is common code for FIOSETOWN ioctl called by fcntl(fd, F_SETOWN, arg).
    // After permission checking, add a sigio structure to the sigio list for the process or process group.
    function fsetown(uint16 pgid, s_sigio sigiop) internal returns (uint8 ret) {
        s_proc proc;
        s_pgrp pgrp;
        s_sigio osigio;
           s_sigio sigio;
        if (pgid == 0) {
        	funsetown(sigiop);
        	return 0;
        }
//       	sigio = malloc(sizeof(struct sigio), M_SIGIO, M_WAITOK);
        sigio.sio_pgid = pgid;
        sigio.sio_ucred = crhold(curthread().td_ucred);
//        sigio.sio_myref = sigiop;
        ret = 0;
        if (pgid > 0) {
            //ret = pget(pgid, libproc.PGET_NOTWEXIT | libproc.PGET_NOTID | libproc.PGET_HOLD, proc);
            osigio = funsetown_locked(sigiop);
            if (ret == 0) {
//              _PRELE(proc);
                if ((proc.p_flag & libproc.P_WEXIT) != 0) {
                    ret = err.ESRCH;
//                } else if (proc.p_session != curthread.td_proc.p_session) {
                    // Policy - Don't allow a process to FSETOWN a process in another session.
                    // Remove this test to allow maximum flexibility or restrict FSETOWN to the current process or process group for maximum safety.
//                    ret = err.EPERM;
                } else {
                    sigio.sio_proc = proc.p_pid;
  //                SLIST_INSERT_HEAD(proc.p_sigiolst, sigio, sio_pgsigio);
                }
            }
        } else /* if (pgid < 0) */ {
            osigio = funsetown_locked(sigiop);
            pgrp = pgfind(-pgid);
            if (pgrp.pg_id == 0) {
                ret = err.ESRCH;
            } else {
//                if (pgrp.pg_session != curthread().td_proc.p_session) {
                    // Policy - Don't allow a process to FSETOWN a process in another session.
                    // Remove this test to allow maximum flexibility or restrict FSETOWN to the current process or process group for maximum safety.
//                    ret = err.EPERM;
//                } else {
                    sigio.sio_pgrp = pgrp.pg_id;
//              	SLIST_INSERT_HEAD(pgrp.pg_sigiolst, sigio, sio_pgsigio);
//                }
            }
        }
        if (ret == 0)
            sigiop = sigio;
        if (osigio.sio_myref > 0)
            sigiofree(osigio);
        return ret;
    }
    // This is common code for FIOGETOWN ioctl called by fcntl(fd, F_GETOWN, arg).
    function fgetown(s_sigio sigiop) internal returns (uint16 pgid) {
        pgid = (sigiop.sio_myref > 0) ? sigiop.sio_pgid : 0;
    }

    // Claim another reference to a ucred structure.
    function crhold(s_ucred cr) internal returns (s_ucred) {
//        s_thread td = curthread();
//        if (td.td_realucred == cr) {
//            KASSERT(cr.cr_users > 0, ("%s: users %d not > 0 on cred %p", cr.cr_users, cr));
//            td.td_ucredref++;
//            return cr;
//        }
//        cr.cr_ref++;
       return cr;
    }

    // Free a cred structure.  Throws away space when ref count gets to 0.
    function  crfree(s_ucred cr) internal {
//        s_thread td = curthread();
//        if (td.td_realucred == cr) {
//            KASSERT(cr.cr_users > 0, ("%s: users %d not > 0 on cred %p", cr.cr_users, cr));
//            td.td_ucredref--;
//            return;
//        }
//        KASSERT(cr.cr_users >= 0, ("%s: users %d not >= 0 on cred %p", cr.cr_users, cr));
//        cr.cr_ref--;
        if (cr.cr_users > 0) {
            return;
        }
//        KASSERT(cr.cr_ref >= 0, ("%s: ref %d not >= 0 on cred %p", cr.cr_ref, cr));
//        if (cr.cr_ref > 0) {
//            return;
//        }
//       crfree_final(cr);
    }

}

