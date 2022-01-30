pragma ton-solidity >= 0.56.0;

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

struct DirEntry {
    uint8 file_type;
    string file_name;
    uint16 index;
}

struct Login {
    uint16 user_id;
    uint16 tty_id;
    uint16 process_id;
    uint32 login_time;
}

struct Ar {
    uint8 ar_type;
    uint8 file_type;
    uint16 index;
    uint16 dir_index;
    string path;
    string text;
}

struct DeviceInfo {
    uint8 major_id;
    uint8 minor_id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
    address device_address;
}
