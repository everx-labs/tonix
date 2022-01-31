pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract userdel is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        (bool force, /*bool remove_home_dir*/, , , , , , ) = arg.flag_values("fr", flags);
        string victim_user_name = params[0];

        (string etc_passwd, string etc_group, uint16 etc_passwd_index, uint16 etc_group_index) = fs.get_passwd_group(inodes, data);
        string victim_entry = uadmin.passwd_entry_by_name(victim_user_name, etc_passwd);
        if (victim_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, victim_user_name)); // specified user doesn't exist

        uint16 victim_group_id;
        uint16[] removed_groups;
//        bool remove_empty_user_group = uadmin.login_def_flag(uadmin.USERGROUPS_ENAB);

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
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, etc_passwd_index, 0, "passwd", stdio.translate(etc_passwd, victim_entry + "\n", "")));
            if (!removed_groups.empty()) {
                string text = format("{}\t{}\n", victim_user_name, victim_group_id);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, etc_group_index, 0, "group", stdio.translate(etc_group, text, "")));
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
