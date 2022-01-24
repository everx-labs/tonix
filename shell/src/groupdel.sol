pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/uadmin.sol";

contract groupdel is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Action file_action, Ar[] ars, Err[] errors) {
        string etc_group = _get_file_contents_at_path("/etc/group", inodes, data);
        string etc_passwd = _get_file_contents_at_path("/etc/passwd", inodes, data);

        string victim_group_name = _val("_", args);
        string victim_entry = uadmin.group_entry_by_name(victim_group_name, etc_group);
        if (victim_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist

        (, uint16 victim_group_id, ) = uadmin.parse_group_entry_line(victim_entry);

        string active_uid_entry = uadmin.passwd_entry_by_primary_gid(victim_group_id, etc_passwd);
        if (!active_uid_entry.empty()) {
            (string user_name, , , ) = uadmin.parse_passwd_entry_line(active_uid_entry);
            errors.push(Err(8, 0, user_name)); // can't remove user's primary group
        }

        if (errors.empty()) {
            uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
            (uint16 group_index, , uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
            string text = format("{}\t{}\n", victim_group_name, victim_group_id);
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", _translate(etc_group, text, "")));
            file_action = Action(UA_DELETE_GROUP, 1);
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupdel",
"[options] GROUP",
"delete a group",
"Modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
"-f     delete group even if it is the primary group of a user",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
