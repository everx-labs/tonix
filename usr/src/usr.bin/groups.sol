pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "../lib/gr.sol";

contract groups is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;

//    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
//        (, string[] params, , ) = arg.get_env(argv);
        string[] params = p.params();
        string user_name = p.env_value("USER");
        uint16 uid = str.toi(p.env_value("UID"));
///        uint16 uid = env.getuid(argv);

        (, string etc_group, , ) = fs.get_passwd_group(inodes, data);

        if (params.empty()) {
            (string primary, string[] supp) = gr.initgroups(user_name, uid, etc_group);
            p.puts(primary + " " + libstring.join_fields(supp, " "));
        }
        for (string param: params) {
            (string primary, string[] supp) = gr.initgroups(param, 0, etc_group);
            p.puts(primary + " : " + primary + " " + libstring.join_fields(supp, " "));
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
