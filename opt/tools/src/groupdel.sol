pragma ton-solidity >= 0.62.0;

import "Utility.sol";
import "pw.sol";
import "gr.sol";
import "fs.sol";
import "fmt.sol";
import "aio.sol";
contract groupdel is Utility {

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
        }
        string victim_group_name;
        if (params.length == 1)
            victim_group_name = params[0];
//        else
            // print usage
        (string etc_passwd, string etc_group, , uint16 etc_group_index) = fs.get_passwd_group(inodes, data);
        (string victim_group_line, s_group g_entry) = gr.getnam(victim_group_name, etc_group);
        if (victim_group_line.empty())
            errors.push(Err(er.E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist
        else {
            (string victim_passwd_line, s_passwd p_entry) = pw.getgid(g_entry.gr_gid, etc_passwd);
            if (victim_passwd_line.empty())
                ars.push(Ar(aio.UPDATE_TEXT_DATA, etc_group_index, "group", libstring.translate(etc_group, victim_group_line + "\n", "")));
            else
                errors.push(Err(8, 0, p_entry.pw_name)); // can't remove user's primary group
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupdel",
"[options] GROUP",
"delete a group",
"Modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
"-f     delete group even if it is the primary group of a user",
"",
"Written by Boris",
"",
"",
"0.03");
    }

}
