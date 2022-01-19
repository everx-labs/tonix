pragma ton-solidity >= 0.54.0;

import "variables.sol";

abstract contract arguments is variables {

    function _flag_set(string name, string flags) internal pure returns (bool) {
        return flags.empty() ? false : _strchr(flags, name) > 0;
    }

    function _flag_values(string flags_query, string flags_set) internal pure returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        uint len = flags_query.byteLength();
        bool[] tmp;
        for (uint i = 0; i < len; i++)
            tmp.push(_strchr(flags_set, flags_query.substr(i, 1)) > 0);
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[1] : false,
                len > 3 ? tmp[1] : false,
                len > 4 ? tmp[1] : false,
                len > 5 ? tmp[1] : false,
                len > 6 ? tmp[1] : false,
                len > 7 ? tmp[1] : false);
    }

    function _get_args(string arg) internal pure returns (string[] args, string flags, string argv) {
        flags = _val("FLAGS", arg);
        string s_args = _val("PARAMS", arg);
        argv = _val("ARGV", arg);
        if (!s_args.empty())
            (args, ) = _split(s_args, " ");
//        argv.append(format("> get_args: s_args \"{}\", flags \"{}\", page {}\n", s_args, flags, arg));
    }

    function _get_env(string env) internal pure returns (uint16 wd, string[] args, string flags, string cwd) {
        string s_wd = _val("WD", env);
        wd = _atoi(s_wd);
        cwd = _val("PWD", env);
        flags = _val("FLAGS", env);
        string s_args = _val("PARAMS", env);
        if (!s_args.empty())
            (args, ) = _split(s_args, " ");
    }

    function _get_user_data(string env) internal pure returns (uint16 uid, uint16 gid) {
        string s_uid = _val("UID", env);
        uid = _atoi(s_uid);
        string s_gid = _val("GID", env);
        gid = _atoi(s_gid);
    }

    function _get_opts(string arg) internal pure returns (string flags, string opt_args) {
        flags = _val("FLAGS", arg);
        opt_args = _get_map_value("OPT_ARGS", arg);
    }

    function _opt_arg_value(string opt_name, string arg) internal pure returns (string) {
        return _val(opt_name, _get_map_value("OPT_ARGS", arg));
    }

}