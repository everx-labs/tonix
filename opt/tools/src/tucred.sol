pragma ton-solidity >= 0.62.0;

import "ucred_h.sol";
import "proc_h.sol";
import "str.sol";
import "libtable.sol";
import "Base.sol";
contract tucred is Base {
    s_ucred[] _creds;

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
    function groupmember(uint16 gid, s_ucred cred) internal pure returns (uint8) {
    	uint16 l;
    	uint16 h;
    	uint16 m;
    	if (cred.cr_groups[0] == gid)
    		return 1;
    	// If gid was not our primary group, perform a binary search of the supplemental groups.
        // This is possible because we sort the groups in crsetgroups().
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

    /*function crget() internal returns (s_ucred) {
    }
    function crcopy(s_ucred dest, s_ucred src) internal {
//	KASSERT(dest->cr_ref == 1, ("crcopy of shared ucred"));
        dest = src;
//	    crsetgroups(dest, src.cr_ngroups, src.cr_groups);
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

    // Change a process's real uid. Side effects: newcred->cr_ruid will be updated, newcred->cr_ruidinfo
    // will be updated, and the old and new cr_ruidinfo proc counts will be updated.
    // References: newcred must be an exclusive credential reference for the duration of the call.
    function change_ruid(s_ucred newcred, s_uidinfo ruip) internal {
//    	chgproccnt(newcred.cr_ruidinfo, -1, 0);
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
    }*/
}