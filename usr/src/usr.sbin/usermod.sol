pragma ton-solidity >= 0.59.0;

import "Utility.sol";
import "../lib/pw.sol";
import "../lib/gr.sol";

contract usermod is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        if (params.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            out = libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
            return (ec, out, ars, errors);
        }
        (bool change_primary_group, /*bool supp_groups_list*/, , , , , , ) = arg.flag_values("gG", flags);
        string param_user_name = change_primary_group ? params[0] : "";

        (string etc_passwd, string etc_group, uint16 etc_passwd_index, ) = fs.get_passwd_group(inodes, data);
        (string cur_line, s_passwd cur_entry) = pw.getnam(param_user_name, etc_passwd);
        if (cur_line.empty())
            errors.push(Err(er.E_NOTFOUND, 0, param_user_name)); // specified user doesn't exist
        else {
            if (change_primary_group && !params.empty()) {
                string param_new_gid_s = arg.opt_arg_value("g", args);
                uint16 new_gid = str.toi(param_new_gid_s);
                (string line, ) = gr.getgid(new_gid, etc_group);
                if (line.empty())
                    errors.push(Err(er.E_NOTFOUND, 0, param_new_gid_s)); // specified group doesn't exist
                else {
                    cur_entry.pw_gid = new_gid;
                    string new_text = pw.putent(cur_entry, etc_passwd);
                    ars.push(Ar(aio.UPDATE_TEXT_DATA, etc_passwd_index, "passwd", new_text));
                }
            }
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"usermod",
"[options] LOGIN",
"modify a user account",
"Modifies the system account files to reflect the changes that are specified on the command line.",
"-a      add the user to the supplementary groups mentioned by the -G option\n\
-g      force use GROUP as new primary group\n\
-G      a list of supplementary groups separated from the next by a comma",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
