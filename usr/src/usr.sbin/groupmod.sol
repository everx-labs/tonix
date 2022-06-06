pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "../lib/pw.sol";
import "../lib/gr.sol";

contract groupmod is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);
        if (params.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            out = libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
            return (ec, out, ars, errors);
        }
        (bool use_group_id, bool use_new_name, , , , , , ) = arg.flag_values("gn", flags);
        (, string etc_group, , uint16 etc_group_index) = fs.get_passwd_group(inodes, data);
        string param = params[0];

        (string cur_record, s_group cur_group) = use_group_id ? gr.getnam(param, etc_group) : gr.getgid(str.toi(param), etc_group);
        if (cur_record.empty()) {
            errors.push(Err(er.E_NOTFOUND, 0, param)); // specified group doesn't exist
        } else {
            if (use_group_id)
                cur_group.gr_gid = str.toi(arg.opt_arg_value("g", args));
            else if (use_new_name)
                cur_group.gr_name = arg.opt_arg_value("n", args);
            string new_text = gr.putent(cur_group, etc_group);
            ars.push(Ar(aio.UPDATE_TEXT_DATA, etc_group_index, "group", new_text));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupmod",
"[options] GROUP",
"modify a group definition on the system",
"Modifies the definition of the specified GROUP by modifying the appropriate entry in the group database.",
"-g     the group ID of the given GROUP will be changed to GID\n\
-n      the name of the group will be changed from GROUP to NEW_GROUP name",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
