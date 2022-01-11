pragma ton-solidity >= 0.51.0;

import "Utility.sol";

struct DeviceRecord {
    uint8 major_version;
    uint8 minor_version;
    uint8 status;
    uint32 assembly_time;
    address location;
}

contract mknod is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        string node_name;
        uint n_args = args.length;
        if (!args.empty())
            node_name = args[0];
        string node_type;
        uint8 file_type;
        if (n_args > 1) {
            node_type = args[1];
            if (node_type == "b") {
                file_type = FT_BLKDEV;
            }
            else if (node_type == "c" || node_type == "u")
                file_type = FT_CHRDEV;
            else if (node_type == "p")
                file_type = FT_FIFO;
            (out, file_action, ars, errors) = _mknod(file_type, node_name, flags,  _get_inode_count(inodes), inodes, data);
        }
    }

    function _mknod(uint8 file_type, string file_name, uint flags, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {

        uint8 action_type = IO_CREATE_FILES;
        uint8 action_item_type = IO_MKDIR;

        action = Action(action_type, 1);
        mapping (uint16 => string[]) parent_dirs;

        uint16 dev_dir_index = _resolve_absolute_path("/dev", inodes, data);
        (uint16 index, uint8 ft) = _lookup_dir(inodes[dev_dir_index], data[dev_dir_index], file_name);

//            (string path, , uint16 index, uint16 parent, uint16 dir_index) = arg.unpack();
//            (, string file_name) = _dir(path);
            if (ft == FT_UNKNOWN) {
                string contents;// = _get_dots(ic, parent);
                ars.push(Ar(action_item_type, file_type, index, 0, file_name, contents));
                parent_dirs[dev_dir_index].push(_dir_entry_line(ic, file_name, file_type));
                ic++;
            } else
                errors.push(Err(0, EEXIST, file_name));

        for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
            uint16 n_dirents = uint16(added_dirents.length);
            if (n_dirents > 0)
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, dir_i, n_dirents, "", _join_fields(added_dirents, "\n")));
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("mknod", "make block or character special files", "[OPTION]... NAME TYPE [MAJOR MINOR]",
            "Create the special file NAME of the given TYPE.",
            "m", 1, M, [
            "set file permission bits to MODE, not a=rw - umask"]);
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
