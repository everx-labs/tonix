pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "../lib/pw.sol";
import "../lib/gr.sol";

contract userdel is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        string out;
        Ar[] ars;
        Err[] errors;

        if (params.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            out = libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
        } else {
            //(bool force, /*bool remove_home_dir*/, , , , , , ) = arg.flag_values("fr", flags);
            string victim_user_name = params[0];
            (string etc_passwd, string etc_group, uint16 etc_passwd_index, uint16 etc_group_index) = fs.get_passwd_group(inodes, data);
            (string victim_passwd_line, s_passwd entry) = pw.getnam(victim_user_name, etc_passwd);
            if (victim_passwd_line.empty())
                errors.push(Err(er.E_NOTFOUND, 0, victim_user_name)); // specified user doesn't exist
            else {
                ars.push(Ar(aio.UPDATE_TEXT_DATA, etc_passwd_index, "passwd", libstring.translate(etc_passwd, victim_passwd_line + "\n", "")));
                uint16 pw_gid = entry.pw_gid;
                (string victim_group_entry, ) = gr.getgid(pw_gid, etc_group);
                if (!victim_group_entry.empty())
                    ars.push(Ar(aio.UPDATE_TEXT_DATA, etc_group_index, "group", libstring.translate(etc_group, victim_group_entry + "\n", "")));
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"userdel",
"[options] LOGIN",
"delete a user account and related files",
"A low level utility for removing users.",
"-f      force removal of files, even if not owned by user\n\
-r      remove the user's home directory",
"",
"Written by Boris",
"",
"",
"0.02");
    }
}
