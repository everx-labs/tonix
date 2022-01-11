pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract userdel is Utility, libuadm {

    function uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _uadm(session, input, inodes, data);
    }

    function _uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();

        session.pid = session.pid;
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        mapping (uint16 => GroupInfo) groups = _get_group_info(inodes, data);

        uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
        (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        string etc_passwd;
        string etc_group;
        if (passwd_file_type == FT_REG_FILE)
            etc_passwd = _get_file_contents(passwd_index, inodes, data);
        if (group_file_type == FT_REG_FILE)
            etc_group = _get_file_contents(group_index, inodes, data);
        string prev_entry;
        UserEvent ue;
        (ue, errors) = _userdel(flags, args, users, groups);

        if (errors.empty()) {
            (uint8 et, uint16 user_id, uint16 group_id, /*uint16 options*/, string user_name, string group_name, ) = ue.unpack();
            string text;
            if (et == UA_ADD_USER) {
                text = format("{}\t{}\t{}\t{}\t/home/{}\n", user_name, user_id, group_id, group_name, user_name);
                ars.push(Ar(et, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", text));
            } else if (et == UA_ADD_GROUP) {
                text = format("{}\t{}\n", group_name, group_id);
                ars.push(Ar(et, FT_REG_FILE, group_index, group_dir_idx, "group", text));
            } else if (et == UA_DELETE_GROUP) {
                text = format("{}\t{}\n", group_name, group_id);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", _translate(etc_group, text, "")));
            } else if (et == UA_DELETE_USER) {
                text = format("{}\t{}\t{}\t{}\t/home/{}\n", user_name, user_id, group_id, group_name, user_name);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", _translate(etc_passwd, text, "")));
            } else if (et == UA_CHANGE_GROUP_ID) {
                text = format("{}\t{}\n", group_name, group_id);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", _translate(etc_group, prev_entry, text)));
            } else if (et == UA_RENAME_GROUP) {
                text = format("{}\t{}\n", group_name, group_id);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", _translate(etc_group, prev_entry, text)));
            } else if (et == UA_UPDATE_USER) {
                text = format("{}\t{}\t{}\t{}\t/home/{}\n", user_name, user_id, group_id, group_name, user_name);
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", _translate(etc_passwd, prev_entry, text)));
            }
            file_action = Action(et, 1);

        }
        out = out;
    }

    function _userdel(uint flags, string[] args, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups) private pure returns (UserEvent ue, Err[] errs) {
        bool force = (flags & _f) > 0;
        bool remove_home_dir = (flags & _r) > 0;

        string victim_user_name = args[0];
        uint16 victim_user_id;
        uint16 victim_group_id;
        uint16[] removed_groups;
        bool remove_empty_user_group;// = _login_def_flag(USERGROUPS_ENAB);

        uint16 options = remove_home_dir ? UAO_REMOVE_HOME_DIR : 0;
        options |= remove_empty_user_group ? UAO_REMOVE_EMPTY_GROUPS : 0;

        for ((uint16 user_id, UserInfo ui): users)
            if (ui.user_name == victim_user_name) {
                victim_user_id = user_id;
                victim_group_id = ui.gid;
                break;
            }

        if (victim_user_id == 0)
            errs.push(Err(E_NOTFOUND, 0, victim_user_name)); // specified user doesn't exist

        // TODO: check for a running process
        for ((uint16 gid, GroupInfo gi): groups)
            if (gi.group_name == victim_user_name) {
                if (force)
                    removed_groups.push(gid);
//                else
//                    errs.push(Err(8, 0, victim_user_name)); // can't remove user's primary group
            }
        if (errs.empty())
            ue = UserEvent(UA_DELETE_USER, victim_user_id, victim_group_id, options, victim_user_name, victim_user_name, removed_groups);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("userdel", "delete a user account and related files", "[options] LOGIN",
            "A low level utility for removing users.",
            "fr", 1, 1, [
            "force removal of files, even if not owned by user",
            "remove the user's home directory"]);
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
