pragma ton-solidity >= 0.55.0;

struct Inode {
    uint16 mode;
    uint16 owner_id;
    uint16 group_id;
    uint16 n_links;
    uint16 device_id;
    uint16 n_blocks;
    uint32 file_size;
    uint32 modified_at;
    uint32 last_modified;
    string file_name;
}

struct SuperBlock {
    bool file_system_state;
    bool errors_behavior;
    string file_system_OS_type;
    uint16 inode_count;
    uint16 block_count;
    uint16 free_inodes;
    uint16 free_blocks;
    uint16 block_size;
    uint32 created_at;
    uint32 last_mount_time;
    uint32 last_write_time;
    uint16 mount_count;
    uint16 max_mount_count;
    uint16 lifetime_writes;
    uint16 first_inode;
    uint16 inode_size;
}

struct SBS {
    uint16 inode_size;
    uint16 inode_count;
    uint16 free_inodes;
    uint16 first_inode;
    uint16 block_size;
    uint16 block_count;
    uint16 free_blocks;
    uint16 first_block;
    uint32 created_at;
    uint32 last_write_time;
    bytes32 file_system_OS_type;
}

struct DirEntry {
    uint8 file_type;
    string file_name;
    uint16 index;
}

struct FileS {
    uint16 mode;
    uint16 inode;
    uint16 state;
    uint16 bc;
    uint16 n_blk;
    uint32 pos;
    uint32 fize;
    string name;
}

/*struct ProcessInfo {
    uint16 owner_id;
    uint16 self_id;
    uint16 umask;
    mapping (uint16 => FileS) fd_table;
    string cwd;
}*/

struct UserInfo {
    uint16 gid;
    string user_name;
    string primary_group;
}

struct GroupInfo {
    string group_name;
    bool is_system;
}

struct Login {
    uint16 user_id;
    uint16 tty_id;
    uint16 process_id;
    uint32 login_time;
}

struct TTY {
    uint8 device_id;
    uint16 user_id;
    uint16 login_id;
}
