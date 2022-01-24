pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/uadmin.sol";

contract finger is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, string flags, ) = arg.get_env(argv);

        bool flag_multi_line = arg.flag_set("l", flags);
//        bool no_names_matching = (flags & _m) > 0;
        bool flag_short_format = arg.flag_set("s", flags);
        bool short_format = flag_short_format && !flag_multi_line;
        if (params.empty())
            out = "No one logged on.";
        else {
            string user_name = params[0];
            string[][] table;
            if (short_format)
                table = [["Login", "Tty", "Idle", "Login Time"]];
            string etc_passwd = _get_file_contents_at_path("/etc/passwd", inodes, data);
            string line = uadmin.passwd_entry_by_name(user_name, etc_passwd);
            if (!line.empty())
                table.push(short_format ? [user_name, "*", "*", "No logins"] : ["Login: " + user_name, "Directory: /home/" + user_name]);
            /*mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
            for ((, UserInfo user_info): users)
                if (user_info.user_name == user_name)
                    table.push(short_format ? [user_name, "*", "*", "No logins"] : ["Login: " + user_name, "Directory: /home/" + user_name]);*/

            out = fmt.format_table(table, " ", "\n", fmt.ALIGN_CENTER);
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
