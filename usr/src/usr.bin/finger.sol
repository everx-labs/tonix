pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "../lib/pw.sol";

contract finger is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, string flags, ) = arg.get_env(argv);

        bool flag_multi_line = arg.flag_set("l", flags);
        bool flag_short_format = arg.flag_set("s", flags);
        bool short_format = flag_short_format && !flag_multi_line;
        if (params.empty())
            out = "No one logged on.\n";
        else {
            string user_name = params[0];
            string[][] table;
            if (short_format)
                table = [["Login", "Tty", "Idle", "Login Time"]];
            (string etc_passwd, , , ) = fs.get_passwd_group(inodes, data);
            (string line, s_passwd res) = pw.getnam(user_name, etc_passwd);
            if (line.empty())
                return (EXECUTE_FAILURE, out, "finger: " + user_name + ": no such user\n");
            (string pw_name, , , string pw_gecos, string pw_dir, string pw_shell) = res.unpack();
            if (short_format)
                table.push([pw_name, "*", "*", "No logins"]);
            else
                table = [["Login: " + pw_name, "Directory: " + pw_dir],
                        ["Name: " + pw_gecos, "Shell: " + pw_shell]];
            out = fmt.format_table(table, " ", "\n", fmt.CENTER);
        }
        ec = EXECUTE_SUCCESS;
        err = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"finger",
"[-lms] [user ...]",
"user information lookup program",
"Displays information about the system users.",
"-l      produces a multi-line format displaying all of the information described for the -s option as well as the user's home directory\n\
-m      prevent matching of user names\n\
-s      displays the user's login name, write status and login time",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
