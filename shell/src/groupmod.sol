pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract groupmod is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);

        uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");

        string etc_group;
        if (group_file_type == FT_REG_FILE)
            etc_group = _get_file_contents(group_index, inodes, data);
        string prev_entry;
        bool use_group_id = arg.flag_set("g", flags);
        bool use_new_name = arg.flag_set("n", flags);

        uint n_args = params.length;
        string target_group_name = params[n_args - 1];
        uint16 target_group_id;
        uint16 new_group_id;
        string new_group_name;
        string g_line = uadmin.group_entry_by_name(target_group_name, etc_group);
        if (!g_line.empty())
            (, target_group_id, ) = uadmin.parse_group_entry_line(g_line);

        if (target_group_id == 0)
            errors.push(Err(uadmin.E_NOTFOUND, 0, target_group_name)); // specified group doesn't exist

        prev_entry = format("{}\t{}\n", target_group_name, target_group_id);

        if (use_group_id && n_args > 1) {
            string group_id_s = params[0];
            uint16 n_gid;
            optional(int) val = stoi(group_id_s);
            if (!val.hasValue())
                errors.push(Err(uadmin.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            if (!uadmin.group_name_by_id(n_gid, etc_group).empty())
                errors.push(Err(uadmin.E_GID_IN_USE, 0, group_id_s));
            else
                new_group_id = n_gid;
        } else if (use_new_name && n_args > 1) {
            new_group_name = params[0];
            g_line = uadmin.group_entry_by_name(new_group_name, etc_group);
            if (!g_line.empty())
                errors.push(Err(uadmin.E_NAME_IN_USE, 0, new_group_name));
        }
        if (errors.empty()) {
            string text = format("{}\t{}\n", use_new_name ? new_group_name : target_group_name, new_group_id);
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", stdio.translate(etc_group, prev_entry, text)));
            file_action = Action(use_group_id ? UA_CHANGE_GROUP_ID : UA_RENAME_GROUP, 1);
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupmod",
"[options] GROUP",
"modify a group definition on the system",
"Modifies the definition of the specified GROUP by modifying the appropriate entry in the group database.",
"-g     the group ID of the given GROUP will be changed to GID\n\
-n      the name of the group will be changed from GROUP to NEW_GROUP name",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
