pragma ton-solidity >= 0.49.0;

struct FileSystem {
    string uuid;
    uint8 fs_type;
    SuperBlock sb;
    mapping (uint16 => INodeS) inodes;
}

struct Mount {
    FileSystem fs;
    DeviceInfo dev;
}

struct INodeS {
    uint16 mode;
    uint16 owner_id;
    uint16 group_id;
    uint32 file_size;
    uint16 n_links;
    uint32 accessed_at;
    uint32 modified_at;
    uint32 last_modified;
    string file_name;
    string text_data;
}

struct DeviceFreeBlocks {
    uint16 next_free;
    uint16 next_len;
    uint16 total_free;
}

struct DeviceInfo {
    uint8 device_type;
    uint16 id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
}

struct SuperBlock {
    bool file_system_state; // clean
    bool errors_behavior; // Continue
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
    uint32 lifetime_writes;
    uint16 first_inode;
    uint16 inode_size;
}

