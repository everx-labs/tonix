pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract groupadd is Utility, libuadm {

    function uadm(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();

        mapping (uint16 => GroupInfo) groups = _get_group_info(inodes, data);

        session.pid = session.pid;
        out = out;
        UserEvent ue;
        (ue, file_action, ars, errors) = _groupadd(flags, args, inodes, data, groups);
    }

    function _groupadd(uint flags, string[] args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, mapping (uint16 => GroupInfo) groups) private pure returns (UserEvent ue, Action file_action, Ar[] ars, Err[] errs) {
        bool force = (flags & _f) > 0;
        bool use_group_id = (flags & _g) > 0;
        bool is_system_group = (flags & _r) > 0;

        uint n_args = args.length;
        string target_group_name = args[n_args - 1];
        uint16 target_group_id;
        uint16 options = is_system_group ? UAO_SYSTEM : 0;
        uint16[] added_groups;

        for ((, GroupInfo gi): groups)
            if (gi.group_name == target_group_name)
                errs.push(Err(E_NAME_IN_USE, 0, target_group_name));

        if (use_group_id && n_args > 1) {
            string group_id_s = args[0];
            optional(int) val = stoi(group_id_s);
            uint16 n_gid;
            if (!val.hasValue())
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            target_group_id = uint16(n_gid);
            if (groups.exists(target_group_id))
                if (force)
                    target_group_id = 0;
                else
                    errs.push(Err(E_GID_IN_USE, 0, group_id_s));
        }

        (, , uint16 reg_groups_counter, uint16 sys_groups_counter) = _get_counters(inodes, data);
        if (target_group_id == 0)
            target_group_id = is_system_group ? sys_groups_counter++ : reg_groups_counter++;

        if (errs.empty())
            ue = UserEvent(UA_ADD_GROUP, target_group_id, target_group_id, options, target_group_name, target_group_name, added_groups);

        uint16 etc_dir = _resolve_absolute_path("/etc", inodes, data);
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = _lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        string etc_group;
        if (group_file_type == FT_REG_FILE)
            etc_group = _get_file_contents(group_index, inodes, data);
        if (errs.empty()) {
            string text = _group_entry_line(target_group_name, target_group_id);
            if (group_file_type == FT_UNKNOWN) {
                uint16 ic = _get_inode_count(inodes);
                ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "group", text));
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", _dir_entry_line(ic, "group", FT_REG_FILE)));
            } else
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", etc_group + text));
            file_action = Action(UA_ADD_GROUP, 1);
        }

    }


    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("groupadd", "create a new group", "[options] group",
            "Creates a new group account using the default values from the system.",
            "fgr", 1, M, [
            "exit successfully if the group already exists, and cancel -g if the GID is already used",
            "use GID for the new group",
            "create a system group"]);
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
