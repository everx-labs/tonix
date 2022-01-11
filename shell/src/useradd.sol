pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract useradd is Utility, libuadm {
//contract useradd is Utility {

    function uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();

        session.pid = session.pid;
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        mapping (uint16 => GroupInfo) groups = _get_group_info(inodes, data);

        UserEvent ue;
        (ue, file_action, ars, errors) = _useradd(flags, args, inodes, data, users, groups);
        out = out;
    }

    function _useradd(uint flags, string[] args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups) private pure returns (UserEvent ue, Action file_action, Ar[] ars, Err[] errs) {
        bool create_user_group_def = _login_def_flag(USERGROUPS_ENAB);
        bool create_home_dir_def = _login_def_flag(CREATE_HOME);

//        bool no_log_init = (flags & _l) > 0;
//        bool flag_create_home = (flags & _m) > 0 && (flags & _M) == 0;
        bool is_system_account = (flags & _r) > 0;
        bool create_home_flag = (flags & _m) > 0;
        bool do_not_create_home_flag = (flags & _M) > 0;
        bool create_user_group_flag = (flags & _U) > 0;
        bool do_not_create_user_group_flag = (flags & _N) > 0;

        bool use_user_id = (flags & _u) > 0;
        bool use_group_id = (flags & _g) > 0;
        bool supp_groups_list = (flags & _G) > 0;

        bool create_home_dir = (create_home_dir_def || create_home_flag) && !do_not_create_home_flag;
        bool create_user_group = (create_user_group_def || create_user_group_flag) && !do_not_create_user_group_flag;

        uint n_args = args.length;
        string user_name = args[n_args - 1];
        uint16 group_id;
        uint16 user_id;
        uint16 options = is_system_account ? UAO_SYSTEM : 0;
        options |= create_home_dir ? UAO_CREATE_HOME_DIR : 0;
        options |= create_user_group ? UAO_CREATE_USER_GROUP : 0;

        uint16[] new_group_ids;

        for ((, UserInfo u): users)
            if (u.user_name == user_name)
                errs.push(Err(E_NAME_IN_USE, 0, user_name));

        if (use_group_id && n_args > 1) {
            string group_id_s = args[0];
            optional(int) val = stoi(group_id_s);
            uint16 n_gid;
            if (!val.hasValue())
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            group_id = uint16(n_gid);
            if (!groups.exists(group_id))
                errs.push(Err(E_NOTFOUND, 0, group_id_s)); // specified group doesn't exist
            else
                new_group_ids = [group_id];
        } else if (use_user_id && n_args > 1) {
            string user_id_s = args[0];
            optional(int) val = stoi(user_id_s);
            if (!val.hasValue())
                errs.push(Err(E_BAD_ARG, 0, user_id_s)); // invalid argument to option
            else
                user_id = uint16(val.get());
            if (users.exists(user_id))
                errs.push(Err(E_GID_IN_USE, 0, user_id_s)); // UID already in use (and no -o)
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = args[0];
            (string[] supp_list, ) = _split(supp_string, ",");
            for (string s: supp_list) {
                uint16 gid_found = 0;
                for ((uint16 gid, GroupInfo gi): groups)
                    if (gi.group_name == s)
                        gid_found = gid;
                if (gid_found > 0)
                    new_group_ids.push(gid_found);
                else
                    errs.push(Err(E_NOTFOUND, 0, s));
            }
        }

        (uint16 reg_users_counter, uint16 sys_users_counter, uint16 reg_groups_counter, uint16 sys_groups_counter) = _get_counters(inodes, data);
        if (user_id == 0)
            user_id = is_system_account ? sys_users_counter++ : reg_users_counter++;

        if (create_user_group) {
            if (group_id == 0)
                group_id = is_system_account ? sys_groups_counter++ : reg_groups_counter++;
        } else {
//            if (group_id == 0)
//                group_id = is_system_account ? _login_defs_uint16[SYS_GID_MIN] : _login_defs_uint16[GID_MIN];
        }

        if (errs.empty())
            ue = UserEvent(UA_ADD_USER, user_id, group_id, options, user_name, user_name, new_group_ids);
//            ars.push(Ar(UA_ADD_USER, FT_REG_FILE, to_dir ? t_ino : wd, t_idx, "passwd", dirents));
        if (errs.empty()) {
            (uint8 et, , , , , , ) = ue.unpack();
            string text;
            uint16 n_files;
            uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
            (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
            (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
            string etc_passwd;
            string etc_group;
            if (passwd_file_type == FT_REG_FILE)
                etc_passwd = _get_file_contents(passwd_index, inodes, data);
            if (group_file_type == FT_REG_FILE)
                etc_group = _get_file_contents(group_index, inodes, data);
            uint16 ic = _get_inode_count(inodes);

            text = _passwd_entry_line(user_name, user_id, group_id, user_name);
            if (passwd_file_type == FT_UNKNOWN || passwd_dir_idx == 0) {
                ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "passwd", text));
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", _dir_entry_line(ic, "passwd", FT_REG_FILE)));
                ic++;
                n_files++;
            } else
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", etc_passwd + text));

            if (create_user_group) {
                string group_text = _group_entry_line(user_name, group_id);
                if (group_file_type == FT_UNKNOWN || group_dir_idx == 0) {
                    ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "group", group_text));
                    ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", _dir_entry_line(ic, "group", FT_REG_FILE)));
                    ic++;
                    n_files++;
                } else
                    ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", etc_group + group_text));
            }
            file_action = Action(et, n_files);
        }

    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("useradd", "create a new user or update default new user information", "[options] LOGIN",
            "A low level utility for adding users.",
            "gGlmMNrU", 1, M, [
            "name or ID of the primary group of the new account",
            "a list of supplementary groups which the user is also a member of",
            "do not add the user to the lastlog and faillog databases",
            "create the user's home directory",
            "do no create the user's home directory",
            "do not create a group with the same name as the user",
            "create a system account",
            "create a group with the same name as the user"]);
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
