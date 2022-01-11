pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract touch is Utility {

    function induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (Action file_action, Ar[] ars) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        uint16 ic = _get_inode_count(inodes);
        bool create_files = (flags & _c) == 0;
        bool update_if_exists = (flags & _m) == 0;

        uint n = arg_list.length;
        file_action = Action(IO_CREATE_FILES, uint16(n));
        mapping (uint16 => string[]) parent_dirs;

        for (Arg arg: arg_list) {
            (string path, uint8 ft, uint16 index, uint16 parent, uint16 dir_index) = arg.unpack();
            (, string file_name) = _dir(path);
            if (dir_index == 0 && create_files) {
                uint8 file_type = FT_REG_FILE;
                string contents;
                ars.push(Ar(IO_MKFILE, file_type, index, dir_index, file_name, contents));
                parent_dirs[parent].push(_dir_entry_line(ic, file_name, file_type));
                ic++;
            } else
                if (update_if_exists)
                    ars.push(Ar(IO_UPDATE_TIME, ft, index, dir_index, path, ""));
        }
        for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
            uint16 n_dirents = uint16(added_dirents.length);
            if (n_dirents > 0)
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, dir_i, n_dirents, "", _join_fields(added_dirents, "\n")));
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
            "touch",
            "change file timestamps",
            "[OPTION]... FILE...",
            "Update the modification time of each FILE to the current time. A FILE argument that does not exist is created empty, unless -c is supplied.",
            "cm", 1, M, [
                "do not create any files",
                "change only the modification time"]);
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
