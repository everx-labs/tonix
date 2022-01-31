pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract userdel is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);

        uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
        (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        string etc_passwd;
        string etc_group;
        if (passwd_file_type == FT_REG_FILE)
            etc_passwd = fs.get_file_contents(passwd_index, inodes, data);
        if (group_file_type == FT_REG_FILE)
            etc_group = fs.get_file_contents(group_index, inodes, data);
        bool force = arg.flag_set("f", flags);
        bool remove_home_dir = arg.flag_set("r", flags);

        string victim_user_name = params[0];
//        uint16 victim_user_id;
        uint16 victim_group_id;
        uint16[] removed_groups;
        bool remove_empty_user_group = uadmin.login_def_flag(uadmin.USERGROUPS_ENAB);

        uint16 options = remove_home_dir ? uadmin.UAO_REMOVE_HOME_DIR : 0;
        options |= remove_empty_user_group ? uadmin.UAO_REMOVE_EMPTY_GROUPS : 0;

        string victim_entry = uadmin.passwd_entry_by_name(victim_user_name, etc_passwd);
        if (victim_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, victim_user_name)); // specified user doesn't exist
        // TODO: check for a running process
        string g_line = uadmin.group_entry_by_name(victim_user_name, etc_group);
        if (!g_line.empty()) {
            if (force) {
                (, uint16 gid, ) = uadmin.parse_group_entry_line(g_line);
                removed_groups.push(gid);
            } else
                errors.push(Err(8, 0, victim_user_name)); // can't remove user's primary group
        }
        if (errors.empty()) {
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", stdio.translate(etc_passwd, victim_entry, "")));
            if (!removed_groups.empty()) {
                string text = format("{}\t{}\n", victim_user_name, victim_group_id);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", stdio.translate(etc_group, text, "")));
            }
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"userdel",
"[options] LOGIN",
"delete a user account and related files",
"A low level utility for removing users.",
"-f      force removal of files, even if not owned by user\n\
-r      remove the user's home directory",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
