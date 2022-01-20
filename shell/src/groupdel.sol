pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract groupdel is Utility, libuadm {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] params, , ) = _get_env(args);

        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        mapping (uint16 => GroupInfo) groups = _get_group_info(inodes, data);

        uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        string etc_group;
        if (group_file_type == FT_REG_FILE)
            etc_group = _get_file_contents(group_index, inodes, data);

        string victim_group_name = params[0];
        uint16 victim_group_id;
        uint16[] removed_groups;

        for ((uint16 group_id, GroupInfo gi): groups)
            if (gi.group_name == victim_group_name) {
                victim_group_id = group_id;
                removed_groups.push(victim_group_id);
            }

        if (victim_group_id == 0)
            errors.push(Err(E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist

        for ((, UserInfo ui): users)
            if (ui.primary_group == victim_group_name)
                errors.push(Err(8, 0, ui.user_name)); // can't remove user's primary group

        if (errors.empty()) {
            string text = format("{}\t{}\n", victim_group_name, victim_group_id);
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", _translate(etc_group, text, "")));
            file_action = Action(UA_DELETE_GROUP, 1);
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("groupdel", "delete a group", "[options] GROUP",
            "Modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
            "f", 1, 1, ["delete group even if it is the primary group of a user"]);
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
