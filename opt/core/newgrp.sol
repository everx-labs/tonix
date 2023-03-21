pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";
import "pw.sol";
import "gr.sol";

contract newgrp is putil_stat {

    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        Err[] errors;
        (bool force, bool use_group_id, bool is_system_group, , , , , ) = e.flag_values("fgr");

        (, string etc_group, , uint16 group_index) = fs.get_passwd_group(inodes, data);

        uint n_args = params.length;
        string target_group_name = params[n_args - 1];
        uint16 target_group_id;

        (string g_line, ) = gr.getnam(target_group_name, etc_group);
        if (!g_line.empty())
            errors.push(Err(er.E_NAME_IN_USE, 0, target_group_name));
        else if (use_group_id && n_args > 1) {
            string group_id_s = params[0];
            optional(int) val = stoi(group_id_s);
            uint16 n_gid;
            if (!val.hasValue())
                errors.push(Err(er.E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            else
                n_gid = uint16(val.get());
            target_group_id = uint16(n_gid);
            (g_line, ) = gr.getgid(target_group_id, etc_group);
            if (!g_line.empty())
                errors.push(Err(er.E_GID_IN_USE, 0, group_id_s));
                if (force)
                    target_group_id = 0;
                else
                    errors.push(Err(er.E_GID_IN_USE, 0, group_id_s));
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"newgrp",
"[-] [group]",
"log in to a new group",
"Change the current group ID during a login session.",
"",
"",
"Written by Boris",
"",
"",
"0.02");
    }
}
