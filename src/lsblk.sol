pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract lsblk is Utility {

    /* Query devices and file systems status */
    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        (/*bool print_all_devices*/, bool human_readable, bool print_header, bool print_fsinfo, bool print_permissions, bool full_path, , ) =
            arg.flag_values("abnfmp", flags);
        bool print_device_info = !print_fsinfo && !print_permissions;
        string[][] table;
        Column[] columns_format = [
            Column(true, 15, fmt.ALIGN_LEFT), // Name
            Column(print_device_info, 3, fmt.ALIGN_RIGHT),
            Column(print_device_info, 4, fmt.ALIGN_LEFT),
            Column(print_device_info || print_permissions, 7, fmt.ALIGN_CENTER),
            Column(print_device_info, 2, fmt.ALIGN_CENTER),
            Column(print_device_info, 4, fmt.ALIGN_CENTER),
            Column(print_fsinfo, 8, fmt.ALIGN_CENTER),
            Column(print_fsinfo, 6, fmt.ALIGN_CENTER),
            Column(print_device_info || print_fsinfo, 10, fmt.ALIGN_LEFT),
            Column(print_permissions, 5, fmt.ALIGN_CENTER),
            Column(print_permissions, 5, fmt.ALIGN_CENTER),
            Column(print_permissions, 10, fmt.ALIGN_LEFT)];

        uint16 dev_dir = fs.resolve_absolute_path("/dev", inodes, data);

        string[] header = ["NAME", "MAJ", ":MIN", "SIZE", "RM", "TYPE", "FSAVAIL", "FSUSE%", "MOUNTPOINT", "OWNER", "GROUP", "MODE"];

        if (print_header)
            table = [header];

        if (params.empty()) {
            (DirEntry[] contents, int16 status) = dirent.read_dir(inodes[dev_dir], data[dev_dir]);
            if (status < 0) {
                out.append(format("Error: {} \n", status));
//                return (out, errors);
            }
            uint len = uint(status);
            for (uint16 j = 0; j < len; j++) {
                (uint8 ft, string name, ) = contents[j].unpack();
                if (ft == FT_BLKDEV || ft == FT_CHRDEV)
                    params.push(name);
            }
        }
        (, , , , uint16 block_count, , uint16 free_blocks, uint16 block_size, , , , , , , , ) = sb.get_sb(inodes, data).unpack();

        (mapping (uint16 => string) user, mapping (uint16 => string) group) = arg.get_users_groups(argv);

        for (string s: params) {
            (uint16 dev_file_index, uint8 dev_file_ft) = fs.fetch_dir_entry(s, dev_dir, inodes, data);
            if (dev_file_ft == FT_BLKDEV || dev_file_ft == FT_CHRDEV) {
                (uint16 mode, uint16 owner_id, uint16 group_id, , , , , , , ) = inodes[dev_file_index].unpack();
                (string[] lines, ) = stdio.split(data[dev_file_index], "\n");
                string[] fields0 = fmt.get_tsv(lines[0]);
                if (fields0.length < 4)
                    continue;
                string name = (full_path ? "/dev/" : "") + fields0[2];
                string mount_path = dev_file_ft == FT_BLKDEV ? ROOT : "";
                string s_owner = user[owner_id];
                string s_group = group[group_id];

                table.push([
                    name,
                    format("{}", fields0[0]),
                    format(":{}", fields0[1]),
                    fmt.scale(uint32(block_count) * block_size, human_readable ? KILO : 1),
                    "0",
                    "disk",
                    fmt.scale(uint32(free_blocks) * block_size, human_readable ? KILO : 1),
                    format("{}%", uint32(block_count) * 100 / (block_count + free_blocks)),
                    mount_path,
                    s_owner,
                    s_group,
                    inode.permissions(mode)]);
            } else
//                errors.push(Err(er.not_a_block_device, 0, s));
                err.append(s + ": not a block device\n");
        }
        out = fmt.format_table_ext(columns_format, table, " ", "\n");
    }

    function _list_devices(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (DirEntry[] device_list) {
        uint16 dev_dir = fs.resolve_absolute_path("/dev", inodes, data);
        (DirEntry[] contents, int16 status) = dirent.read_dir(inodes[dev_dir], data[dev_dir]);
        if (status >= 0) {
            for (DirEntry de: contents)
                if (de.file_type == FT_BLKDEV || de.file_type == FT_CHRDEV)
                    device_list.push(de);
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"lsblk",
"[options] [device...]",
"list block devices",
"List information about all available or the specified block devices.",
"-a      print all devices\n\
-b      print SIZE in bytes rather than in human readable format\n\
-f      output info about filesystems\n\
-m      output info about permissions\n\
-n      don't print headings\n\
-O      output all columns\n\
-p      print complete device path",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}

