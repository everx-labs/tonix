pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract groups is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, , ) = arg.get_env(argv);

        string user_name = vars.val("USER", argv);
        (, string etc_group, , ) = fs.get_passwd_group(inodes, data);

        if (params.empty()) {
            (string primary, string[] supp) = uadmin.user_groups(user_name, etc_group);
            out.append(primary + " " + stdio.join_fields(supp, " ") + "\n");
        }
        for (string param: params) {
            (string primary, string[] supp) = uadmin.user_groups(param, etc_group);
            out.append(primary + " : " + primary + " " + stdio.join_fields(supp, " ") + "\n");
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
