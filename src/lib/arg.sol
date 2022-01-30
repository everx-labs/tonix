pragma ton-solidity >= 0.56.0;

import "vars.sol";

library arg {

    function flag_set(string name, string flags) internal returns (bool) {
        return flags.empty() ? false : str.chr(flags, name) > 0;
    }

    function flag_values(string flags_query, string flags_set) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        uint len = flags_query.byteLength();
        bool[] tmp;
        for (uint i = 0; i < len; i++)
            tmp.push(str.chr(flags_set, flags_query.substr(i, 1)) > 0);
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false,
                len > 4 ? tmp[4] : false,
                len > 5 ? tmp[5] : false,
                len > 6 ? tmp[6] : false,
                len > 7 ? tmp[7] : false);
    }

    function get_args(string s_arg) internal returns (string[] args, string flags, string argv) {
        flags = vars.val("FLAGS", s_arg);
        string s_args = vars.val("PARAMS", s_arg);
        argv = vars.val("ARGV", s_arg);
        if (!s_args.empty())
            (args, ) = stdio.split(s_args, " ");
    }

    function get_env(string env) internal returns (uint16 wd, string[] args, string flags, string indices) {
        string s_wd = vars.val("WD", env);
        wd = str.toi(s_wd);
//        cwd = vars.val("PWD", env);
        flags = vars.val("FLAGS", env);
        string s_args = vars.val("PARAMS", env);
        if (!s_args.empty())
            (args, ) = stdio.split(s_args, " ");
        indices = vars.get_map_value("PARAM_INDEX", env);
    }

    function get_user_data(string env) internal returns (uint16 uid, uint16 gid) {
        string s_uid = vars.val("UID", env);
        uid = str.toi(s_uid);
        string s_gid = vars.val("GID", env);
        gid = str.toi(s_gid);
    }

    function get_opts(string s_arg) internal returns (string flags, string opt_args) {
        flags = vars.val("FLAGS", s_arg);
        opt_args = vars.get_map_value("OPT_ARGS", s_arg);
    }

    function opt_arg_value(string opt_name, string s_arg) internal returns (string) {
        return vars.val(opt_name, vars.get_map_value("OPT_ARGS", s_arg));
    }

    function param_indices(string s_arg) internal returns (string) {
        return vars.get_map_value("PARAM_INDEX", s_arg);
    }

    function index(string param_name, string s_arg) internal returns (string) {
        return vars.val(param_name, vars.get_map_value("PARAM_INDEX", s_arg));
    }

    function dir_entry(string param_name, string s_arg) internal returns (string) {
        return vars.get_pool_record(param_name, vars.get_map_value("PARAM_INDEX", s_arg));
    }

    function get_users_groups(string s_arg) internal returns (mapping (uint16 => string) users, mapping (uint16 => string) groups) {
        string user_map = vars.get_map_value("USERS", s_arg);
        (string[] lines, ) = stdio.split(user_map, "\n");
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            users[str.toi(name)] = value;
        }
        string group_map = vars.get_map_value("GROUPS", s_arg);
        (lines, ) = stdio.split(group_map, "\n");
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            groups[str.toi(name)] = value;
        }
    }
}