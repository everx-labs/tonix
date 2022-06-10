pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "../lib/pw.sol";
import "../lib/gr.sol";
import "../lib/adm.sol";

contract useradd is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        string out;
        Ar[] ars;
        Err[] errors;

        if (params.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            out = libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
        }
        (string etc_passwd, string etc_group, , ) = fs.get_passwd_group(inodes, data);

        bool create_user_group_def = adm.login_def_flag(adm.USERGROUPS_ENAB);
        bool create_home_dir_def = adm.login_def_flag(adm.CREATE_HOME);

        (bool is_system_account, bool create_home_flag, bool do_not_create_home_flag, bool create_user_group_flag, bool do_not_create_user_group_flag,
            bool use_user_id, bool use_group_id, bool supp_groups_list) = p.flag_values("rmMUNugG");

        bool create_home_dir = (create_home_dir_def || create_home_flag) && !do_not_create_home_flag;
        bool create_user_group = (create_user_group_def || create_user_group_flag) && !do_not_create_user_group_flag;

        uint n_args = params.length;
        string user_name = params[n_args - 1];
        uint16 group_id;
        uint16 user_id;
        uint16[] new_group_ids;

        (string line, s_passwd res) = pw.getnam(user_name, etc_passwd);
        if (!line.empty())
            errors.push(Err(er.E_NAME_IN_USE, 0, user_name));

        if (use_group_id && n_args > 1) {
            string group_id_s = params[0];
            optional(int) val = stoi(group_id_s);
            uint16 n_gid;
            if (!val.hasValue())
                errors.push(Err(er.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            group_id = uint16(n_gid);
            (string group_line, ) = gr.getgid(group_id, etc_group);
            if (group_line.empty())
                errors.push(Err(er.E_NOTFOUND, 0, group_id_s)); // specified group doesn't exist
            else
                new_group_ids = [group_id];
        } else if (use_user_id && n_args > 1) {
            string user_id_s = params[0];
            optional(int) val = stoi(user_id_s);
            if (!val.hasValue())
                errors.push(Err(er.E_BAD_ARG, 0, user_id_s)); // invalid argument to option
            else
                user_id = uint16(val.get());
                (line, res) = pw.getuid(user_id, etc_passwd);
                if (!line.empty())
                    errors.push(Err(er.E_GID_IN_USE, 0, user_id_s)); // UID already in use (and no -o)
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = params[0];
            (string[] supp_list, ) = supp_string.split(",");
            for (string s: supp_list) {
                (string g_line, s_group grp) = gr.getnam(s, etc_group);
                if (!g_line.empty()) {
                    uint16 gid_found = grp.gr_gid;
                    new_group_ids.push(gid_found);
                } else
                    errors.push(Err(er.E_NOTFOUND, 0, s));
            }
        }

        (uint16 reg_users_counter, uint16 sys_users_counter, uint16 reg_groups_counter, uint16 sys_groups_counter) = adm.get_counters(etc_passwd);
        if (user_id == 0)
            user_id = is_system_account ? sys_users_counter++ : reg_users_counter++;

        if (create_user_group) {
            if (group_id == 0)
                group_id = is_system_account ? sys_groups_counter++ : reg_groups_counter++;
        } else {
//            if (group_id == 0)
//                group_id = is_system_account ? _login_defs_uint16[SYS_GID_MIN] : _login_defs_uint16[GID_MIN];
        }
        if (errors.empty()) {
            string text;
            uint16 n_files;
            uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
            (uint16 passwd_index, uint8 passwd_file_type, uint16 passwd_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "passwd");
            (uint16 group_index, uint8 group_file_type, uint16 group_dir_idx) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
            uint16 ic = sb.get_inode_count(inodes);

            if (create_home_dir) {
                uint16 home_dir = fs.resolve_absolute_path("/home", inodes, data);
                ars.push(Ar(aio.MKDIR, ic, user_name, inode.get_dots(ic, home_dir)));
                ic++;
            }

            text = pw.putent(s_passwd(user_name, user_id, group_id, user_name, "/home/" + user_name, "./eilish"), etc_passwd);
            if (passwd_file_type == ft.FT_UNKNOWN || passwd_dir_idx == 0) {
                ars.push(Ar(aio.MKFILE, ic, "passwd", text));
                ars.push(Ar(aio.ADD_DIR_ENTRY, etc_dir, "", udirent.dir_entry_line(ic, "passwd", ft.FT_REG_FILE)));
                ic++;
                n_files++;
            } else
                ars.push(Ar(aio.UPDATE_TEXT_DATA, passwd_index, "passwd", text));

            if (create_user_group) {
                string[] empty;
                string group_text = gr.putent(s_group(user_name, group_id, empty), etc_group);
                if (group_file_type == ft.FT_UNKNOWN || group_dir_idx == 0) {
                    ars.push(Ar(aio.MKFILE, ic, "group", group_text));
                    ars.push(Ar(aio.ADD_DIR_ENTRY, etc_dir, "", udirent.dir_entry_line(ic, "group", ft.FT_REG_FILE)));
                    ic++;
                    n_files++;
                } else
                    ars.push(Ar(aio.UPDATE_TEXT_DATA, group_index, "group", group_text));
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"useradd",
"[options] LOGIN",
"create a new user or update default new user information",
"A low level utility for adding users.",
"-g      name or ID of the primary group of the new account\n\
-G      a list of supplementary groups which the user is also a member of\n\
-l      do not add the user to the lastlog and faillog databases\n\
-m      create the user's home directory\n\
-M      do no create the user's home directory\n\
-N      do not create a group with the same name as the user\n\
-r      create a system account\n\
-U      create a group with the same name as the user",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
