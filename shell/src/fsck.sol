pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libfs.sol";

contract fsck is Utility {

    uint8 constant NO_ERRORS                = 0;
    uint8 constant ERRORS_CORRECTED         = 1;
    uint8 constant ERRORS_CORRECTED_REBOOT  = 2;
    uint8 constant ERRORS_UNCORRECTED       = 4;
    uint8 constant OPERATIONAL_ERROR        = 8;
    uint8 constant USAGE_OR_SYNTAX_ERROR    = 16;
    uint8 constant CANCELED_BY_USER         = 32;
    uint8 constant SHARED_LIBRARY_ERROR     = 128;

    function _print_dir_contents(uint16 start_dir_index, mapping (uint16 => bytes) data) internal pure returns (uint8 ec, string out) {
        (DirEntry[] contents, int16 status) = _read_dir_data(data[start_dir_index]);
        if (status < 0) {
            out.append(format("Error: {} \n", status));
            ec = EXECUTE_FAILURE;
        } else {
            uint len = uint(status);
            for (uint16 j = 0; j < len; j++) {
                (uint8 ft, string name, uint16 index) = contents[j].unpack();
                if (ft == FT_UNKNOWN)
                    continue;
                out.append(_dir_entry_line(index, name, ft));
            }
        }
    }

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, mapping (uint16 => Inode) inodes_out, mapping (uint16 => bytes) data_out) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        bool auto_repair = arg.flag_set("p", flags);
        bool check_all = arg.flag_set("A", flags);
        bool no_changes = arg.flag_set("n", flags);
        bool repair = auto_repair && !no_changes;

        inodes_out = inodes;
        data_out = data;

        string start_dir = params.empty() ? "/" : params[0];

        uint16 start_dir_index = _resolve_absolute_path(start_dir, inodes, data);
        if (start_dir_index >= ROOT_DIR) {
            (DirEntry[] contents, int16 status) = _read_dir_data(data[start_dir_index]);
            if (status < 0) {
                out.append(format("Error: {} \n", status));
                ec = EXECUTE_FAILURE;
            } else {
                uint len = uint(status);
                for (uint16 j = 0; j < len; j++) {
                    (uint8 ft, string name, uint16 index) = contents[j].unpack();
                    if (ft == FT_UNKNOWN)
                        continue;
                    out.append(_dir_entry_line(index, name, ft));
                }
            }
        }

//        uint16 block_size = 100;
        uint16 first_block = 0;
        uint total_inodes;
        uint total_blocks_reported;
        uint total_blocks_actual;

    if (check_all) {
        out = libfs.display_sb(inodes, data);

        SuperBlock sb = libfs.read_sb(inodes, data);

        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, /*uint32 last_write_time*/, uint16 mount_count,
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
                    inodes_out[i].file_size = len;
                    ec |= ERRORS_CORRECTED;
                } else
                    ec |= ERRORS_UNCORRECTED;
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
-N      don't execute, just show what would be done\n\
-n      make no changes to the filesystem",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
