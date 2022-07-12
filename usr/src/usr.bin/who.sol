pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";
import "adm.sol";

contract who is putil_stat {

    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        (bool last_boot_time, bool print_headings, bool system_login_proc, bool all_logged_on, bool default_format, bool user_message_status,
            , bool users_logged_in) = e.flag_values("bHlqsTwu");
        (mapping (uint16 => string) user, ) = e.get_users_groups();
        uint16 var_run_dir = fs.resolve_absolute_path("/var/run", inodes, data);
        (uint16 utmp_index, uint8 utmp_file_type) = fs.lookup_dir(inodes[var_run_dir], data[var_run_dir], "utmp");
        string utmp_contents;
        if (utmp_file_type == ft.FT_REG_FILE)
            utmp_contents = fs.get_file_contents(utmp_index, inodes, data);
        mapping (uint16 => Login) utmp;

        if (all_logged_on) {
            uint count;
            for ((, Login l): utmp) {
                uint16 user_id = l.user_id;
                if (system_login_proc && user_id > adm.login_def_value(adm.SYS_UID_MAX))
                    continue;
                string ui_user_name = user[user_id];
                e.puts(ui_user_name + "\t");
                count++;
            }
            e.puts(format("\n# users={}", count));
        }

        string[][] table;
        if (print_headings)
            table = [["NAME", "S", "LINE", "TIME", "PID"]];

        if (last_boot_time)
            table.push(["reboot", " ", "~", fmt.ts(now), "1"]);
        Column[] columns_format = [
            Column(true, 15, fmt.LEFT), // Name
            Column(user_message_status, 1, fmt.LEFT),
            Column(true, 7, fmt.LEFT),
            Column(true, 30, fmt.LEFT),
            Column(!default_format || users_logged_in, 5, fmt.RIGHT)];
        for ((, Login l): utmp) {
            (uint16 user_id, uint16 tty_id, uint16 process_id, uint32 login_time) = l.unpack();
            if (system_login_proc && user_id > adm.login_def_value(adm.SYS_UID_MAX))
                continue;

            string ui_user_name = user[user_id];
            table.push([ui_user_name, "+", str.toa(tty_id), fmt.ts(login_time), str.toa(process_id)]);
        }
        e.puts(fmt.format_table_ext(columns_format, table, " ", "\n"));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"who",
"OPTION... [FILE]...",
"show who is logged on",
"Print information about users who are currently logged in.",
"-a      same as -b -d -l -p -r -t -T -u\n\
-b      time of last system boot\n\
-d      print dead processes\n\
-H      print line of column headings\n\
-l      print system login processes\n\
-p      print active processes spawned by init\n\
-q      all login names and number of users logged on\n\
-s      print only name, line, and time (default)\n\
-t      print last system clock change\n\
-T      \n\
-w      add user's message status as +, - or ?\n\
-u      list users logged in",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
