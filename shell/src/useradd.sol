pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract useradd is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        string etc_passwd = _get_file_contents_at_path("/etc/passwd", inodes, data);
        string etc_group = _get_file_contents_at_path("/etc/group", inodes, data);
        bool create_user_group_def = uadmin.login_def_flag(uadmin.USERGROUPS_ENAB);
        bool create_home_dir_def = uadmin.login_def_flag(uadmin.CREATE_HOME);

        (bool is_system_account, bool create_home_flag, bool do_not_create_home_flag, bool create_user_group_flag, bool do_not_create_user_group_flag,
            bool use_user_id, bool use_group_id, bool supp_groups_list) = arg.flag_values("rmMUNugG", flags);

        bool create_home_dir = (create_home_dir_def || create_home_flag) && !do_not_create_home_flag;
        bool create_user_group = (create_user_group_def || create_user_group_flag) && !do_not_create_user_group_flag;

        uint n_args = params.length;
        string user_name = params[n_args - 1];
        uint16 group_id;
        uint16 user_id;
        uint16 options = is_system_account ? UAO_SYSTEM : 0;
        options |= create_home_dir ? UAO_CREATE_HOME_DIR : 0;
        options |= create_user_group ? UAO_CREATE_USER_GROUP : 0;

        uint16[] new_group_ids;

        string line = uadmin.passwd_entry_by_name(user_name, etc_passwd);
        if (!line.empty())
            errors.push(Err(uadmin.E_NAME_IN_USE, 0, user_name));

        if (use_group_id && n_args > 1) {
            string group_id_s = params[0];
            optional(int) val = stoi(group_id_s);
            uint16 n_gid;
            if (!val.hasValue())
                errors.push(Err(uadmin.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            group_id = uint16(n_gid);
            if (uadmin.group_name_by_id(group_id, etc_group).empty())
                errors.push(Err(uadmin.E_NOTFOUND, 0, group_id_s)); // specified group doesn't exist
            else
                new_group_ids = [group_id];
        } else if (use_user_id && n_args > 1) {
            string user_id_s = params[0];
            optional(int) val = stoi(user_id_s);
            if (!val.hasValue())
                errors.push(Err(uadmin.E_BAD_ARG, 0, user_id_s)); // invalid argument to option
            else
                user_id = uint16(val.get());
            line = uadmin.passwd_entry_by_uid(user_id, etc_passwd);
            if (!line.empty())
                errors.push(Err(uadmin.E_GID_IN_USE, 0, user_id_s)); // UID already in use (and no -o)
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = params[0];
            (string[] supp_list, ) = stdio.split(supp_string, ",");
            for (string s: supp_list) {
                string g_line = uadmin.group_entry_by_name(s, etc_group);
                if (!g_line.empty()) {
                    (, uint16 gid_found, ) = uadmin.parse_group_entry_line(g_line);
                    new_group_ids.push(gid_found);
                } else
                    errors.push(Err(uadmin.E_NOTFOUND, 0, s));
            }
        }

        (uint16 reg_users_counter, uint16 sys_users_counter, uint16 reg_groups_counter, uint16 sys_groups_counter) = uadmin.get_counters(etc_passwd);
        if (user_id == 0)
            user_id = is_system_account ? sys_users_counter++ : reg_users_counter++;

        if (create_user_group) {
            if (group_id == 0)
                group_id = is_system_account ? sys_groups_counter++ : reg_groups_counter++;
        } else {
//            if (group_id == 0)
//                group_id = is_system_account ? _login_defs_uint16[SYS_GID_MIN] : _login_defs_uint16[GID_MIN];
        }
        if (errors.empty()) {
            string text;
            uint16 n_files;
            uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
            (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
            (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");

            uint16 ic = _get_inode_count(inodes);

            text = uadmin.passwd_entry_line(user_name, user_id, group_id, user_name);
            if (passwd_file_type == FT_UNKNOWN || passwd_dir_idx == 0) {
                ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "passwd", text));
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", _dir_entry_line(ic, "passwd", FT_REG_FILE)));
                ic++;
                n_files++;
            } else
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", etc_passwd + text));

            if (create_user_group) {
                string group_text = uadmin.group_entry_line(user_name, group_id);
                if (group_file_type == FT_UNKNOWN || group_dir_idx == 0) {
                    ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "group", group_text));
                    ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", _dir_entry_line(ic, "group", FT_REG_FILE)));
                    ic++;
                    n_files++;
                } else
                    ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", etc_group + group_text));
            }
            file_action = Action(UA_ADD_USER, n_files);
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"useradd",
"[options] LOGIN",
"create a new user or update default new user information",
"A low level utility for adding users.",
"-g      name or ID of the primary group of the new account\n\
-G      a list of supplementary groups which the user is also a member of\n\
-l      do not add the user to the lastlog and faillog databases\n\
-m      create the user's home directory\n\
-M      do no create the user's home directory\n\
-N      do not create a group with the same name as the user\n\
-r      create a system account\n\
-U      create a group with the same name as the user",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
