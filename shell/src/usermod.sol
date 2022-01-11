pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract usermod is Utility, libuadm {

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
        (ue, errors, prev_entry) = _usermod(flags, args, users, groups);

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

    function _usermod(uint flags, string[] args, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups) private pure returns (UserEvent ue, Err[] errs, string prev_entry) {
//        bool append_to_supp_groups = (flags & _a) > 0;
        bool change_primary_group = (flags & _g) > 0;
        bool supp_groups_list = (flags & _G) > 0;

        uint n_args = args.length;
        string user_name = args[n_args - 1];
        uint16 user_id;
        uint16 options;
        uint16 group_id;
        string group_name;
        uint16[] group_list;

        for ((uint16 uid, UserInfo ui): users)
            if (ui.user_name == user_name) {
                user_id = uid;
                break;
            }

        if (user_id == 0)
            errs.push(Err(E_NOTFOUND, 0, user_name)); // specified user doesn't exist

        prev_entry = format("{}\t{}\t{}\t{}\t/home/{}", user_name, user_id, users[user_id].gid, users[user_id].primary_group, user_name);
        if (change_primary_group && n_args > 1) {
            string group_id_s = args[0];
            optional(int) val = stoi(group_id_s);
            if (!val.hasValue())
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                group_id = uint16(val.get());
            if (!groups.exists(group_id))
                errs.push(Err(E_NOTFOUND, 0, group_id_s)); // specified group doesn't exist
            group_name = groups[group_id].group_name;
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = args[0];
            (string[] supp_list, ) = _split(supp_string, ",");
            for (string s: supp_list) {
                uint16 gid_found = 0;
                for ((uint16 gid, GroupInfo gi): groups)
                    if (gi.group_name == s)
                        gid_found = gid;
                if (gid_found > 0)
                    group_list.push(gid_found);
                else
                    errs.push(Err(E_NOTFOUND, 0, s));
            }
        }
        if (errs.empty())
            ue = UserEvent(UA_UPDATE_USER, user_id, group_id, options, user_name, group_name, group_list);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("usermod", "modify a user account", "[options] LOGIN",
            "Modifies the system account files to reflect the changes that are specified on the command line.",
            "agG", 1, M, [
            "add the user to the supplementary groups mentioned by the -G option",
            "force use GROUP as new primary group",
            "a list of supplementary groups separated from the next by a comma"]);
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
