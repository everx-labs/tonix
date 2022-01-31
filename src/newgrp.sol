pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract newgrp is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        out = "";
        ec = EXECUTE_SUCCESS;
        (bool force, bool use_group_id, bool is_system_group, , , , , ) = arg.flag_values("fgr", flags);

        string etc_group = fs.get_file_contents_at_path("/etc/group", inodes, data);

        uint n_args = params.length;
        string target_group_name = params[n_args - 1];
        uint16 target_group_id;

        string g_line = uadmin.group_entry_by_name(target_group_name, etc_group);
        if (!g_line.empty()) {
                errors.push(Err(uadmin.E_NAME_IN_USE, 0, target_group_name));
        }
        if (use_group_id && n_args > 1) {
            string group_id_s = params[0];
            optional(int) val = stoi(group_id_s);
            uint16 n_gid;
            if (!val.hasValue())
                errors.push(Err(uadmin.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            target_group_id = uint16(n_gid);
            if (!uadmin.group_name_by_id(target_group_id, etc_group).empty())
                errors.push(Err(uadmin.E_GID_IN_USE, 0, group_id_s));
                if (force)
                    target_group_id = 0;
                else
                    errors.push(Err(uadmin.E_GID_IN_USE, 0, group_id_s));
        }

        (, , uint16 reg_groups_counter, uint16 sys_groups_counter) = uadmin.get_counters(etc_group);
        if (target_group_id == 0)
            target_group_id = is_system_group ? sys_groups_counter++ : reg_groups_counter++;

        uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
        if (errors.empty()) {
            string text = uadmin.group_entry_line(target_group_name, target_group_id);
            if (group_file_type == FT_UNKNOWN) {
                uint16 ic = sb.get_inode_count(inodes);
                ars.push(Ar(IO_MKFILE, FT_REG_FILE, ic, etc_dir, "group", text));
                ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, etc_dir, 1, "", dirent.dir_entry_line(ic, "group", FT_REG_FILE)));
            } else
                ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", etc_group + text));
        }

    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"newgrp",
"[-] [group]",
"log in to a new group",
"Change the current group ID during a login session.",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
