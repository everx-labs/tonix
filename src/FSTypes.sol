pragma ton-solidity >= 0.49.0;

struct INodeS {
    uint16 mode;
    uint16 owner_id;
    uint16 group_id;
    uint32 file_size;
    uint16 n_links;
    uint32 modified_at;
    uint32 last_modified;
    string file_name;
    string[] text_data;
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

struct FileSystem {
    string uuid;
    uint8 fs_type;
    SuperBlock sb;
    uint16 ic;
    mapping (uint16 => INodeS) inodes;
}

struct Mount {
    FileSystem fs;
    DeviceInfo dev;
    string path;
    uint16 options;
    uint16 target;
}

struct DeviceInfo {
    uint8 major_id;
    uint8 minor_id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
    address device_address;
}

struct FileMapS {
    uint16 storage_type;
    uint16 start;
    uint16 count;
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

struct ProcessInfo {
    uint16 owner_id;
    uint16 self_id;
    uint16 umask;
    mapping (uint16 => FileS) fd_table;
    string cwd;
}

struct UserInfo {
    uint16 uid;
    uint16 gid;
    string user_name;
    string primary_group;
    string home_directory;
}
