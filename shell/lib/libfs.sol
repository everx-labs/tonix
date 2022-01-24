pragma ton-solidity >= 0.55.0;

import "../include/Internal.sol";
import "../lib/stdio.sol";
import "../lib/libfmt.sol";

library libfs {

    uint16 constant SB          = 0;
    uint16 constant DEVICE_INFO = 1;
    uint16 constant SB_INFO     = 2;
    uint16 constant SB_INODES   = SB_INFO + 1;
    uint16 constant SB_BLOCKS   = SB_INFO + 2;
    uint16 constant SB_MOUNTS   = SB_INFO + 3;
    uint16 constant SB_STATE    = SB_INFO + 4;
    uint16 constant SB_INODES_TABLE = SB_INFO + 5;
    uint16 constant SB_SB       = SB_INFO + 6;
    uint16 constant SB_JOURNAL  = SB_INFO + 7;
    uint16 constant SB_BACKUP   = SB_INFO + 8;

    function _read_sb(mapping (uint16 => Inode) /*inodes*/, mapping (uint16 => bytes) data) internal returns (SuperBlock sb) {
        bytes sb_data = data[SB];

        (string[] fields, ) = stdio.split_line(sb_data, " ", "\n");
        uint[] values;
        string[] texts;
        for (string s: fields) {
            optional(int) val = stoi(s);
            if (val.hasValue())
                values.push(uint(val.get()));
            else
                texts.push(s);
        }

        if (texts.length < 3 || values.length < 13)
            return sb;

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

        sb = SuperBlock(file_system_state, errors_behavior, file_system_OS_type, inode_count, block_count, free_inodes, free_blocks,
            block_size, created_at, last_mount_time, last_write_time, mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
    }

    function _display_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string out) {
//        SuperBlock sb = _get_sb(inodes, data);
        SuperBlock sb = libfs._read_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();

        string[][] table = [
            ["Filesystem state:", file_system_state ? "clean" : "dirty"],
            ["Errors behavior:", errors_behavior ? "Continue" : "Stop"],
            ["Filesystem OS type:", file_system_OS_type],
            ["Inode count:", stdio.itoa(inode_count)],
            ["Block count:", stdio.itoa(block_count)],
            ["Free blocks:", stdio.itoa(free_blocks)],
            ["Free inodes:", stdio.itoa(free_inodes)],
            ["First block:", "0"],
            ["Block size:", stdio.itoa(block_size)],
            ["Filesystem created:", libfmt._ts(created_at)],
            ["Last mount time:", libfmt._ts(last_mount_time)],
            ["Last write time:", libfmt._ts(last_write_time)],
            ["Mount count:", stdio.itoa(mount_count)],
            ["Maximum mount count:", stdio.itoa(max_mount_count)],
            ["Lifetime writes:", stdio.itoa(lifetime_writes)],
            ["First inode:", stdio.itoa(first_inode)],
            ["Inode size:", stdio.itoa(inode_size)]];
        return libfmt._format_table(table, "\t", "\n", libfmt.ALIGN_LEFT);
    }

}