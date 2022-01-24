pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract last is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , , string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;

//    function ustat(Session /*session*/, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
//        (, , uint flags) = input.unpack();
//        bool host_names = (flags & _a) > 0;
//        bool translate_address = (flags & _d) > 0;
//        bool full_dates = (flags & _F) > 0;
//        bool numeric_addresses = (flags & _i) > 0;
//        bool no_host_names = (flags & _R) > 0;
//        bool full_domain_names = (flags & _w) > 0;
//        bool shutdown_entries = (flags & _x) > 0;
        bool shutdown_entries = arg.flag_set("x", flags);
        string etc_passwd = _get_file_contents_at_path("/etc/passwd", inodes, data);

        uint16 var_log_dir = _resolve_absolute_path("/var/log", inodes, data);
        (uint16 wtmp_index, uint8 wtmp_file_type) = _lookup_dir(inodes[var_log_dir], data[var_log_dir], "wtmp");
        string wtmp_contents;
        if (wtmp_file_type == FT_REG_FILE)
            wtmp_contents = _get_file_contents(wtmp_index, inodes, data);

        string[][] table;

        Column[] columns_format = [
            Column(true, 15, fmt.ALIGN_LEFT), // Name
            Column(true, 7, fmt.ALIGN_LEFT),
            Column(true, 30, fmt.ALIGN_LEFT),
            Column(true, 30, fmt.ALIGN_LEFT)];

        mapping (uint16 => uint32) log_ts;
        LoginEvent[] wtmp;

        for (LoginEvent le: wtmp) {
            (uint8 letype, uint16 user_id, uint16 tty_id, , uint32 timestamp) = le.unpack();
            string line = uadmin.passwd_entry_by_uid(user_id, etc_passwd);
            string ui_user_name;
            if (!line.empty())
                (ui_user_name, , , ) = uadmin.parse_passwd_entry_line(line);

            if (letype == AE_LOGIN)
                log_ts[tty_id] = timestamp;
            if (letype == AE_LOGOUT) {
                uint32 login_ts = log_ts[tty_id];
                table.push([
                    ui_user_name,
                    stdio.itoa(tty_id),
                    fmt.ts(login_ts),
                    fmt.ts(timestamp)]);
            }
            if (letype != AE_SHUTDOWN || shutdown_entries)
                table.push([
                    ui_user_name,
                    stdio.itoa(tty_id),
                    stdio.itoa(user_id),
                    fmt.ts(timestamp)]);
        }

        out = fmt.format_table_ext(columns_format, table, " ", "\n");
        out.append("wtmp begins Mon Mar 22 23:44:55 2021\n");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"last",
"[options] [username...] [tty...]",
"show a listing of last logged in users",
"Searches back through the /var/log/wtmp file (or the file designated by the -f option) and displays a list of all users logged in (and out) since that file was created.",
"-a      display hostnames in the last column\n\
-d      translate the IP number back into a hostname\n\
-F      print full login and logout times and dates\n\
-i      display IP numbers in numbers-and-dots notation\n\
-R      don't display the hostname field\n\
-w      display full user and domain names\n\
-x      display system shutdown entries and run level changes",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
