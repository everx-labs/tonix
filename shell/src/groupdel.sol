pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract groupdel is Utility, libuadm {

    function uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _uadm(session, input, inodes, data);
    }

    function _uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, ) = input.unpack();

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

        (ue, errors) = _groupdel(args, users, groups);

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

    function _groupdel(string[] args, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups) private pure returns (UserEvent ue, Err[] errs) {
        string victim_group_name = args[0];
        uint16 victim_group_id;
        uint16 options;
        uint16[] removed_groups;

        for ((uint16 group_id, GroupInfo gi): groups)
            if (gi.group_name == victim_group_name) {
                victim_group_id = group_id;
                removed_groups.push(victim_group_id);
            }

        if (victim_group_id == 0)
            errs.push(Err(E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist

        for ((, UserInfo ui): users)
            if (ui.primary_group == victim_group_name)
                errs.push(Err(8, 0, ui.user_name)); // can't remove user's primary group
        if (errs.empty() && !removed_groups.empty())
            ue = UserEvent(UA_DELETE_GROUP, victim_group_id, victim_group_id, options, victim_group_name, victim_group_name, removed_groups);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("groupdel", "delete a group", "[options] GROUP",
            "Modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
            "f", 1, 1, ["delete group even if it is the primary group of a user"]);
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
