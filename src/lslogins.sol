pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract lslogins is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = arg.get_env(argv);
        (bool flag_system, bool flag_user, bool colon, bool newline, bool raw, bool nulll, , ) = arg.flag_values("sucnrz", flags);
        bool print_system = flag_system || !flag_user;
        bool print_user = !flag_system || flag_user;
        string field_separator;
        uint16 uid = vars.int_val("UID", argv);
        (string etc_passwd, , , ) = fs.get_passwd_group(inodes, data);

        if (colon)
            field_separator = ":";
        field_separator = str.aif(field_separator, newline, "\n");
        field_separator = str.aif(field_separator, raw, " ");
        field_separator = str.aif(field_separator, nulll, "\x00");
        if (field_separator.byteLength() > 1)
            return (EXECUTE_FAILURE, "", "Mutually exclusive options\n");
        bool formatted_table = field_separator.empty();
        bool print_all = (print_system || print_user) && params.empty();

        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GID", "GROUP"]];
        Column[] columns_format = print_all ? [
                Column(print_all, 5, fmt.ALIGN_LEFT), Column(print_all, 10, fmt.ALIGN_LEFT), Column(print_all, 5, fmt.ALIGN_LEFT), Column(print_all, 10, fmt.ALIGN_LEFT)] :
               [Column(!print_all, 15, fmt.ALIGN_LEFT), Column(!print_all, 20, fmt.ALIGN_LEFT)];

        if (params.empty() && uid < GUEST_USER) {
            (string[] lines, ) = stdio.split(etc_passwd, "\n");
            for (string line: lines) {
                (string s_owner, uint16 t_uid, uint16 t_gid, string s_group, ) = uadmin.parse_passwd_entry_line(line);
                table.push([str.toa(t_uid), s_owner, str.toa(t_gid), s_group]);
            }
        } else {
            string user_name = params[0];
            string line = uadmin.passwd_entry_by_name(user_name, etc_passwd);
            if (!line.empty()) {
                (, uint16 t_uid, uint16 t_gid, string group_name, string home_dir) = uadmin.parse_passwd_entry_line(line);
                    table = [
                        ["Username:", user_name],
                        ["UID:", str.toa(t_uid)],
                        ["Home directory:", home_dir],
                        ["Primary group:", group_name],
                        ["GID:", str.toa(t_gid)]];
                }
        }
        out = fmt.format_table_ext(columns_format, table, field_separator, "\n");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"lslogins",
"[options] [-s] [username]",
"display information about known users in the system",
"Examine the wtmp and btmp logs, /etc/shadow (if necessary) and /etc/passwd and output the desired data.",
"-c      display data in a format similar to /etc/passwd\n\
-e      display in an export-able output format\n\
-n      display each piece of information on a new line\n\
-r      display in raw mode\n\
-s      display system accounts\n\
-u      display user accounts\n\
-z      delimit user entries with a nul character",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
