pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract groupmod is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        (bool use_group_id, bool use_new_name, , , , , , ) = arg.flag_values("gn", flags);
        (, string etc_group, , uint16 etc_group_index) = fs.get_passwd_group(inodes, data);
        string cur_record;
        string new_record;

        if (use_group_id) {
            uint16 new_gid = str.toi(arg.opt_arg_value("g", args));
            string group_param = params[0];
            cur_record = uadmin.group_entry_by_name(group_param, etc_group);
            (string cur_group_name, , ) = uadmin.getgrnam(group_param, etc_group);
            if (cur_group_name.empty())
                errors.push(Err(uadmin.E_NOTFOUND, 0, group_param)); // specified group doesn't exist
            else {
                cur_record.append("\n");
                new_record = uadmin.group_entry_line(cur_group_name, new_gid);
            }
        } else if (use_new_name) {
            string new_name = arg.opt_arg_value("n", args);
            uint16 id_param = str.toi(params[0]);
            (string cur_group_name, uint16 cur_gid, ) = uadmin.getgrgid(id_param, etc_group);
            if (cur_group_name.empty())
                errors.push(Err(uadmin.E_NOTFOUND, 0, params[0])); // specified group doesn't exist
            else {
                cur_record = uadmin.group_entry_line(cur_group_name, cur_gid);
                new_record = uadmin.group_entry_line(new_name, cur_gid);
            }
        }

        if (!cur_record.empty() && !new_record.empty() && errors.empty())
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, etc_group_index, 0, "group", stdio.translate(etc_group, cur_record, new_record)));
        else
            ec = EXECUTE_FAILURE;
        out = "";
    }
        /*
            (string group_name, , ) = uadmin.getgrgid(new_gid, etc_group);
            if (group_name.empty())
                errors.push(Err(uadmin.E_NOTFOUND, 0, target_group_name)); // specified group doesn't exist

        string victim_entry = uadmin.group_entry_by_name(victim_group_name, etc_group);
        if (victim_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist

        (, uint16 victim_group_id, ) = uadmin.parse_group_entry_line(victim_entry);
        string active_uid_entry = uadmin.passwd_entry_by_primary_gid(victim_group_id, etc_passwd);
        if (!active_uid_entry.empty()) {
            (string user_name, , , , ) = uadmin.parse_passwd_entry_line(active_uid_entry);
            errors.push(Err(8, 0, user_name)); // can't remove user's primary group
        }

        if (errors.empty())
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, etc_group_index, 0, "group", stdio.translate(etc_group, victim_entry + "\n", "")));

        uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
        (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");

        string etc_group;
        if (group_file_type == FT_REG_FILE)
            etc_group = fs.get_file_contents(group_index, inodes, data);
        string prev_entry;

        uint n_args = params.length;
        string target_group_name = params[n_args - 1];
        uint16 new_group_id;
        string new_group_name;
        (string group_name, uint16 target_group_id, ) = uadmin.getgrnam(target_group_name, etc_group);
        if (group_name.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, target_group_name)); // specified group doesn't exist

        prev_entry = format("{}\t{}\n", target_group_name, target_group_id);

        if (use_group_id && n_args > 1) {
            string group_id_s = params[0];
            uint16 n_gid;
            optional(int) val = stoi(group_id_s);
            if (!val.hasValue())
                errors.push(Err(uadmin.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            (group_name, , ) = uadmin.getgrgid(n_gid, etc_group);
            if (!group_name.empty())
                errors.push(Err(uadmin.E_GID_IN_USE, 0, group_id_s));
            else
                new_group_id = n_gid;
        } else if (use_new_name && n_args > 1) {
            new_group_name = params[0];
            (group_name, , ) = uadmin.getgrnam(new_group_name, etc_group);
            if (!group_name.empty())
                errors.push(Err(uadmin.E_NAME_IN_USE, 0, new_group_name));
        }
        if (errors.empty()) {
            string text = format("{}\t{}\n", use_new_name ? new_group_name : target_group_name, new_group_id);
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, group_index, group_dir_idx, "group", stdio.translate(etc_group, prev_entry, text)));
        } else
            ec = EXECUTE_FAILURE;
        out = "";
    }*/

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupmod",
"[options] GROUP",
"modify a group definition on the system",
"Modifies the definition of the specified GROUP by modifying the appropriate entry in the group database.",
"-g     the group ID of the given GROUP will be changed to GID\n\
-n      the name of the group will be changed from GROUP to NEW_GROUP name",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
