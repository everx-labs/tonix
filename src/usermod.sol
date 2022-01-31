pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract usermod is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        (bool change_primary_group, /*bool supp_groups_list*/, , , , , , ) = arg.flag_values("gG", flags);
        string param_user_name = change_primary_group ? params[0] : "";

        (string etc_passwd, string etc_group, uint16 etc_passwd_index, ) = fs.get_passwd_group(inodes, data);
        string cur_entry = uadmin.passwd_entry_by_name(param_user_name, etc_passwd);
        string new_entry;
        if (cur_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, param_user_name)); // specified user doesn't exist
        else {
            if (change_primary_group && !params.empty()) {
                string param_new_gid_s = arg.opt_arg_value("g", args);
                uint16 new_gid = str.toi(param_new_gid_s);
                string group_name = uadmin.group_name_by_id(new_gid, etc_group);
                if (group_name.empty())
                    errors.push(Err(uadmin.E_NOTFOUND, 0, param_new_gid_s)); // specified group doesn't exist
                else {
                    (string cur_user_name, uint16 cur_uid, , string cur_primary_group, ) = uadmin.parse_passwd_entry_line(cur_entry);
                    cur_entry.append("\n");
                    new_entry = uadmin.passwd_entry_line(cur_user_name, cur_uid, new_gid, cur_primary_group);
                }
            }
        }

        if (!cur_entry.empty() && !new_entry.empty() && errors.empty())
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, etc_passwd_index, 0, "passwd", stdio.translate(etc_passwd, cur_entry, new_entry)));
        else
            ec = EXECUTE_FAILURE;
        out = "";

        /*uint n_args = params.length;
        uint16 user_id;
        uint16 group_id;
        string group_name;
        uint16[] group_list;
        string new_entry;

        } else if (supp_groups_list && n_args > 1) {
            string supp_string = params[0];
            (string[] supp_list, ) = stdio.split(supp_string, ",");
            for (string s: supp_list) {
                string g_line = uadmin.group_entry_by_name(s, etc_group);
                if (!g_line.empty()) {
                    (, uint16 gid_found, ) = uadmin.parse_group_entry_line(g_line);
                    group_list.push(gid_found);
                } else
                    errors.push(Err(uadmin.E_NOTFOUND, 0, s));
            }
        }
        if (errors.empty()) {
            string text = format("{}\t{}\t{}\t{}\t/home/{}\n", user_name, user_id, group_id, group_name, user_name);
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, passwd_index, passwd_dir_idx, "passwd", stdio.translate(etc_passwd, prev_entry, text)));
        } else
            ec = EXECUTE_FAILURE;
        out = "";*/
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"usermod",
"[options] LOGIN",
"modify a user account",
"Modifies the system account files to reflect the changes that are specified on the command line.",
"-a      add the user to the supplementary groups mentioned by the -G option\n\
-g      force use GROUP as new primary group\n\
-G      a list of supplementary groups separated from the next by a comma",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
