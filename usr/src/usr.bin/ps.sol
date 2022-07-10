pragma ton-solidity >= 0.61.0;

import "putil.sol";
import "adm.sol";
import "unistd.sol";

contract ps is putil {

//    function _main(s_proc p_in) internal override pure returns (s_proc p) {
//        p = p_in;
    function _main(p_env e_in, s_proc p) internal pure override returns (p_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        (bool last_boot_time, bool print_headings, bool system_login_proc, bool all_logged_on,
            bool default_format, bool user_message_status, , bool users_logged_in) = p.flag_values("bHlqsTwu");
        mapping (uint16 => Login) utmp;

        (mapping (uint16 => string) user, ) = p.get_users_groups();

        if (all_logged_on) {
            uint count;
            for ((, Login l): utmp) {
                uint16 user_id = l.user_id;
                if (system_login_proc && user_id > adm.login_def_value(adm.SYS_UID_MAX))
                    continue;
                string ui_user_name = user[user_id];
                res.fputs(ui_user_name + "\t");
                count++;
            }
            res.fputs(format("\n# users = {}\n", count));
            e.ofiles[libfdt.STDOUT_FILENO] = res;
            return e;
        }

        string[][] table;
        if (print_headings)
            table = [["NAME", "S", "LINE", "TIME", "PID"]];

        if (last_boot_time)
            table.push(["reboot", " ", "~", fmt.ts(now), "1"]);
        Column[] columns_format = [
            Column(true, 15, fmt.LEFT),
            Column(user_message_status, 1, fmt.LEFT),
            Column(true, 7, fmt.LEFT),
            Column(true, 30, fmt.LEFT),
            Column(!default_format || users_logged_in, 5, fmt.RIGHT)];

        uint16 p_pid = unistd.getpid(p);
        for ((, Login l): utmp) {
            (uint16 user_id, uint16 tty_id, uint16 process_id, uint32 login_time) = l.unpack();
            if (system_login_proc && user_id > adm.login_def_value(adm.SYS_UID_MAX))
                continue;
            string ui_user_name = user[user_id];
            table.push([ui_user_name, "+", str.toa(tty_id), fmt.ts(login_time), str.toa(process_id)]);
        }

        res.fputs(fmt.format_table_ext(columns_format, table, " ", "\n"));
        res.fputs(format("\nPID: {}\n", p_pid));
        e.ofiles[libfdt.STDOUT_FILENO] = res;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"ps",
"[options]",
"report a snapshot of the current processes",
"Displays information about a selection of the active processes.",
"-e      select all processes\n\
-f      do full-format listing\n\
-F      extra full format",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
