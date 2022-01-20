pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract who is Utility, libuadm {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , , string flags, ) = _get_env(argv);
        ec = EXECUTE_SUCCESS;
        (bool last_boot_time, bool print_headings, bool system_login_proc, bool all_logged_on, bool default_format, bool user_message_status,
            , bool users_logged_in) = _flag_values("bHlqsTwu", flags);

//    function ustat(Session /*session*/, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
//        (, , uint flags) = input.unpack();
//        bool all_fields = (flags & _a) > 0;
        /*bool last_boot_time = (flags & _b) > 0;
//        bool dead_processes = (flags & _d) > 0;
        bool print_headings = (flags & _H) > 0;
        bool system_login_proc = (flags & _l) > 0;
//        bool init_spawned_proc = (flags & _p) > 0;
        bool all_logged_on = (flags & _q) > 0;
        bool default_format = (flags & _s) > 0;
  //      bool last_clock_change = (flags & _t) > 0;
        bool user_message_status = (flags & _T + _w) > 0;
        bool users_logged_in = (flags & _u) > 0;*/
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);

        uint16 var_run_dir = _resolve_absolute_path("/var/run", inodes, data);
        (uint16 utmp_index, uint8 utmp_file_type) = _lookup_dir(inodes[var_run_dir], data[var_run_dir], "utmp");
        string utmp_contents;
        if (utmp_file_type == FT_REG_FILE)
            utmp_contents = _get_file_contents(utmp_index, inodes, data);
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
            return (EXECUTE_SUCCESS, out, err);
        }

        string[][] table;
        if (print_headings)
            table = [["NAME", "S", "LINE", "TIME", "PID"]];

        if (last_boot_time)
            table.push(["reboot", " ", "~", _ts(now), "1"]);
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
            table.push([ui_user_name, "+", format("{}", tty_id), _ts(login_time), format("{}", process_id)]);
        }
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("who", "show who is logged on", "[OPTION]... [FILE]",
            "Print information about users who are currently logged in.",
            "abdHlpqstTwu", 0, 1, [
            "same as -b -d -l -p -r -t -T -u",
            "time of last system boot",
            "print dead processes",
            "print line of column headings",
            "print system login processes",
            "print active processes spawned by init",
            "all login names and number of users logged on",
            "print only name, line, and time (default)",
            "print last system clock change",
            "",
            "add user's message status as +, - or ?",
            "list users logged in"]);
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
"0.01");
    }

}
