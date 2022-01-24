pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract mkdir is Utility {

    function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
            arg_list.push(Arg(s_arg, ft, index, parent, dir_index));
        }
        (out, file_action, ars, errors) = _mkdir(flags, arg_list, _get_inode_count(inodes));
    }

    function _mkdir(string flags, Arg[] arg_list, uint16 ic) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
        bool error_if_exists = !arg.flag_set("p", flags);
        bool report_actions = arg.flag_set("v", flags);

        uint8 action_type = IO_CREATE_FILES;
        uint8 action_item_type = IO_MKDIR;

        uint n = arg_list.length;
        action = Action(action_type, uint16(n));
        mapping (uint16 => string[]) parent_dirs;

        for (Arg ag: arg_list) {
            (string s_path, , uint16 index, uint16 parent, uint16 dir_index) = ag.unpack();
            (, string file_name) = path.dir(s_path);
            if (dir_index == 0) {
                uint8 file_type = FT_DIR;
                string contents = _get_dots(ic, parent);
                ars.push(Ar(action_item_type, file_type, index, dir_index, file_name, contents));
                parent_dirs[parent].push(_dir_entry_line(ic, file_name, file_type));
                ic++;
                if (report_actions)
                    out.append("mkdir: created directory" + stdio.quote(file_name) + "\n");
            } else {
                if (error_if_exists)
                    errors.push(Err(0, EEXIST, file_name));
            }
        }
        for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
            uint16 n_dirents = uint16(added_dirents.length);
            if (n_dirents > 0)
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, dir_i, n_dirents, "", stdio.join_fields(added_dirents, "\n")));
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mkdir",
"[OPTION]... DIRECTORY...",
"make directories",
"Create the DIRECTORY(ies), if they do not already exist.",
"-m      set file mode (as in chmod), not a=rwx - umask\n\
-p      no error if existing, make parent directories as needed\n\
-v      print a message for each created directory",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
