pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";
import "gr.sol";

contract groups is putil_stat {

    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        string user_name = e.env_value("USER");
        uint16 uid = str.toi(e.env_value("UID"));

        (, string etc_group, , ) = fs.get_passwd_group(inodes, data);

        if (params.empty()) {
            (string primary, string[] supp) = gr.initgroups(user_name, uid, etc_group);
            e.puts(primary + " " + libstring.join_fields(supp, " "));
        }
        for (string param: params) {
            (string primary, string[] supp) = gr.initgroups(param, 0, etc_group);
            e.puts(primary + " : " + primary + " " + libstring.join_fields(supp, " "));
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groups",
"[OPTION]... [USERNAME]...",
"print the groups a user is in",
"Print group memberships for each USERNAME or, if no USERNAME is specified, for the current process\n\
(which may differ if the groups database has changed).",
"",
"",
"Written by Boris",
"",
"getent(1)",
"0.01");
    }

}
