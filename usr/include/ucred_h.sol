pragma ton-solidity >= 0.62.0;

struct s_uidinfo {
    uint16 ui_vmsize;  // pages of swap reservation by uid
    uint16 ui_sbsize;  // socket buffer space consumed
    uint16 ui_proccnt; // number of processes
    uint16 ui_ptscnt;  // number of pseudo-terminals
    uint16 ui_kqcnt;   // number of kqueues
    uint16 ui_umtxcnt; // number of shared umtxs
    uint16 ui_uid;     // uid
    uint16 ui_ref;     // reference count
}

struct s_ucred {
    uint16 cr_users;  // proc + thread using this cred
    uint16 cr_uid;    // effective user id
    uint16 cr_ruid;   // real user id
    uint16 cr_svuid;  // saved user id
    uint8 cr_ngroups; // number of groups
    uint16 cr_rgid;   // real group id
    uint16 cr_svgid;  // saved group id
    string cr_loginclass; // login class
    uint16 cr_flags;  // credential flags
    uint16[] cr_groups; // groups
}

struct s_xucred {
    uint16 cr_uid;       // effective user id
    uint8 cr_ngroups;    // number of groups
    uint16[] cr_groups;  // groups
    uint16 cr_pid;
}

library libucred {
    uint8 constant XU_NGROUPS = 16;
}