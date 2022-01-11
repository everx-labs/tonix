pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract groupmod is Utility, libuadm {

    function uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _uadm(session, input, inodes, data);
    }

    function _uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();

        session.pid = session.pid;
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
        (ue, errors, prev_entry) = _groupmod(flags, args, groups);
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

    function _groupmod(uint flags, string[] args, mapping (uint16 => GroupInfo) groups) private pure returns (UserEvent ue, Err[] errs, string prev_entry) {
        bool use_group_id = (flags & _g) > 0;
        bool use_new_name = (flags & _n) > 0;

        uint n_args = args.length;
        string target_group_name = args[n_args - 1];
        uint16 target_group_id;
        uint16 options;
        uint16 new_group_id;
        uint16[] new_group_ids;
        string new_group_name;
        for ((uint16 gid, GroupInfo gi): groups)
            if (gi.group_name == target_group_name) {
                target_group_id = gid;
                break;
            }

        if (target_group_id == 0)
            errs.push(Err(E_NOTFOUND, 0, target_group_name)); // specified group doesn't exist

        prev_entry = format("{}\t{}\n", target_group_name, target_group_id);

        if (use_group_id && n_args > 1) {
            string group_id_s = args[0];
            uint16 n_gid;
            optional(int) val = stoi(group_id_s);
            if (!val.hasValue())
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            if (groups.exists(n_gid))
                errs.push(Err(E_GID_IN_USE, 0, group_id_s)); // specified group doesn't exist
            else
                new_group_id = n_gid;
        } else if (use_new_name && n_args > 1) {
            new_group_name = args[0];
            for ((, GroupInfo gi): groups)
                if (gi.group_name == new_group_name)
                    errs.push(Err(E_NAME_IN_USE, 0, new_group_name));
        }
        if (errs.empty())
            ue = UserEvent(use_group_id ? UA_CHANGE_GROUP_ID : UA_RENAME_GROUP, target_group_id, new_group_id, options, target_group_name, use_new_name ? new_group_name : target_group_name, new_group_ids);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("groupmod", "modify a group definition on the system", "[options] GROUP",
            "Modifies the definition of the specified GROUP by modifying the appropriate entry in the group database.",
            "gn", 1, M, [
            "the group ID of the given GROUP will be changed to GID",
            "the name of the group will be changed from GROUP to NEW_GROUP name"]);
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
