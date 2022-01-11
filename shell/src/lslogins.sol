pragma ton-solidity >= 0.53.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract lslogins is Utility, libuadm {

    function ustat(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
//    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, string[] args, uint flags) = input.unpack();
        (out, ) = _lslogins(flags, args, session, inodes, data);
    }

    function _lslogins(uint flags, string[] args, Session session, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        bool print_system = (flags & _s) > 0 || (flags & _u) == 0;
        bool print_user = (flags & _u) > 0 || (flags & _s) == 0;
        string field_separator;
        if ((flags & _c) > 0)
            field_separator = ":";
        field_separator = _if(field_separator, (flags & _n) > 0, "\n");
        field_separator = _if(field_separator, (flags & _r) > 0, " ");
        field_separator = _if(field_separator, (flags & _z) > 0, "\x00");
        if (field_separator.byteLength() > 1)
            return ("Mutually exclusive options\n", [Err(0, mutually_exclusive_options, "")]);
        bool formatted_table = field_separator.empty();
        bool print_all = (print_system || print_user) && args.empty();

        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GID", "GROUP"]];
        Column[] columns_format = print_all ? [
                Column(print_all, 5, ALIGN_LEFT),
                Column(print_all, 10, ALIGN_LEFT),
                Column(print_all, 5, ALIGN_LEFT),
                Column(print_all, 10, ALIGN_LEFT)] :
               [Column(!print_all, 15, ALIGN_LEFT),
                Column(!print_all, 20, ALIGN_LEFT)];
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);

        if (args.empty() && session.uid < GUEST_USER) {
            for ((uint16 uid, UserInfo user_info): users) {
                (uint16 gid, string s_owner, string s_group) = user_info.unpack();
                    table.push([format("{}", uid), s_owner, format("{}", gid), s_group]);
            }
        } else {
            string user_name = args[0];
            for ((uint16 uid, UserInfo user_info): users)
                if (user_info.user_name == user_name) {
                    (uint16 gid, , string s_group) = user_info.unpack();
                    string home_dir = "/home/" + user_name;
                    table = [
                        ["Username:", user_name],
                        ["UID:", format("{}", uid)],
                        ["Home directory:", home_dir],
                        ["Primary group:", s_group],
                        ["GID:", format("{}", gid)]];
                    break;
                }
        }
        out = _format_table_ext(columns_format, table, field_separator, "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("lslogins", "display information about known users in the system", "[options] [-s] [username]",
            "Examine the wtmp and btmp logs, /etc/shadow (if necessary) and /etc/passwd and output the desired data.",
            "cenrsuz", 0, 1, [
            "display data in a format similar to /etc/passwd",
            "display in an export-able output format",
            "display each piece of information on a new line",
            "display in raw mode",
            "display system accounts",
            "display user accounts",
            "delimit user entries with a nul character"]);
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
