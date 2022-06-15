pragma ton-solidity >= 0.61.0;

import "stypes.sol";
//import "../kern/ucred.sol";

library sucred {

//    using ucred for s_ucred;

    uint16 constant SYS_setuid              = 23;
    uint16 constant SYS_getuid              = 24;
    uint16 constant SYS_geteuid             = 25;
    uint16 constant SYS_getegid             = 43;
    uint16 constant SYS_getgid              = 47;
    uint16 constant SYS_getresuid           = 360;
    uint16 constant SYS_getresgid           = 361;
    uint16 constant SYS_setgid              = 181;
    uint16 constant SYS_setegid             = 182;
    uint16 constant SYS_seteuid             = 183;

  /*  uint16 cr_ref;              // (c) reference count
    uint16 cr_users;            // (c) proc + thread using this cred
    uint16 cr_uid;              // effective user id
    uint16 cr_ruid;             // real user id
    uint16 cr_svuid;            // saved user id
    uint8 cr_ngroups;           // number of groups
    uint16 cr_rgid;             // real group id
    uint16 cr_svgid;            // saved group id
    s_loginclass cr_loginclass; // login class
    uint16 cr_flags;            // credential flags
    uint16[] cr_groups;         // groups*/

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
            return errno.EPERM;
    }
    function seteuid(s_ucred cr, uint16 euid) internal returns (uint8) {
        cr.cr_uid = euid;
    }

    function setgid(s_ucred cr, uint16 gid) internal returns (uint8) {
        cr.cr_svgid = cr.cr_rgid;
        cr.cr_rgid = gid;
    }

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
                ngroups = errno.EINVAL;
            else
            gidset = cr.cr_groups;
            ngroups = cr.cr_ngroups;
        }
    }

    function setgroups(s_ucred cr, uint8 ngroups, uint16[] gidset) internal returns (uint8 e) {
        if (ngroups > param.NGROUPS)
            return errno.EINVAL;
        if (cr.cr_uid > 0)
            return errno.EPERM;
        cr.cr_groups = gidset;
        cr.cr_ngroups = ngroups;
    }

    function issetugid(s_ucred cr) internal returns (uint16) {}

}
