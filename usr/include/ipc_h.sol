pragma ton-solidity >= 0.64.0;

struct ipc_perm {
    uint16 cuid; // creator user id
    uint16 cgid; // creator group id
    uint16 uid;	 // user id
    uint16 gid;	 // group id
    uint16 mode; // r/w permission
    uint16 seq;	 // sequence # (to generate unique ipcid)
    uint16 key;	 // user specified msg/sem/shm key
}
