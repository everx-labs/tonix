pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libfs.sol";

/* Generic block device hosting a generic file system */
contract fsck is Utility {

    function exec(Session session, ParsedCommand pc, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (string out, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return _fsck(session, pc, inodes_in, data_in);
    }

    function alter(Session session, ParsedCommand pc, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (string out, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return _fsck(session, pc, inodes_in, data_in);
    }

    function _fsck(Session session, ParsedCommand pc, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) internal pure returns (string out, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        (, , string short_options, , , , , ) = pc.unpack();
        bool auto_repair = _strchr(short_options, "p") > 0;
        bool no_changes = _strchr(short_options, "n") > 0;

        bool repair = auto_repair && !no_changes;

        inodes = inodes_in;
        data = data_in;
//        uint16 block_size = 100;
        uint16 first_block = 0;
        uint total_inodes;
        uint total_blocks_reported;
        uint total_blocks_actual;

        out = libfs._display_sb(inodes, data);

        SuperBlock sb = libfs._read_sb(inodes, data);

        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();

        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
            string errors;
            bytes bts = data[i];
            uint32 len = uint32(bts.length);
            if (file_size != uint32(len)) {
                errors.append(format("Size mismatch: inode: {} data: {} \n", file_size, len));
                if (repair) {
                    out.append(format("Fixing inode {}: size {} -> {}\n", i, file_size, len));
                    inodes[i].file_size = len;
                }
            }
            uint16 n_data_blocks = uint16(len / block_size + 1);
            if (n_blocks != n_data_blocks) {
//                errors.append(format("Block count mismatch: inode: {} data: {} \n", n_blocks, n_data_blocks));
            }
            total_blocks_reported += n_blocks;
            total_blocks_actual += n_data_blocks;
            total_inodes++;

            if ((mode & S_IFMT) == S_IFDIR) {
                out.append(format("Inode dir: {}\n", i));
                out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
                out.append(bts);
                (DirEntry[] contents, int status) = _read_dir_data(bts);
                out.append(format("status {}\n", status));
                if (status < 0)
                    out.append(format("Error! status {}\n", status));
                else {
                    for (DirEntry de: contents) {
                        (uint8 sub_ft, string sub_name, uint16 sub_index) = de.unpack();
                        out.append(_dir_entry_line(sub_index, sub_name, sub_ft));
                    }
                }
            }

            if (errors.empty()) {
                out.append(format("I {} OK\n", i));
            } else {
                out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
                out.append(bts);
                out.append("\n Errors:\n");
                out.append(errors);
            }
        }

        out.append("Summary\n");
        out.append(format("Inodes SB: count: {} free: {} first: {} size: {}\n", inode_count, free_inodes, first_inode, inode_size));
        out.append(format("Inodes actual: count: {}\n", total_inodes));
        out.append(format("Blocks SB: count: {} free: {} first: {} size: {}\n", block_count, free_blocks, first_block, block_size));
        out.append(format("Blocks reported: {} actual: {}\n", total_blocks_reported, total_blocks_actual));
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("fsck", "check and repair a Tonix filesystem", "[filesystem...]",
            "Used to check and optionally repair one or more Tonix filesystems.",
            "AlRpn", 1, M, [
            "check all filesystems",
            "lock the device to guarantee exclusive access",
            "skip root filesystem",
            "automatic repair (no questions)",
            "make no changes to the filesystem"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"fsck",
"[filesystem...]",
"check and repair a Tonix filesystem",
"Used to check and optionally repair one or more Tonix filesystems.",
"-A      check all filesystems\n\
-l      lock the device to guarantee exclusive access\n\
-R      skip root filesystem\n\
-p      automatic repair (no questions)\n\
-n      make no changes to the filesystem",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
