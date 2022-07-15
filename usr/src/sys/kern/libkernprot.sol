pragma ton-solidity >= 0.62.0;

import "ucred.sol";
import "priv.sol";

struct s_pgrp {
    uint16[] pg_members; // Pointer to pgrp members.
    uint16 pg_session;   // Pointer to session.
    uint16 pg_id;        // Process group id.
    uint16 pg_flags;     // PGRP_ flags
}

struct s_session {
    uint16 s_count;      // Ref cnt; pgrps in session - atomic.
    uint16 s_leader;     // Session leader.
    uint16 k_ttyvp;     // Vnode of controlling tty.
//    k_cdev_priv k_ttydp; // Device of controlling tty.
    uint16 k_ttydp; // Device of controlling tty.
    uint16 k_ttyp;        // Controlling tty.
//    k_tty k_ttyp;        // Controlling tty.
    uint16 s_sid;        // Session ID.
    string s_login;      // Setlogin() name:
}


library libkernprot {
    uint32 constant P_ADVLOCK          = 0x00000001; // Process may hold a POSIX advisory lock.
    uint32 constant P_CONTROLT         = 0x00000002; // Has a controlling terminal.
    uint32 constant P_KPROC            = 0x00000004; // Kernel process.
    uint32 constant P_UNUSED3          = 0x00000008; // --available--
    uint32 constant P_PPWAIT           = 0x00000010; // Parent is waiting for child to exec/exit.
    uint32 constant P_PROFIL           = 0x00000020; // Has started profiling.
    uint32 constant P_STOPPROF         = 0x00000040; // Has thread requesting to stop profiling.
    uint32 constant P_HADTHREADS       = 0x00000080; // Has had threads (no cleanup shortcuts)
    uint32 constant P_SUGID            = 0x00000100; // Had set id privileges since last exec.
    uint32 constant P_SYSTEM           = 0x00000200; // System proc: no sigs, stats or swapping.
    uint32 constant P_SINGLE_EXIT      = 0x00000400; // Threads suspending should exit, not wait.
    uint32 constant P_TRACED           = 0x00000800; // Debugged process being traced.
    uint32 constant P_WAITED           = 0x00001000; // Someone is waiting for us.
    uint32 constant P_WEXIT            = 0x00002000; // Working on exiting.
    uint32 constant P_EXEC             = 0x00004000; // Process called exec.
    uint32 constant P_WKILLED          = 0x00008000; // Killed, go to kernel/user boundary ASAP.
    uint32 constant P_CONTINUED        = 0x00010000; // Proc has continued from a stopped state.
    uint32 constant P_STOPPED_SIG      = 0x00020000; // Stopped due to SIGSTOP/SIGTSTP.
    uint32 constant P_STOPPED_TRACE    = 0x00040000; // Stopped because of tracing.
    uint32 constant P_STOPPED_SINGLE   = 0x00080000; // Only 1 thread can continue (not to user).
    uint32 constant P_PROTECTED        = 0x00100000; // Do not kill on memory overcommit.
    uint32 constant P_SIGEVENT         = 0x00200000; // Process pending signals changed.
    uint32 constant P_SINGLE_BOUNDARY  = 0x00400000; // Threads should suspend at user boundary.
    uint32 constant P_HWPMC            = 0x00800000; // Process is using HWPMCs
    uint32 constant P_JAILED           = 0x01000000; // Process is in jail.
    uint32 constant P_TOTAL_STOP       = 0x02000000; // Stopped in stop_all_proc.
    uint32 constant P_INEXEC           = 0x04000000; // Process is in execve().
    uint32 constant P_STATCHILD        = 0x08000000; // Child process stopped or exited.
    uint32 constant P_INMEM            = 0x10000000; // Loaded into memory.
    uint32 constant P_SWAPPINGOUT      = 0x20000000; // Process is being swapped out.
    uint32 constant P_SWAPPINGIN       = 0x40000000; // Process is being swapped in.
    uint32 constant P_PPTRACE          = 0x80000000; // PT_TRACEME by vforked child.

    uint32 constant P_STOPPED = (P_STOPPED_SIG|P_STOPPED_SINGLE|P_STOPPED_TRACE);
    uint8 constant XU_NGROUPS = 16;

    function pgfind(uint16) internal returns (s_pgrp) {}            // Find process group by id.
    function pfind(uint16) internal returns (s_proc) {}             // Find process by id.
    function inferior(s_proc p) internal returns (bool) {}
    function enterpgrp(s_proc p, uint16 pgid, s_pgrp pgrp, s_session sess) internal returns (uint8) {
    }

    function enterthispgrp(s_proc p, s_pgrp pgrp) internal returns (uint8) {}
    function p_cansee(s_thread td, s_proc p) internal returns (uint8) {}
    function copyout(uint16, uint16, uint16) internal returns (uint8) {}
    function sys_getpid(s_thread td) internal returns (uint8) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	td.td_retval = p.p_pid;
    	return 0;
    }

    function sys_getppid(s_thread td) internal returns (uint8) {
    	td.td_retval = kern_getppid(td);
    	return 0;
    }

    function kern_getppid(s_thread td) internal returns (uint16) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	return p.p_oppid;
    }

    function sys_getpgrp(s_thread td) internal returns (uint8) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	td.td_retval = p.p_leader;//p.p_pgrp.pg_id;
    	return 0;
    }

    /* Get an arbitrary pid's process group id */
    function sys_getpgid(s_thread td, uint16 pid) internal returns (uint8 error) {
    	s_proc p;
    	if (pid == 0) {
//    		p = td.td_proc;
    	    p = pfind(td.td_proc);
    	} else {
    		p = pfind(pid);
    		if (p.p_pid == 0)
    			return err.ESRCH;
    		error = p_cansee(td, p);
    		if (error > 0) {
    			return error;
    		}
    	}
    	td.td_retval = p.p_leader;//p.p_pgrp.pg_id;
    	return 0;
    }

    /*
     * Get an arbitrary pid's session id.
     */
    function sys_getsid(s_thread td, uint16 pid) internal returns (uint8) {
    	return kern_getsid(td, pid);
    }

    function kern_getsid(s_thread td, uint16 pid) internal returns (uint8 error) {
    	s_proc p;
    	if (pid == 0) {
//    		p = td.td_proc;
    	    p = pfind(td.td_proc);
    	} else {
    		p = pfind(pid);
    		if (p.p_pid == 0)
    			return err.ESRCH;
    		error = p_cansee(td, p);
    		if (error > 0) {
    			return error;
    		}
    	}
    	//td.td_retval = p.p_session.s_sid;
    	return 0;
    }

    function sys_getuid(s_thread td) internal returns (uint8) {
    	td.td_retval = td.td_ucred.cr_ruid;
    	return 0;
    }

    function sys_geteuid(s_thread td) internal returns (uint8)  {
    	td.td_retval = td.td_ucred.cr_uid;
    	return 0;
    }

    function sys_getgid(s_thread td) internal returns (uint8) {
    	td.td_retval = td.td_ucred.cr_rgid;
    	return 0;
    }

    /*
     * Get effective group ID.  The "egid" is groups[0], and could be obtained
     * via getgroups.  This syscall exists because it is somewhat painful to do
     * correctly in a library function.
     */
    function sys_getegid(s_thread td) internal returns (uint8) {
    	td.td_retval = td.td_ucred.cr_groups[0];
    	return 0;
    }

    struct getgroups_args {
    	uint8	gidsetsize;
    	uint16[] gidset;
    }
    function sys_getgroups(s_thread td, getgroups_args uap) internal returns (uint8 error) {
    	s_ucred cred;
    	uint8 ngrp;
    	cred = td.td_ucred;
    	ngrp = cred.cr_ngroups;
    	if (uap.gidsetsize == 0) {
    		error = 0;
    	} else {
            if (uap.gidsetsize < ngrp)
    		    return err.EINVAL;
//    	    error = copyout(cred.cr_groups, uap.gidset, ngrp * 16);
        }
    	td.td_retval = ngrp;
    	return error;
    }

    function sys_setsid(s_thread td) internal returns (uint8 error) {
    	s_pgrp pgrp;
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_pgrp newpgrp;
    	s_session newsess;
    	error = 0;
//    	newpgrp = uma_zalloc(pgrp_zone, M_WAITOK);
//    	newsess = malloc(sizeof(struct session), M_SESSION, M_WAITOK | M_ZERO);
        pgrp = pgfind(p.p_pid);
    	if (p.p_leader == p.p_pid || pgrp.pg_id != 0) {
    		error = err.EPERM;
    	} else {
    		enterpgrp(p, p.p_pid, newpgrp, newsess);
    		td.td_retval = p.p_pid;
    		delete newpgrp;
    		delete newsess;
    	}
//    	uma_zfree(pgrp_zone, newpgrp);
///    	free(newsess, M_SESSION);
    	return error;
    }

    /*
     * set process group (setpgid/old setpgrp)
     *
     * caller does setpgid(targpid, targpgid)
     *
     * pid must be caller or child of caller (ESRCH)
     * if a child
     *	pid must be in same session (EPERM)
     *	pid can't have done an exec (EACCES)
     * if pgid != pid
     * 	there must exist some pid in same session having pgid (EPERM)
     * pid must not be session leader (EPERM)
     */
    function sys_setpgid(s_thread td, uint16 pid, uint16 pgid) internal returns (uint8 error) {
//    	s_proc curp = td.td_proc;
    	s_proc curp = pfind(td.td_proc);
    	s_proc targp;	/* target process */
    	s_pgrp pgrp;	/* target pgrp */
    	s_pgrp newpgrp;
        s_session none;
//        s_pgrp no_pgrp;
    	if (pgid < 0)
    		return err.EINVAL;
    	error = 0;
//    	newpgrp = uma_zalloc(pgrp_zone, M_WAITOK);
    	if (pid != 0 && pid != curp.p_pid) {
            targp = pfind(pid);
    		if (targp.p_pid == 0) {
    			error = err.ESRCH;
//    			goto done;
    		}
    		if (!inferior(targp)) {
    			error = err.ESRCH;
//    			goto done;
    		}
    		if ((error = p_cansee(td, targp)) > 0) {
//    			goto done;
    		}
//    		if (targp.p_leader == 0 || targp.p_session != curp.p_session) {
//    			error = err.EPERM;
//    			goto done;
//    		}
    		if ((targp.p_flag & P_EXEC) > 0) {
    			error = err.EACCES;
//    			goto done;
    		}
    	} else
    		targp = curp;
//    	if (SESS_LEADER(targp)) {
//    		error = err.EPERM;
//    		goto done;
//    	}
    	if (pgid == 0)
    		pgid = targp.p_pid;
        pgrp = pgfind(pgid);
    	if (pgrp.pg_id == 0) {
    		if (pgid == targp.p_pid) {
    			error = enterpgrp(targp, pgid, newpgrp, none);
    			if (error == 0)
    				delete newpgrp;
    		} else
    			error = err.EPERM;
    	} else {
//    		if (pgrp == targp.p_pgrp) {
//    			goto done;
//    		}
    		if (pgrp.pg_id != targp.p_pid) {
//    		    && pgrp.pg_session != curp.p_session) {
    			error = err.EPERM;
//    			goto done;
    		}
    		error = enterthispgrp(targp, pgrp);
    	}
//    done:
//    	KASSERT((error == 0) || (newpgrp != NULL), ("setpgid failed and newpgrp is NULL"));
//    	uma_zfree(pgrp_zone, newpgrp);
    	return error;
    }

    /*
     * Use the clause in B.4.2.2 that allows setuid/setgid to be 4.2/4.3BSD
     * compatible.  It says that setting the uid/gid to euid/egid is a special
     * case of "appropriate privilege".  Once the rules are expanded out, this
     * basically means that setuid(nnn) sets all three id's, in all permitted
     * cases unless _POSIX_SAVED_IDS is enabled.  In that case, setuid(getuid())
     * does not set the saved id - this is dangerous for traditional BSD
     * programs.  For this reason, we *really* do not want to set
     * _POSIX_SAVED_IDS and do not want to clear POSIX_APPENDIX_B_4_2_2.
     */
    function sys_setuid(s_thread td, uint16 uid) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
    	s_uidinfo uip;
//    	AUDIT_ARG_UID(uid);
    	newcred = crget();
    	uip = uifind(uid);
    	/*
    	 * Copy credentials so other references do not see our changes.
    	 */
    	oldcred = crcopysafe(p, newcred);
        /*
    	 * See if we have "permission" by POSIX 1003.1 rules.
    	 *
    	 * Note that setuid(geteuid()) is a special case of
    	 * "appropriate privileges" in appendix B.4.2.2.  We need
    	 * to use this clause to be compatible with traditional BSD
    	 * semantics.  Basically, it means that "setuid(xx)" sets all
    	 * three id's (assuming you have privs).
    	 *
    	 * Notes on the logic.  We do things in three steps.
    	 * 1: We determine if the euid is going to change, and do EPERM
    	 *    right away.  We unconditionally change the euid later if this
    	 *    test is satisfied, simplifying that part of the logic.
    	 * 2: We determine if the real and/or saved uids are going to
    	 *    change.  Determined by compile options.
    	 * 3: Change euid last. (after tests in #2 for "appropriate privs")
    	 */
    	if (uid != oldcred.cr_ruid &&		/* allow setuid(getuid()) */
    	    uid != oldcred.cr_uid &&		/* allow setuid(geteuid()) */
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETUID)) != 0) {
    	        return error;
            }
    	{
    		/*
    		 * Set the real uid and transfer proc count to new user.
    		 */
    		if (uid != oldcred.cr_ruid) {
    			change_ruid(newcred, uip);
    			setsugid(p);
    		}
    		/*
    		 * Set saved uid
    		 *
    		 * XXX always set saved uid even if not _POSIX_SAVED_IDS, as
    		 * the security of seteuid() depends on it.  B.4.2.2 says it
    		 * is important that we should do this.
    		 */
    		if (uid != oldcred.cr_svuid) {
    			change_svuid(newcred, uid);
    			setsugid(p);
    		}
    	}
    	/*
    	 * In all permitted cases, we are changing the euid.
    	 */
    	if (uid != oldcred.cr_uid) {
    		change_euid(newcred, uip);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;
    }

    function sys_seteuid(s_thread td, uint16 euid) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
    	s_uidinfo euip;

//    	AUDIT_ARG_EUID(euid);
    	newcred = crget();
    	euip = uifind(euid);
    	/*
    	 * Copy credentials so other references do not see our changes.
    	 */
    	oldcred = crcopysafe(p, newcred);
        if (euid != oldcred.cr_ruid &&		/* allow seteuid(getuid()) */
    	    euid != oldcred.cr_svuid &&	/* allow seteuid(saved uid) */
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETEUID)) != 0) {
                return error;
            }
    	/*
    	 * Everything's okay, do it.
    	 */
    	if (oldcred.cr_uid != euid) {
    		change_euid(newcred, euip);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;

    }

    function sys_setgid(s_thread td, uint16 gid) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
//    	AUDIT_ARG_GID(gid);
    	newcred = crget();
    	oldcred = crcopysafe(p, newcred);
        /*
    	 * See if we have "permission" by POSIX 1003.1 rules.
    	 *
    	 * Note that setgid(getegid()) is a special case of
    	 * "appropriate privileges" in appendix B.4.2.2.  We need
    	 * to use this clause to be compatible with traditional BSD
    	 * semantics.  Basically, it means that "setgid(xx)" sets all
    	 * three id's (assuming you have privs).
    	 *
    	 * For notes on the logic here, see setuid() above.
    	 */
    	if (gid != oldcred.cr_rgid &&		/* allow setgid(getgid()) */
    	    gid != oldcred.cr_groups[0] && /* allow setgid(getegid()) */
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETGID)) != 0)
                return error;

    		/*
    		 * Set real gid
    		 */
    		if (oldcred.cr_rgid != gid) {
    			change_rgid(newcred, gid);
    			setsugid(p);
    		}
    		/*
    		 * Set saved gid
    		 *
    		 * XXX always set saved gid even if not _POSIX_SAVED_IDS, as
    		 * the security of setegid() depends on it.  B.4.2.2 says it
    		 * is important that we should do this.
    		 */
    		if (oldcred.cr_svgid != gid) {
    			change_svgid(newcred, gid);
    			setsugid(p);
    		}
    	/*
    	 * In all cases permitted cases, we are changing the egid.
    	 * Copy credentials so other references do not see our changes.
    	 */
    	if (oldcred.cr_groups[0] != gid) {
    		change_egid(newcred, gid);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;
    }

    function sys_setegid(s_thread td, uint16 egid) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
//    	AUDIT_ARG_EGID(egid);
    	newcred = crget();
    	oldcred = crcopysafe(p, newcred);
        if (egid != oldcred.cr_rgid &&		/* allow setegid(getgid()) */
    	    egid != oldcred.cr_svgid &&	/* allow setegid(saved gid) */
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETEGID)) != 0)
        	return error;
       	if (oldcred.cr_groups[0] != egid) {
    		change_egid(newcred, egid);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;

    }

    function sys_setgroups(s_thread td, uint8 gidsetsize, uint16[] gidset) internal returns (uint8 error) {
    	uint16[XU_NGROUPS] smallgroups;
    	uint16[] groups;
    	if (gidsetsize > XU_NGROUPS + 1 || gidsetsize < 0)
    		return err.EINVAL;
//    	if (gidsetsize > XU_NGROUPS)
    		//groups = malloc(gidsetsize * sizeof(gid_t), M_TEMP, M_WAITOK);
//    	else
    		groups = smallgroups;
    	//error = copyin(gidset, groups, gidsetsize * 16);
    	if (error == 0)
    		error = kern_setgroups(td, gidsetsize, gidset);
    	if (gidsetsize > XU_NGROUPS)
//    		free(groups, M_TEMP);
    	return error;
    }

    function kern_setgroups(s_thread td, uint8 ngrp, uint16[] groups) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
//    	MPASS(ngrp <= ngroups_max + 1);
//    	AUDIT_ARG_GROUPSET(groups, ngrp);
    	newcred = crget();
//    	crextend(newcred, ngrp);
    	oldcred = crcopysafe(p, newcred);
    	error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETGROUPS);
    	if (error > 0) {
    	    return error;
        }
    	if (ngrp == 0) {
    		/*
    		 * setgroups(0, NULL) is a legitimate way of clearing the
    		 * groups vector on non-BSD systems (which generally do not
    		 * have the egid in the groups[0]).  We risk security holes
    		 * when running non-BSD software if we do not do the same.
    		 */
    		newcred.cr_ngroups = 1;
    	} else {
//    		crsetgroups(newcred, ngrp, groups);
            newcred.cr_ngroups = ngrp;
            newcred.cr_groups = groups;
    	}
    	setsugid(p);
    	proc_set_cred(p, newcred);
     	return 0;
    }

    function sys_setreuid(s_thread td, uint16 ruid, uint16 euid) internal returns (uint8 error)  {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
    	s_uidinfo euip;
        s_uidinfo ruip;
//    	AUDIT_ARG_EUID(euid);
//    	AUDIT_ARG_RUID(ruid);
    	newcred = crget();
    	euip = uifind(euid);
    	ruip = uifind(ruid);
    	oldcred = crcopysafe(p, newcred);
        if (((ruid != 0 && ruid != oldcred.cr_ruid &&
    	      ruid != oldcred.cr_svuid) ||
    	     (euid != 0 && euid != oldcred.cr_uid &&
    	      euid != oldcred.cr_ruid && euid != oldcred.cr_svuid)) &&
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETREUID)) != 0) {
    	    return error;
        }
    	if (euid != 0 && oldcred.cr_uid != euid) {
    		change_euid(newcred, euip);
    		setsugid(p);
    	}
    	if (ruid != 0 && oldcred.cr_ruid != ruid) {
    		change_ruid(newcred, ruip);
    		setsugid(p);
    	}
    	if ((ruid != 0 || newcred.cr_uid != newcred.cr_ruid) &&
    	    newcred.cr_svuid != newcred.cr_uid) {
    		change_svuid(newcred, newcred.cr_uid);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return (0);
    }

    function sys_setregid(s_thread td, uint16 rgid, uint16 egid) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
//    	AUDIT_ARG_EGID(egid);
//    	AUDIT_ARG_RGID(rgid);
    	newcred = crget();
    	oldcred = crcopysafe(p, newcred);
        if (((rgid != 0 && rgid != oldcred.cr_rgid &&
    	    rgid != oldcred.cr_svgid) ||
    	     (egid != 0 && egid != oldcred.cr_groups[0] &&
    	     egid != oldcred.cr_rgid && egid != oldcred.cr_svgid)) &&
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETREGID)) != 0) {
    	        return error;
            }

        	if (egid != 0 && oldcred.cr_groups[0] != egid) {
    		change_egid(newcred, egid);
    		setsugid(p);
    	}
    	if (rgid != 0 && oldcred.cr_rgid != rgid) {
    		change_rgid(newcred, rgid);
    		setsugid(p);
    	}
    	if ((rgid != 0 || newcred.cr_groups[0] != newcred.cr_rgid) &&
    	    newcred.cr_svgid != newcred.cr_groups[0]) {
    		change_svgid(newcred, newcred.cr_groups[0]);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;
    }

    /*
     * setresuid(ruid, euid, suid) is like setreuid except control over the saved
     * uid is explicit.
     */
    function sys_setresuid(s_thread td, uint16 ruid, uint16 euid, uint16 suid) internal returns (uint8 error)  {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
    	s_uidinfo euip;
        s_uidinfo ruip;
//    	AUDIT_ARG_EUID(euid);
//    	AUDIT_ARG_RUID(ruid);
//    	AUDIT_ARG_SUID(suid);
    	newcred = crget();
    	euip = uifind(euid);
    	ruip = uifind(ruid);
    	oldcred = crcopysafe(p, newcred);
        if (((ruid != 0 && ruid != oldcred.cr_ruid &&
    	     ruid != oldcred.cr_svuid &&
    	      ruid != oldcred.cr_uid) ||
    	     (euid != 0 && euid != oldcred.cr_ruid &&
    	    euid != oldcred.cr_svuid &&
    	      euid != oldcred.cr_uid) ||
    	     (suid != 0 && suid != oldcred.cr_ruid &&
    	    suid != oldcred.cr_svuid &&
    	      suid != oldcred.cr_uid)) &&
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETRESUID)) != 0) {
            	return error;
            }

    	if (euid != 0 && oldcred.cr_uid != euid) {
    		change_euid(newcred, euip);
    		setsugid(p);
    	}
    	if (ruid != 0 && oldcred.cr_ruid != ruid) {
    		change_ruid(newcred, ruip);
    		setsugid(p);
    	}
    	if (suid != 0 && oldcred.cr_svuid != suid) {
    		change_svuid(newcred, suid);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;
    }

    /*
     * setresgid(rgid, egid, sgid) is like setregid except control over the saved
     * gid is explicit.
     */
    function sys_setresgid(s_thread td, uint16 egid, uint16 rgid, uint16 sgid) internal returns (uint8 error) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	s_ucred newcred;
        s_ucred oldcred;
//    	AUDIT_ARG_EGID(egid);
//    	AUDIT_ARG_RGID(rgid);
//    	AUDIT_ARG_SGID(sgid);
    	newcred = crget();
    	oldcred = crcopysafe(p, newcred);
    	if (((rgid != 0 && rgid != oldcred.cr_rgid &&
    	      rgid != oldcred.cr_svgid &&
    	      rgid != oldcred.cr_groups[0]) ||
    	     (egid != 0 && egid != oldcred.cr_rgid &&
    	      egid != oldcred.cr_svgid &&
    	      egid != oldcred.cr_groups[0]) ||
    	     (sgid != 0 && sgid != oldcred.cr_rgid &&
    	      sgid != oldcred.cr_svgid &&
    	      sgid != oldcred.cr_groups[0])) &&
    	    (error = priv.priv_check_cred(oldcred, priv.PRIV_CRED_SETRESGID)) != 0) {
    	        return error;
            }

    	if (egid != 0 && oldcred.cr_groups[0] != egid) {
    		change_egid(newcred, egid);
    		setsugid(p);
    	}
    	if (rgid != 0 && oldcred.cr_rgid != rgid) {
    		change_rgid(newcred, rgid);
    		setsugid(p);
    	}
    	if (sgid != 0 && oldcred.cr_svgid != sgid) {
    		change_svgid(newcred, sgid);
    		setsugid(p);
    	}
    	proc_set_cred(p, newcred);
    	return 0;
    }

    struct getresuid_args {
    	uint16 ruid;
    	uint16 euid;
    	uint16 suid;
    }
    function sys_getresuid(s_thread td, getresuid_args uap) internal returns (uint8) {
    	s_ucred cred;
    	uint8 error1 = 0;
        uint8 error2 = 0;
        uint8 error3 = 0;
    	cred = td.td_ucred;
    	if (uap.ruid > 0)
    		error1 = copyout(cred.cr_ruid, uap.ruid, 16);
    	if (uap.euid > 0)
    		error2 = copyout(cred.cr_uid,uap.euid, 16);
    	if (uap.suid > 0)
    		error3 = copyout(cred.cr_svuid, uap.suid, 16);
    	return (error1 > 0 ? error1 : error2 > 0 ? error2 : error3);
    }

    struct getresgid_args {
    	uint16 rgid;
    	uint16 egid;
    	uint16 sgid;
    }
    function sys_getresgid(s_thread td, getresgid_args uap) internal returns (uint8) {
    	s_ucred cred;
    	uint8 error1 = 0;
        uint8 error2 = 0;
        uint8 error3 = 0;
    	cred = td.td_ucred;
    	if (uap.rgid > 0)
    		error1 = copyout(cred.cr_rgid, uap.rgid, 16);
    	if (uap.egid > 0)
    		error2 = copyout(cred.cr_groups[0], uap.egid, 16);
    	if (uap.sgid > 0)
    		error3 = copyout(cred.cr_svgid, uap.sgid, 16);
    	return (error1 > 0 ? error1 : error2 > 0 ? error2 : error3);
    }

    function sys_issetugid(s_thread td) internal returns (uint8) {
//    	s_proc p = td.td_proc;
    	s_proc p = pfind(td.td_proc);
    	/*
    	 * Note: OpenBSD sets a P_SUGIDEXEC flag set at execve() time,
    	 * we use P_SUGID because we consider changing the owners as
    	 * "tainting" as well.
    	 * This is significant for procs that start as root and "become"
    	 * a user without an exec - programs cannot know *everything*
    	 * that libc *might* have put in their data segment.
    	 */
    	td.td_retval = ((p.p_flag & P_SUGID) > 0) ? 1 : 0;
    	return 0;
    }

    function sys___setugid(s_thread td, uint16 flag) internal returns (uint8) {
//    #ifdef REGRESSION
    	s_proc p;
//    	p = td.td_proc;
    	p = pfind(td.td_proc);
    	if (flag == 0) {
    		p.p_flag &= ~P_SUGID;
    		return 0;
    	} else if (flag == 1) {
    		p.p_flag |= P_SUGID;
    		return 0;
        }
    		return err.EINVAL;
  //  #else /* !REGRESSION */
//    	return err.ENOSYS;
//    #endif /* REGRESSION */
    }

    /*
     * Check if gid is a member of the group set.
     */
    function groupmember(uint16 gid, s_ucred cred) internal returns (uint8) {
    	uint16 l;
    	uint16 h;
    	uint16 m;
    	if (cred.cr_groups[0] == gid)
    		return 1;
    	/*
    	 * If gid was not our primary group, perform a binary search
    	 * of the supplemental groups.  This is possible because we
    	 * sort the groups in crsetgroups().
    	 */
    	l = 1;
    	h = cred.cr_ngroups;
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

    function uifind(uint16 uid) internal returns (s_uidinfo) {}

    function crget() internal returns (s_ucred) {

    }
    function crcopy(s_ucred dest, s_ucred src) internal {
//	KASSERT(dest->cr_ref == 1, ("crcopy of shared ucred"));
        dest = src;
//	    crsetgroups(dest, src.cr_ngroups, src.cr_groups);
    }

    function setsugid(s_proc p) internal {
    	p.p_flag |= P_SUGID;
    }

    /*-
     * Change a process's effective uid.
     * Side effects: newcred->cr_uid and newcred->cr_uidinfo will be modified.
     * References: newcred must be an exclusive credential reference for the
     *             duration of the call.
     */
    function change_euid(s_ucred newcred, s_uidinfo euip) internal {
    	newcred.cr_uid = euip.ui_uid;
    	//newcred.cr_uidinfo = euip;
    }

    /*-
     * Change a process's effective gid.
     * Side effects: newcred->cr_gid will be modified.
     * References: newcred must be an exclusive credential reference for the
     *             duration of the call.
     */
    function change_egid(s_ucred newcred, uint16 egid) internal {
    	newcred.cr_groups[0] = egid;
    }

    /*-
     * Change a process's real uid.
     * Side effects: newcred->cr_ruid will be updated, newcred->cr_ruidinfo
     *               will be updated, and the old and new cr_ruidinfo proc
     *               counts will be updated.
     * References: newcred must be an exclusive credential reference for the
     *             duration of the call.
     */
    function change_ruid(s_ucred newcred, s_uidinfo ruip) internal {
//    	chgproccnt(newcred.cr_ruidinfo, -1, 0);
    	newcred.cr_ruid = ruip.ui_uid;
    	// /newcred.cr_ruidinfo = ruip;
//    	chgproccnt(newcred.cr_ruidinfo, 1, 0);
    }

    /*-
     * Change a process's real gid.
     * Side effects: newcred->cr_rgid will be updated.
     * References: newcred must be an exclusive credential reference for the
     *             duration of the call.
     */
    function change_rgid(s_ucred newcred, uint16 rgid) internal {
    	newcred.cr_rgid = rgid;
    }

    /*
     * Change a process's saved uid.
     * Side effects: newcred->cr_svuid will be updated.
     * References: newcred must be an exclusive credential reference for the
     *             duration of the call.
     */
    function change_svuid(s_ucred newcred, uint16 svuid) internal {
    	newcred.cr_svuid = svuid;
    }

    /*-
     * Change a process's saved gid.
     * Side effects: newcred->cr_svgid will be updated.
     * References: newcred must be an exclusive credential reference for the
     *             duration of the call.
     */
    function change_svgid(s_ucred newcred, uint16 svgid) internal {
    	newcred.cr_svgid = svgid;
    }
    /*
     * Change process credentials.
     * Callers are responsible for providing the reference for passed credentials
     * and for freeing old ones.
     *
     * Process has to be locked except when it does not have credentials (as it
     * should not be visible just yet) or when newcred is NULL (as this can be
     * only used when the process is about to be freed, at which point it should
     * not be visible anymore).
     */
    function proc_set_cred(s_proc p, s_ucred newcred) internal {
    	s_ucred cr;
    	cr = p.p_ucred;
//    	MPASS(cr != NULL);
//    	KASSERT(newcred->cr_users == 0, ("%s: users %d not 0 on cred %p", __func__, newcred->cr_users, newcred));
//    	KASSERT(cr->cr_users > 0, ("%s: users %d not > 0 on cred %p", __func__, cr->cr_users, cr));
    	cr.cr_users--;
    	p.p_ucred = newcred;
    	newcred.cr_users = 1;
    }

    function proc_unset_cred(s_proc p) internal {
    	s_ucred cr;
//    	MPASS(p->p_state == PRS_ZOMBIE || p->p_state == PRS_NEW);
    	cr = p.p_ucred;
    	delete p.p_ucred;
//    	KASSERT(cr->cr_users > 0, ("%s: users %d not > 0 on cred %p", __func__, cr->cr_users, cr));
    	cr.cr_users--;
//    	if (cr.cr_users == 0)
//    		KASSERT(cr->cr_ref > 0, ("%s: ref %d not > 0 on cred %p", __func__, cr->cr_ref, cr));
    }

    function crcopysafe(s_proc p, s_ucred cr) internal returns (s_ucred) {
    	s_ucred oldcred;
//    	int groups;
    	oldcred = p.p_ucred;
//    	while (cr.cr_agroups < oldcred.cr_agroups) {
//    		groups = oldcred.cr_agroups;
 //   		crextend(cr, groups);
    		oldcred = p.p_ucred;
//    	}
    	crcopy(cr, oldcred);
    	return oldcred;
    }

}