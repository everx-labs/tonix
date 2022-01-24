pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract id is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        err = "";

        ( , , string flags, ) = arg.get_env(argv);

        bool effective_gid_only = arg.flag_set("g", flags);
        bool name_not_number = arg.flag_set("n", flags);
        bool real_id = arg.flag_set("r", flags);
        bool effective_uid_only = arg.flag_set("u", flags);
        bool all_group_ids = arg.flag_set("G", flags);
        bool is_ugG = effective_uid_only || effective_gid_only || all_group_ids;

        string user_name = vars.val("USER", argv);
        string group_name = vars.val("USER", argv);
        string uid = vars.val("UID", argv);
        string eid = vars.val("EID", argv);
        string gid = vars.val("UID", argv);

        if ((name_not_number || real_id) && !is_ugG) {
            err = "id: cannot print only names or real IDs in default format";
            ec = EXECUTE_FAILURE;
        } else if (effective_gid_only && effective_uid_only) {
            out = "id: cannot print \"only\" of more than one choice";
            ec = EXECUTE_FAILURE;
        } else if (effective_gid_only)
            out = name_not_number ? group_name : format("{}", gid);
        else if (effective_uid_only)
            out = name_not_number ? user_name : format("{}", eid);
        else
            out = format("uid={}({}) gid={}({})", uid, user_name, gid, group_name);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"id",
"[OPTION]... [USER]",
"print real and effective user and group IDs",
"Print user and group information for the specified USER, or (when USER omitted) for the current user.",
"-a      ignore, for compatibility with other versions\n\
-g      print only the effective group ID\n\
-G      print all group IDs\n\
-n      print a name instead of a number, for -ugG\n\
-r      print the real ID instead of the effective ID, with -ugG\n\
-u      print only the effective user ID\n\
-z      delimit entries with NUL characters, not whitespace",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
