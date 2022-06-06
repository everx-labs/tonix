pragma ton-solidity >= 0.57.0;

import "fmt.sol";

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

struct DeviceInfo {
    uint8 major_id;
    uint8 minor_id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
    address device_address;
}

library sb {

    using libstring for string;

    uint16 constant ROOT_DIR = 11;

    uint16 constant DEF_BLOCK_SIZE = 100;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 60;
    uint16 constant MAX_BLOCKS = 4000;
    uint16 constant MAX_INODES = 600;

    uint16 constant SB          = 0;
    uint16 constant DEVICE_INFO = 1;
    uint16 constant SB_INFO     = 2;
    uint16 constant SB_INODES   = 3;
    uint16 constant SB_BLOCKS   = 4;
    uint16 constant SB_MOUNTS   = 5;
    uint16 constant SB_STATE    = 6;
    uint16 constant SB_INODES_TABLE = 7;
    uint16 constant SB_SB       = 8;
    uint16 constant SB_JOURNAL  = 9;
    uint16 constant SB_BACKUP   = 10;

    function get_inode_size(mapping (uint16 => Inode) inodes) internal returns (uint16) {
        return inodes[SB_INFO].n_links;
    }

    function get_inode_count(mapping (uint16 => Inode) inodes) internal returns (uint16) {
        return inodes[SB_INODES].owner_id + 1;
    }

    function claim_inodes_and_blocks(Inode inodes_inode, uint inode_count, uint block_count) internal returns (Inode) {
        uint16 i_count = uint16(inode_count);
        uint16 b_count = uint16(block_count);
        if (i_count > 0) {
            inodes_inode.owner_id += i_count;
            inodes_inode.modified_at = now;
        }
        if (b_count > 0) {
            inodes_inode.group_id += b_count;
            inodes_inode.last_modified = now;
        }
        inodes_inode.n_links++;
        return inodes_inode;
    }

    function get_block_size(mapping (uint16 => Inode) inodes) internal returns (uint16) {
        return inodes[SB_INFO].n_blocks;
    }

    function get_device_id(mapping (uint16 => Inode) inodes) internal returns (uint16) {
        return inodes[SB_INFO].device_id;
    }

    function get_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (SuperBlock) {
        Inode info_inode = inodes[SB_INFO];
        uint16[] sb_info = get_sb_data(data[SB_INFO]);
        uint16 total_inodes = info_inode.owner_id; //sb_info[1];
        uint16 total_blocks = info_inode.group_id; // sb_info[2];
        uint32 created_at = info_inode.modified_at;
        uint16 first_inode = 11;//ROOT_DIR;// = sb_info[0];
        uint16 inode_size = info_inode.n_links;
        uint16 block_size = info_inode.n_blocks;
        uint16 max_mount_count = 10;

        if (sb_info.length > 5) {
            first_inode = sb_info[0];
            max_mount_count = sb_info[5];
        }

        Inode inodes_inode = inodes[SB_INODES];
        uint16 inode_count = inodes_inode.owner_id;
        uint16 free_inodes = total_inodes - inode_count;
        uint32 last_write_time = inodes_inode.modified_at;
        uint16 lifetime_writes = inodes_inode.n_links;
        uint16 block_count = inodes_inode.group_id;
        uint16 free_blocks = total_blocks - block_count;

        Inode mounts_inode = inodes[SB_MOUNTS];
        uint16[] sb_mounts = get_sb_data(data[SB_MOUNTS]);
        uint16 mount_count = 0;
        if (!sb_mounts.empty())
            mount_count = sb_mounts[0];
        uint32 last_mount_time = mounts_inode.modified_at;

        (string[] sb_state, ) = get_sb_text(data[SB_STATE]);
        bool file_system_state = true;
        bool errors_behavior = true;
        string file_system_OS_type;
        if (sb_state.length > 2) {
            file_system_state = sb_state[0] == "Y";
            errors_behavior = sb_state[1] == "Y";
            file_system_OS_type = sb_state[2];
        }

        return SuperBlock(file_system_state, errors_behavior, file_system_OS_type, inode_count, block_count, free_inodes, free_blocks,
            block_size, created_at, last_mount_time, last_write_time, mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
    }

    function get_sb_text(bytes data) internal returns (string[] values, uint n_fields) {
        return libstring.split_line(data, " ", "\n");
    }

    function get_sb_data(bytes data) internal returns (uint16[] values) {
        (string[] fields, ) = libstring.split_line(data, " ", "\n");
        for (string s: fields)
            values.push(str.toi(s));
    }

    function read_sb(mapping (uint16 => Inode) /*inodes*/, mapping (uint16 => bytes) data) internal returns (SuperBlock) {
        string sb_data = string(data[SB]);
        (string[] fields, ) = sb_data.split_line(" ", "\n");
        uint[] values;
        string[] texts;
        for (string s: fields) {
            optional(int) val = stoi(s);
            if (val.hasValue())
                values.push(uint(val.get()));
            else
                texts.push(s);
        }

        if (texts.length > 2 && values.length > 12) {

            bool file_system_state = texts[0] == "Y";
            bool errors_behavior = texts[1] == "Y";
            string file_system_OS_type = texts[2];
            uint16 inode_count = uint16(values[0]);
            uint16 block_count = uint16(values[1]);
            uint16 free_inodes = uint16(values[2]);
            uint16 free_blocks = uint16(values[3]);
            uint16 block_size = uint16(values[4]);
            uint32 created_at = uint32(values[5]);
            uint32 last_mount_time = uint32(values[6]);
            uint32 last_write_time = uint32(values[7]);
            uint16 mount_count = uint16(values[8]);
            uint16 max_mount_count = uint16(values[9]);
            uint16 lifetime_writes = uint16(values[10]);
            uint16 first_inode = uint16(values[11]);
            uint16 inode_size = uint16(values[12]);

            return SuperBlock(file_system_state, errors_behavior, file_system_OS_type, inode_count, block_count, free_inodes, free_blocks,
                block_size, created_at, last_mount_time, last_write_time, mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
        }
    }

    function display_index_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string out) {
        SuperBlock sblk = get_sb(inodes, data);
        return display_sb(sblk);
    }
    function display_data_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string out) {
        SuperBlock sblk = read_sb(inodes, data);
        return display_sb(sblk);
    }

    function display_sb(SuperBlock sblk) internal returns (string out) {
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sblk.unpack();

        string[][] table = [
            ["Filesystem state:", file_system_state ? "clean" : "dirty"],
            ["Errors behavior:", errors_behavior ? "Continue" : "Stop"],
            ["Filesystem OS type:", file_system_OS_type],
            ["Inode count:", str.toa(inode_count)],
            ["Block count:", str.toa(block_count)],
            ["Free blocks:", str.toa(free_blocks)],
            ["Free inodes:", str.toa(free_inodes)],
            ["First block:", "0"],
            ["Block size:", str.toa(block_size)],
            ["Filesystem created:", fmt.ts(created_at)],
            ["Last mount time:", fmt.ts(last_mount_time)],
            ["Last write time:", fmt.ts(last_write_time)],
            ["Mount count:", str.toa(mount_count)],
            ["Maximum mount count:", str.toa(max_mount_count)],
            ["Lifetime writes:", str.toa(lifetime_writes)],
            ["First inode:", str.toa(first_inode)],
            ["Inode size:", str.toa(inode_size)]];
        return fmt.format_table(table, "\t", "\n", fmt.LEFT);
    }

}
