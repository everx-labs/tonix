pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract id is Utility {

//    function exec(string[] e) external pure returns (string out) {
    function exec(string[] e) external pure returns (uint8 ec, string out, string err) {
        ec = 0;
        string pool = e[IS_POOL];
        out = _val("USER", pool);
        err = "";

        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);

        bool effective_gid_only = _flag_set("g", flags);
        bool name_not_number = _flag_set("n", flags);
        bool real_id = _flag_set("r", flags);
        bool effective_uid_only = _flag_set("u", flags);
        bool all_group_ids = _flag_set("G", flags);
        bool is_ugG = effective_uid_only || effective_gid_only || all_group_ids;

        string user_name = _val("USER", pool);
        string group_name = _val("USER", pool);
        string uid = _val("UID", pool);
        string eid = _val("EID", pool);
        string gid = _val("UID", pool);

        if ((name_not_number || real_id) && !is_ugG)
            out = "id: cannot print only names or real IDs in default format";
        else if (effective_gid_only && effective_uid_only)
            out = "id: cannot print \"only\" of more than one choice";
        else if (effective_gid_only)
            out = name_not_number ? group_name : format("{}", gid);
        else if (effective_uid_only)
            out = name_not_number ? user_name : format("{}", uid);
        else
            out = format("uid={}({}) gid={}({})", uid, user_name, gid, group_name);
    }

    function _id(uint flags, string user_name, uint16 uid, uint16 gid, string group_name) private pure returns (string out) {
        bool effective_gid_only = (flags & _g) > 0;
        bool name_not_number = (flags & _n) > 0;
        bool real_id = (flags & _r) > 0;
        bool effective_uid_only = (flags & _u) > 0;

        bool is_ugG = (flags & _u + _g + _G) > 0;

        if ((name_not_number || real_id) && !is_ugG)
            out = "id: cannot print only names or real IDs in default format";
        else if (effective_gid_only && effective_uid_only)
            out = "id: cannot print \"only\" of more than one choice";
        else if (effective_gid_only)
            out = name_not_number ? group_name : format("{}", gid);
        else if (effective_uid_only)
            out = name_not_number ? user_name : format("{}", uid);
        else
            out = format("uid={}({}) gid={}({})", uid, user_name, gid, group_name);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("id", "print real and effective user and group IDs", "[OPTION]... [USER]",
            "Print user and group information for the specified USER, or (when USER omitted) for the current user.",
            "agGnruz", 0, 1, [
            "ignore, for compatibility with other versions",
            "print only the effective group ID",
            "print all group IDs",
            "print a name instead of a number, for -ugG",
            "print the real ID instead of the effective ID, with -ugG",
            "print only the effective user ID",
            "delimit entries with NUL characters, not whitespace"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
