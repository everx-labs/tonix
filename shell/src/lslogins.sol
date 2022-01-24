pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract lslogins is Utility, libuadm {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = _get_env(argv);
        ec = EXECUTE_SUCCESS;
        (bool flag_system, bool flag_user, bool colon, bool newline, bool raw, bool nulll, , ) = _flag_values("sucnrz", flags);
        bool print_system = flag_system || !flag_user;
        bool print_user = !flag_system || flag_user;
        string field_separator;
        uint16 uid = _atoi(_val("UID", argv));

        if (colon)
            field_separator = ":";
        field_separator = _if(field_separator, newline, "\n");
        field_separator = _if(field_separator, raw, " ");
        field_separator = _if(field_separator, nulll, "\x00");
        if (field_separator.byteLength() > 1)
            return (EXECUTE_FAILURE, "", "Mutually exclusive options\n");
        bool formatted_table = field_separator.empty();
        bool print_all = (print_system || print_user) && argv.empty();

        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GID", "GROUP"]];
        Column[] columns_format = print_all ? [
                Column(print_all, 5, ALIGN_LEFT), Column(print_all, 10, ALIGN_LEFT), Column(print_all, 5, ALIGN_LEFT), Column(print_all, 10, ALIGN_LEFT)] :
               [Column(!print_all, 15, ALIGN_LEFT), Column(!print_all, 20, ALIGN_LEFT)];
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);

        if (params.empty() && uid < GUEST_USER) {
            for ((uint16 t_uid, UserInfo user_info): users) {
                (uint16 t_gid, string s_owner, string s_group) = user_info.unpack();
                    table.push([_itoa(t_uid), s_owner, _itoa(t_gid), s_group]);
            }
        } else {
            string user_name = params[0];
            for ((uint16 t_uid, UserInfo user_info): users)
                if (user_info.user_name == user_name) {
                    (uint16 t_gid, , string s_group) = user_info.unpack();
                    string home_dir = "/home/" + user_name;
                    table = [
                        ["Username:", user_name],
                        ["UID:", _itoa(t_uid)],
                        ["Home directory:", home_dir],
                        ["Primary group:", s_group],
                        ["GID:", _itoa(t_gid)]];
                    break;
                }
        }
        out = _format_table_ext(columns_format, table, field_separator, "\n");
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
