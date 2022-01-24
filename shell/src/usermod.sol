pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract usermod is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);

        uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
        (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
        (uint16 group_index, uint8 group_file_type, ) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        string etc_passwd;
        string etc_group;
        if (passwd_file_type == FT_REG_FILE)
            etc_passwd = _get_file_contents(passwd_index, inodes, data);
        if (group_file_type == FT_REG_FILE)
            etc_group = _get_file_contents(group_index, inodes, data);
//        bool append_to_supp_groups = (flags & _a) > 0;
        bool change_primary_group = arg.flag_set("g", flags);
        bool supp_groups_list = arg.flag_set("G", flags);

        uint n_args = params.length;
        string user_name = params[n_args - 1];
        uint16 user_id;
        uint16 group_id;
        string group_name;
        uint16[] group_list;

        string prev_entry = uadmin.passwd_entry_by_name(user_name, etc_passwd);
        if (prev_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, user_name)); // specified user doesn't exist
        if (change_primary_group && n_args > 1) {
            string group_id_s = params[0];
            optional(int) val = stoi(group_id_s);
            if (!val.hasValue())
                errors.push(Err(uadmin.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                group_id = uint16(val.get());
            group_name = uadmin.group_name_by_id(group_id, etc_group);
            if (group_name.empty())
                errors.push(Err(uadmin.E_NOTFOUND, 0, group_name)); // specified group doesn't exist
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = params[0];
            (string[] supp_list, ) = stdio.split(supp_string, ",");
            for (string s: supp_list) {
                string g_line = uadmin.group_entry_by_name(s, etc_group);
                if (!g_line.empty()) {
                    (, uint16 gid_found, ) = uadmin.parse_group_entry_line(g_line);
                    group_list.push(gid_found);
                } else
                    errors.push(Err(uadmin.E_NOTFOUND, 0, s));
            }
        }
        if (errors.empty()) {
            string text = format("{}\t{}\t{}\t{}\t/home/{}\n", user_name, user_id, group_id, group_name, user_name);
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", stdio.translate(etc_passwd, prev_entry, text)));
            file_action = Action(UA_UPDATE_USER, 1);
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"usermod",
"[options] LOGIN",
"modify a user account",
"Modifies the system account files to reflect the changes that are specified on the command line.",
"-a      add the user to the supplementary groups mentioned by the -G option\n\
-g      force use GROUP as new primary group\n\
-G      a list of supplementary groups separated from the next by a comma",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
