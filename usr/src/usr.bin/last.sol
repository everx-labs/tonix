pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";

contract last is putil_stat {

    uint8 constant AE_LOGIN         = 1;
    uint8 constant AE_LOGOUT        = 2;
    uint8 constant AE_SHUTDOWN      = 3;

    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;

        uint16 var_log_dir = fs.resolve_absolute_path("/var/log", inodes, data);
        (uint16 wtmp_index, uint8 wtmp_file_type) = fs.lookup_dir(inodes[var_log_dir], data[var_log_dir], "wtmp");
        string wtmp_contents;
        if (wtmp_file_type == ft.FT_REG_FILE)
            wtmp_contents = fs.get_file_contents(wtmp_index, inodes, data);

        string[][] table;

        Column[] columns_format = [
            Column(true, 15, fmt.LEFT), // Name
            Column(true, 7, fmt.LEFT),
            Column(true, 30, fmt.LEFT),
            Column(true, 30, fmt.LEFT)];

//        mapping (uint16 => uint32) log_ts;
        /*LoginEvent[] wtmp;

        for (LoginEvent le: wtmp) {
            (uint8 letype, uint16 user_id, uint16 tty_id, , uint32 timestamp) = le.unpack();
            string ui_user_name = user[user_id];
            if (letype == AE_LOGIN)
                log_ts[tty_id] = timestamp;
            if (letype == AE_LOGOUT) {
                uint32 login_ts = log_ts[tty_id];
                table.push([
                    ui_user_name,
                    str.toa(tty_id),
                    fmt.ts(login_ts),
                    fmt.ts(timestamp)]);
            }
            if (letype != AE_SHUTDOWN || shutdown_entries)
                table.push([
                    ui_user_name,
                    str.toa(tty_id),
                    str.toa(user_id),
                    fmt.ts(timestamp)]);
        }*/

        e.puts(fmt.format_table_ext(columns_format, table, " ", "\n"));
        e.puts("wtmp begins Mon Mar 22 23:44:55 2021");
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
"0.02");
    }
}
