pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract mountpoint is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        bool mounted_device = arg.flag_set("d", flags);
        bool quiet = arg.flag_set("q", flags);
        bool arg_device = arg.flag_set("x", flags);

        string s_path = params[0];
        (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(s_path, wd, inodes, data);
        if (arg_device) {
            if (ft != FT_BLKDEV)
                err.append("not_a_block_device " + s_path);
            else {
                (string major_id, string minor_id) = inode.get_device_version(inodes[index].device_id);
                out = major_id + ":" + minor_id;
            }
        }

        string text;
        text = fs.get_file_contents_at_path("/etc/fstab", inodes, data);
        text.append(fs.get_file_contents_at_path("/etc/mtab", inodes, data));

        DirEntry[] device_list = _list_devices(inodes, data);

        (string[] tab_lines, ) = stdio.split(text, "\n");
        for (string line: tab_lines) {
            (string[] fields, uint n_fields) = stdio.split(line, "\t");
            if (n_fields > 3) {
                if (fields[1] == s_path) {
                    for (DirEntry de: device_list) {
                        if (de.file_name == fields[0]) {
                            (string major_id, string minor_id) = inode.get_device_version(inodes[de.index].device_id);
                            out.append(mounted_device ? format("{}:{}", major_id, minor_id) : (s_path + " is a mountpoint"));
                        }
                    }
                }
            }
        }

        stdio.aif(out, out.empty(), s_path + " is not a mountpoint");
        if (quiet)
            out = "";
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
"mountpoint",
"[-d|-q] directory | file\t-x device",
"see if a directory or file is a mountpoint",
"Checks whether the given directory or file is mentioned in the /proc/self/mountinfo file.",
"-d      quiet mode - don't print anything\n\
-q      print maj:min device number of the filesystem\n\
-x      print maj:min device number of the block device",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
