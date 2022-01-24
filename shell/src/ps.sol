pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract ps is Utility, libuadm {

    function ustat(Session /*session*/, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, , uint flags) = input.unpack();
        bool last_boot_time = (flags & _b) > 0;
        bool print_headings = (flags & _H) > 0;
        bool system_login_proc = (flags & _l) > 0;
        bool all_logged_on = (flags & _q) > 0;
        bool default_format = (flags & _s) > 0;
//        bool dead_processes = (flags & _d) > 0;
//        bool init_spawned_proc = (flags & _p) > 0;
//        bool all_fields = (flags & _a) > 0;
//      bool last_clock_change = (flags & _t) > 0;
        bool user_message_status = (flags & _T + _w) > 0;
        bool users_logged_in = (flags & _u) > 0;
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        mapping (uint16 => Login) utmp;

        if (all_logged_on) {
            uint count;
            for ((, Login l): utmp) {
                uint16 user_id = l.user_id;
                if (system_login_proc && user_id > _login_def_value(SYS_UID_MAX))
                    continue;
                out.append(users[user_id].user_name + "\t");
                count++;
            }
            out.append(format("\n# users = {}\n", count));
            return out;
        }

        string[][] table;
        if (print_headings)
            table = [["NAME", "S", "LINE", "TIME", "PID"]];

        if (last_boot_time)
            table.push(["reboot", " ", "~", fmt.ts(now), "1"]);
        Column[] columns_format = [
            Column(true, 15, ALIGN_LEFT), // Name
            Column(user_message_status, 1, ALIGN_LEFT),
            Column(true, 7, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT),
            Column(!default_format || users_logged_in, 5, ALIGN_RIGHT)];
        for ((, Login l): utmp) {
            (uint16 user_id, uint16 tty_id, uint16 process_id, uint32 login_time) = l.unpack();
//            if (system_login_proc && user_id > _login_defs_uint16[SYS_UID_MAX])
            if (system_login_proc && user_id > _login_def_value(SYS_UID_MAX))
                continue;
            (, string ui_user_name, ) = users[user_id].unpack();
            table.push([ui_user_name, "+", stdio.itoa(tty_id), fmt.ts(login_time), stdio.itoa(process_id)]);
        }

        out = fmt.format_table_ext(columns_format, table, " ", "\n");
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
"0.01");
    }

}
