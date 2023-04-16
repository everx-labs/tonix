pragma ton-solidity >= 0.67.0;
struct ucred {
    uint16 cr_ref;        // reference count
    uint16 cr_users;      // proc + thread using this cred
    uint16 cr_uid;        // effective user id
    uint16 cr_ruid;       // real user id
    uint16 cr_svuid;      // saved user id
    uint8 cr_ngroups;     // number of groups
    uint16 cr_rgid;       // real group id
    uint16 cr_svgid;      // saved group id
    uint16 cr_loginclass; // login class // loginclass
    uint16 cr_flags;      // credential flags
    uint16[] cr_groups;   // groups
    uint8 cr_agroups;     // Available groups
}
struct loginclass {
    string lc_name;
    uint16 lc_refcount;
    uint16 lc_racct;
}
