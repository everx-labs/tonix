pragma ton-solidity >= 0.61.0;

import "adm.sol";
import "gr.sol";
import "unistd.sol";
import "putil.sol";

contract lslogins is putil {

    using unistd for s_proc;

    function _main(p_env e_in, s_proc p) internal pure override returns (p_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = p.params();
        (bool flag_system, bool flag_user, bool colon, bool newline, bool raw, bool nulll, , ) = p.flag_values("sucnrz");
        bool print_system = flag_system || !flag_user;
        bool print_user = !flag_system || flag_user;
        string field_separator;
        uint16 uid = p.getuid();

        if (colon)
            field_separator = ":";
        field_separator.aif(newline, "\n");
        field_separator.aif(raw, " ");
        field_separator.aif(nulll, "\x00");
        if (field_separator.strlen() > 1) {
            p.perror("mutually exclusive arguments: -c -n -r -z");
            return e;
        }
        bool formatted_table = field_separator.empty();
        bool print_all = (print_system || print_user) && params.empty();

        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GECOS", "HOMEDIR", "SHELL", "GID", "GROUP"]];
        Column[] columns_format = print_all ? [Column(print_all, 5, fmt.LEFT), Column(print_all, 10, fmt.LEFT),
            Column(print_all, 15, fmt.LEFT), Column(print_all, 15, fmt.LEFT), Column(print_all, 15, fmt.LEFT),
            Column(print_all, 5, fmt.LEFT), Column(print_all, 10, fmt.LEFT)] :
            [Column(!print_all, 15, fmt.LEFT), Column(!print_all, 20, fmt.LEFT)];

        if (params.empty() && uid < pw.GUEST_USER) {
            s_of f = p.fopen("/etc/passwd", "r");
            while (!f.feof()) {
                string line = f.getline();
                (string pw_name, uint16 pw_uid, uint16 pw_gid, string pw_gecos, string pw_dir, string pw_shell) = pw.parse_passwd_record(line).unpack();
                table.push([str.toa(pw_uid), pw_name, pw_gecos, pw_dir, pw_shell, str.toa(pw_gid), pw_name]);
            }
        } else {
            string user_name = params[0];
            s_of f = p.fopen("/etc/passwd", "r");
            string etc_passwd;
            while (!f.feof()) {
                string line_in = f.getline();
                etc_passwd.append(line_in);
            }
            (string line, s_passwd entry) = pw.getnam(user_name, etc_passwd);
            if (!line.empty()) {
                (string pw_name, uint16 pw_uid, uint16 pw_gid, string pw_gecos, string pw_dir, string pw_shell) = entry.unpack();
                table = [["Username:", pw_name], ["UID:", str.toa(pw_uid)], ["Gecos field:", pw_gecos], ["Home directory:", pw_dir],
                    ["Shell:", pw_shell], ["Home directory:", pw_dir], ["Primary group:", pw_name], ["GID:", str.toa(pw_gid)]];
            }
        }
        res.fputs(fmt.format_table_ext(columns_format, table, field_separator, "\n"));
        e.ofiles[libfdt.STDOUT_FILENO] = res;
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
