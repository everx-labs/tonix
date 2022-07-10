pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "pw.sol";
import "gr.sol";
import "adm.sol";

contract groupadd is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (, string[] params, , ) = p.get_env();
        string out;
        Ar[] ars;
        Err[] errors;
        uint8 ec;
        if (params.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            out = libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
            return p;
        }
        (bool force, bool use_group_id, bool is_system_group, , , , , ) = p.flag_values("fgr");

        string target_group_name = params[0];
        uint16 target_group_id;
        (string etc_passwd, string etc_group, , ) = fs.get_passwd_group(inodes, data);

        (string line, ) = gr.getnam(target_group_name, etc_group);
        if (!line.empty())
            errors.push(Err(er.E_NAME_IN_USE, 0, target_group_name));
        if (use_group_id) {
            string group_id_s = p.opt_value("g");
            uint16 n_gid = str.toi(group_id_s);
            if (n_gid == 0)
                errors.push(Err(er.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                target_group_id = uint16(n_gid);
            (string group_name, ) = gr.getgid(target_group_id, etc_group);
            if (!group_name.empty()) {
                if (force)
                    target_group_id = 0;
                else
                    errors.push(Err(er.E_GID_IN_USE, 0, group_id_s));
            }
        }

        (, , uint16 reg_groups_counter, uint16 sys_groups_counter) = adm.get_counters(etc_passwd);
        if (target_group_id == 0)
            target_group_id = is_system_group ? sys_groups_counter++ : reg_groups_counter++;

        if (errors.empty()) {
            uint16 etc_dir = fs.resolve_absolute_path("/etc", inodes, data);
            (uint16 group_index, uint8 group_file_type, ) = fs.lookup_dir_ext(inodes[etc_dir], data[etc_dir], "group");
            string[] empty;
            string text = gr.putent(s_group(target_group_name, target_group_id, empty), etc_group);
            if (group_file_type == ft.FT_UNKNOWN) {
                uint16 ic = sb.get_inode_count(inodes);
                ars.push(Ar(aio.MKFILE, ic, "group", text));
                ars.push(Ar(aio.ADD_DIR_ENTRY, etc_dir, "", udirent.dir_entry_line(ic, "group", ft.FT_REG_FILE)));
            } else
                ars.push(Ar(aio.UPDATE_TEXT_DATA, group_index, "group", text));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupadd",
"[options] group",
"create a new group",
"Creates a new group account using the default values from the system.",
"-f     exit successfully if the group already exists, and cancel -g if the GID is already used\n\
-g      use GID for the new group\n\
-r      create a system group",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
