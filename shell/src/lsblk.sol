pragma ton-solidity >= 0.53.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract lsblk is Utility, libuadm {

    /* Query devices and file systems status */
    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        uint16 pid = session.pid;
        pid = pid;
//        bool print_all_devices = (flags & _a) > 0;
        bool human_readable = (flags & _b) == 0;
        bool print_header = (flags & _n) == 0;
        bool print_fsinfo = (flags & _f) > 0;
        bool print_permissions = (flags & _m) > 0;
        bool print_device_info = !print_fsinfo && !print_permissions;
        bool full_path = (flags & _p) > 0;

        string[][] table;
        Column[] columns_format = [
            Column(true, 15, ALIGN_LEFT), // Name
            Column(print_device_info, 3, ALIGN_RIGHT),
            Column(print_device_info, 4, ALIGN_LEFT),
            Column(print_device_info || print_permissions, 7, ALIGN_CENTER),
            Column(print_device_info, 2, ALIGN_CENTER),
            Column(print_device_info, 4, ALIGN_CENTER),
            Column(print_fsinfo, 8, ALIGN_CENTER),
            Column(print_fsinfo, 6, ALIGN_CENTER),
            Column(print_device_info || print_fsinfo, 10, ALIGN_LEFT),
            Column(print_permissions, 5, ALIGN_CENTER),
            Column(print_permissions, 5, ALIGN_CENTER),
            Column(print_permissions, 10, ALIGN_LEFT)];

        uint16 dev_dir = _resolve_absolute_path("/dev", inodes, data);

        string[] header = ["NAME", "MAJ", ":MIN", "SIZE", "RM", "TYPE", "FSAVAIL", "FSUSE%", "MOUNTPOINT", "OWNER", "GROUP", "MODE"];

        if (print_header)
            table = [header];

        if (args.empty()) {
            (DirEntry[] contents, int16 status) = _read_dir(inodes[dev_dir], data[dev_dir]);
            if (status < 0) {
                out.append(format("Error: {} \n", status));
//                return (out, errors);
            }
            uint len = uint(status);
            for (uint16 j = 0; j < len; j++) {
                (uint8 ft, string name, ) = contents[j].unpack();
                if (ft == FT_BLKDEV || ft == FT_CHRDEV)
                    args.push(name);
            }
        }
        (, , , , uint16 block_count, , uint16 free_blocks, uint16 block_size, , , , , , , , ) = _get_sb(inodes, data).unpack();

        for (string s: args) {
            (uint16 dev_file_index, uint8 dev_file_ft) = _fetch_dir_entry(s, dev_dir, inodes, data);
            if (dev_file_ft == FT_BLKDEV || dev_file_ft == FT_CHRDEV) {
                (uint16 mode, uint16 owner_id, uint16 group_id, , , , , , , ) = inodes[dev_file_index].unpack();
                (string[] lines, ) = _split(data[dev_file_index], "\n");
                string[] fields0 = _get_tsv(lines[0]);
                if (fields0.length < 4)
                    continue;
                string name = (full_path ? "/dev/" : "") + fields0[2];
                string mount_path = dev_file_ft == FT_BLKDEV ? ROOT : "";
                string s_owner = _get_user_name(owner_id, inodes, data);
                string s_group = _get_group_name(group_id, inodes, data);

                table.push([
                    name,
                    format("{}", fields0[0]),
                    format(":{}", fields0[1]),
                    _scale(uint32(block_count) * block_size, human_readable ? KILO : 1),
                    "0",
                    "disk",
                    _scale(uint32(free_blocks) * block_size, human_readable ? KILO : 1),
                    format("{}%", uint32(block_count) * 100 / (block_count + free_blocks)),
                    mount_path,
                    s_owner,
                    s_group,
                    _permissions(mode)]);
            } else
                errors.push(Err(not_a_block_device, 0, s));
        }
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function _list_devices(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (DirEntry[] device_list) {
        uint16 dev_dir = _resolve_absolute_path("/dev", inodes, data);
        (DirEntry[] contents, int16 status) = _read_dir(inodes[dev_dir], data[dev_dir]);
        if (status >= 0) {
            for (DirEntry de: contents)
                if (de.file_type == FT_BLKDEV || de.file_type == FT_CHRDEV)
                    device_list.push(de);
        }
    }

    function _command_info() internal override pure returns
        (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
            "lsblk",
            "list block devices",
            "[options] [device...]",
            "List information about all available or the specified block devices.",
            "abfmnOp",
            0,
            M, [
                "print all devices",
                "print SIZE in bytes rather than in human readable format",
                "output info about filesystems",
                "output info about permissions",
                "don't print headings",
                "output all columns",
                "print complete device path"]);
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
