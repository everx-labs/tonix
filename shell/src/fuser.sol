pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract fuser is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , , string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        (bool last_boot_time, bool print_headings, bool system_login_proc, bool all_logged_on, bool default_format, bool user_message_status,
            , bool users_logged_in) = arg.flag_values("bHlqsTwu", flags);
        string etc_passwd = _get_file_contents_at_path("/etc/passwd", inodes, data);

        mapping (uint16 => Login) utmp;

        if (all_logged_on) {
            uint count;
            for ((, Login l): utmp) {
                uint16 user_id = l.user_id;
                if (system_login_proc && user_id > uadmin.login_def_value(uadmin.SYS_UID_MAX))
                    continue;
                string line = uadmin.passwd_entry_by_uid(user_id, etc_passwd);
                string ui_user_name;
                if (!line.empty())
                    (ui_user_name, , , ) = uadmin.parse_passwd_entry_line(line);
                out.append(ui_user_name + "\t");
                count++;
            }
            out.append(format("\n# users = {}\n", count));
            return (EXECUTE_SUCCESS, out, err);
        }

        string[][] table;
        if (print_headings)
            table = [["NAME", "S", "LINE", "TIME", "PID"]];

        if (last_boot_time)
            table.push(["reboot", " ", "~", fmt.ts(now), "1"]);
        Column[] columns_format = [
            Column(true, 15, fmt.ALIGN_LEFT), // Name
            Column(user_message_status, 1, fmt.ALIGN_LEFT),
            Column(true, 7, fmt.ALIGN_LEFT),
            Column(true, 30, fmt.ALIGN_LEFT),
            Column(!default_format || users_logged_in, 5, fmt.ALIGN_RIGHT)];
        for ((, Login l): utmp) {
            (uint16 user_id, uint16 tty_id, uint16 process_id, uint32 login_time) = l.unpack();
            if (system_login_proc && user_id > uadmin.login_def_value(uadmin.SYS_UID_MAX))
                continue;
            string line = uadmin.passwd_entry_by_uid(user_id, etc_passwd);
            string ui_user_name;
            if (!line.empty())
                (ui_user_name, , , ) = uadmin.parse_passwd_entry_line(line);
            table.push([ui_user_name, "+", stdio.itoa(tty_id), fmt.ts(login_time), stdio.itoa(process_id)]);
        }

        out = fmt.format_table_ext(columns_format, table, " ", "\n");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"fuser",
"[-almsuv]",
"identify processes using files or sockets",
"Displays the PIDs of processes using the specified files or file systems.",
"-a      display unused files too\n\
-l      list available signal names\n\
-m      show all processes using the named filesystems or block device\n\
-s      silent operation\n\
-u      display user IDs\n\
-v      verbose output",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
