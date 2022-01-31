pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract utmpdump is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , , string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        bool write_back = arg.flag_set("r", flags);
        string[][] table;
        Column[] columns_format = [
            Column(true, 5, fmt.ALIGN_LEFT),
            Column(true, 7, fmt.ALIGN_LEFT),
            Column(true, 7, fmt.ALIGN_LEFT),
            Column(!write_back, 5, fmt.ALIGN_LEFT),
            Column(true, 30, fmt.ALIGN_LEFT)];

        uint16 var_log_dir = fs.resolve_absolute_path("/var/log", inodes, data);
        (uint16 wtmp_index, uint8 wtmp_file_type) = fs.lookup_dir(inodes[var_log_dir], data[var_log_dir], "wtmp");
        string wtmp_contents;
        if (wtmp_file_type == FT_REG_FILE)
            wtmp_contents = fs.get_file_contents(wtmp_index, inodes, data);
        LoginEvent[] wtmp;

        uint16 var_run_dir = fs.resolve_absolute_path("/var/run", inodes, data);
        (uint16 utmp_index, uint8 utmp_file_type) = fs.lookup_dir(inodes[var_run_dir], data[var_run_dir], "utmp");
        string utmp_contents;
        if (utmp_file_type == FT_REG_FILE)
            utmp_contents = fs.get_file_contents(utmp_index, inodes, data);
//        mapping (uint16 => Login) utmp;

        if (write_back)
            for (LoginEvent le: wtmp) {
                (uint8 letype, uint16 user_id, uint16 tty_id, , uint32 timestamp) = le.unpack();
                table.push([str.toa(letype), str.toa(user_id), str.toa(tty_id), fmt.ts(timestamp)]);
            }
        out = fmt.format_table_ext(columns_format, table, " ", "\n");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"utmpdump",
"[options] [filename]",
"dump UTMP and WTMP files in raw format",
"Dump UTMP and WTMP files in raw format, so they can be examined.",
"-r      write back dumped data into utmp file\n\
-o      write to file instead of standard output",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
