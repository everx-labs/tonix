pragma ton-solidity >= 0.61.0;

import "putil.sol";
import "../lib/adm.sol";
import "../lib/sb.sol";

contract fuser is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;

        (bool last_boot_time, bool print_headings, bool system_login_proc, bool all_logged_on, bool default_format, bool user_message_status,
            , bool users_logged_in) = p.flag_values("bHlqsTwu");
        (mapping (uint16 => string) user, ) = p.get_users_groups();
        mapping (uint16 => Login) utmp;

        if (all_logged_on) {
            uint count;
            for ((, Login l): utmp) {
                uint16 user_id = l.user_id;
                if (system_login_proc && user_id > adm.login_def_value(adm.SYS_UID_MAX))
                    continue;
                string ui_user_name = user[user_id];
                p.puts(ui_user_name + "\t");
                count++;
            }
            p.puts(format("\n# users = {}", count));
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

        p.puts(fmt.format_table_ext(columns_format, table, " ", "\n"));
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
