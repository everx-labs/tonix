pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract mountpoint is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        (out, errors) = _mountpoint(flags, args, arg_list, inodes, data);// 500
    }

    /* File manipulation operations - cp, ln and mv */
    function _mountpoint(uint flags, string[] args, Arg[] arg_list, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Err[] errors) {
        bool mounted_device = (flags & _d) > 0;
        bool quiet = (flags & _q) > 0;
        bool arg_device = (flags & _x) > 0;

        string arg = args[0];
        Arg x_arg = arg_list[0];
        (string path, uint8 ft, uint16 index, , ) = x_arg.unpack();

        if (arg_device) {
            if (ft != FT_BLKDEV)
                errors = [Err(not_a_block_device, 0, path)];
            else {
                (string major_id, string minor_id) = _get_device_version(inodes[index].device_id);
                out = major_id + ":" + minor_id;
            }
        }

        string text;
        text = _get_file_contents_at_path("/etc/fstab", inodes, data);
        text.append(_get_file_contents_at_path("/etc/mtab", inodes, data));

        DirEntry[] device_list = _list_devices(inodes, data);

        (string[] tab_lines, ) = _split(text, "\n");
        for (string line: tab_lines) {
            (string[] fields, uint n_fields) = _split(line, "\t");
            if (n_fields > 3) {
                if (fields[1] == arg) {
                    for (DirEntry de: device_list) {
                        if (de.file_name == fields[0]) {
                            (string major_id, string minor_id) = _get_device_version(inodes[de.index].device_id);
                            out.append(mounted_device ? format("{}:{}", major_id, minor_id) : (path + " is a mountpoint"));
                        }
                    }
                }
            }
        }

        _if(out, out.empty(), path + " is not a mountpoint");
        if (quiet)
            out = "";
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

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return("mountpoint", "see if a directory or file is a mountpoint", "[-d|-q] directory | file\t-x device",
            "Checks whether the given directory or file is mentioned in the /proc/self/mountinfo file.",
            "dqx", 1, 1, [
            "quiet mode - don't print anything",
            "print maj:min device number of the filesystem",
            "print maj:min device number of the block device"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
