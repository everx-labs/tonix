pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract finger is Utility, libuadm {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, string flags, ) = _get_env(argv);

        bool flag_multi_line = _flag_set("l", flags);
//        bool no_names_matching = (flags & _m) > 0;
        bool flag_short_format = _flag_set("s", flags);
        bool short_format = flag_short_format && !flag_multi_line;
        if (params.empty())
            out = "No one logged on.";
        else {
            string user_name = params[0];
            string[][] table;
            if (short_format)
                table = [["Login", "Tty", "Idle", "Login Time"]];
            mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
            for ((, UserInfo user_info): users)
                if (user_info.user_name == user_name)
                    table.push(short_format ? [user_name, "*", "*", "No logins"] : ["Login: " + user_name, "Directory: /home/" + user_name]);

            out = _format_table(table, " ", "\n", ALIGN_CENTER);
        }
        ec = EXECUTE_SUCCESS;
        err = "";
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("finger", "user information lookup program", "[-lms] [user ...]",
            "Displays information about the system users.",
            "lms", 1, M, [
            "produces a multi-line format displaying all of the information described for the -s option as well as the user's home directory",
            "prevent matching of user names",
            "displays the user's login name, write status and login time"]);
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
