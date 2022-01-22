pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/uadmin.sol";

contract groups is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, , ) = _get_env(argv);

        string user_name = _val("USER", argv);
        string etc_group = _get_file_contents_at_path("/etc/group", inodes, data);

        if (params.empty()) {
            (string primary, string[] supp) = uadmin.user_groups(user_name, etc_group);
            out.append(primary + " " + _join_fields(supp, " ") + "\n");
        }
        for (string param: params) {
            (string primary, string[] supp) = uadmin.user_groups(param, etc_group);
            out.append(primary + " : " + primary + " " + _join_fields(supp, " ") + "\n");
        }
        ec = EXECUTE_SUCCESS;
        err = "";
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