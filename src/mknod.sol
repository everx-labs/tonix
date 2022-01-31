pragma ton-solidity >= 0.56.0;

import "Utility.sol";

struct DeviceRecord {
    uint8 major_version;
    uint8 minor_version;
    uint8 status;
    uint32 assembly_time;
    address location;
}

contract mknod is Utility {

    function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        string node_name;
        uint n_args = params.length;
        if (!params.empty())
            node_name = params[0];
        string node_type;
        uint8 file_type;
        if (n_args > 1) {
            node_type = params[1];
            if (node_type == "b") {
                file_type = FT_BLKDEV;
            }
            else if (node_type == "c" || node_type == "u")
                file_type = FT_CHRDEV;
            else if (node_type == "p")
                file_type = FT_FIFO;
            (ars, errors) = _mknod(file_type, node_name, flags, sb.get_inode_count(inodes), inodes, data);
        }
    }

    function _mknod(uint8 file_type, string file_name, string flags, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (Ar[] ars, Err[] errors) {
        uint8 action_item_type = IO_MKDIR;
        mapping (uint16 => string[]) parent_dirs;

        uint16 dev_dir_index = fs.resolve_absolute_path("/dev", inodes, data);
        (uint16 index, uint8 ft) = fs.lookup_dir(inodes[dev_dir_index], data[dev_dir_index], file_name);

            if (ft == FT_UNKNOWN) {
                string contents;// = _get_dots(ic, parent);
                ars.push(Ar(action_item_type, file_type, index, 0, file_name, contents));
                parent_dirs[dev_dir_index].push(dirent.dir_entry_line(ic, file_name, file_type));
                ic++;
            } else
                errors.push(Err(0, er.EEXIST, file_name));

        for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
            uint16 n_dirents = uint16(added_dirents.length);
            if (n_dirents > 0)
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, dir_i, n_dirents, "", stdio.join_fields(added_dirents, "\n")));
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mknod",
"[OPTION]... NAME TYPE [MAJOR MINOR]",
"make block or character special files",
"Create the special file NAME of the given TYPE.",
"-m     set file permission bits to MODE, not a=rw - umask",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
