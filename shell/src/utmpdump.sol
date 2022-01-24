pragma ton-solidity >= 0.53.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract utmpdump is Utility, libuadm {

    function ustat(Session /*session*/, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, , uint flags) = input.unpack();

        bool write_back = (flags & _r) > 0;
//        bool write_to_file = (flags & _o) > 0;
        string[][] table;
        Column[] columns_format = [
            Column(true, 5, fmt.ALIGN_LEFT),
            Column(true, 7, fmt.ALIGN_LEFT),
            Column(true, 7, fmt.ALIGN_LEFT),
            Column(!write_back, 5, fmt.ALIGN_LEFT),
            Column(true, 30, fmt.ALIGN_LEFT)];

        uint16 var_log_dir = _resolve_absolute_path("/var/log", inodes, data);
        (uint16 wtmp_index, uint8 wtmp_file_type) = _lookup_dir(inodes[var_log_dir], data[var_log_dir], "wtmp");
        string wtmp_contents;
        if (wtmp_file_type == FT_REG_FILE)
            wtmp_contents = _get_file_contents(wtmp_index, inodes, data);
        LoginEvent[] wtmp;

        uint16 var_run_dir = _resolve_absolute_path("/var/run", inodes, data);
        (uint16 utmp_index, uint8 utmp_file_type) = _lookup_dir(inodes[var_run_dir], data[var_run_dir], "utmp");
        string utmp_contents;
        if (utmp_file_type == FT_REG_FILE)
            utmp_contents = _get_file_contents(utmp_index, inodes, data);
//        mapping (uint16 => Login) utmp;

        if (write_back)
            for (LoginEvent le: wtmp) {
                (uint8 letype, uint16 user_id, uint16 tty_id, , uint32 timestamp) = le.unpack();
                table.push([stdio.itoa(letype), stdio.itoa(user_id), stdio.itoa(tty_id), fmt.ts(timestamp)]);
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
