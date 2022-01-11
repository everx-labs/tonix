pragma ton-solidity >= 0.53.0;

import "variables.sol";

abstract contract arguments is variables {

    function _flag_set(string name, string flags) internal pure returns (bool) {
        return _strchr(flags, name) > 0;
    }

    function _get_args(string arg) internal pure returns (string[] args, string flags, string argv) {
        flags = _val("FLAGS", arg);
        string s_args = _val("PARAMS", arg);
        argv = _val("ARGV", arg);
        if (!s_args.empty())
            (args, ) = _split(s_args, " ");
        argv.append(format("> get_args: s_args \"{}\", flags \"{}\", page {}\n", s_args, flags, arg));
    }

    function _get_opts(string arg) internal pure returns (string flags, string opt_args) {
        flags = _val("FLAGS", arg);
        opt_args = _get_map_value("OPT_ARGS", arg);
    }

    function _opt_arg_value(string opt_name, string arg) internal pure returns (string) {
        return _val(opt_name, _get_map_value("OPT_ARGS", arg));
    }

    function _get_builtin_args(string[] e) internal pure returns (string cmd, string[] args, string flags, string argv) {
        string arg_arr = e[IS_BLTN_IN];
        cmd = _val("BLTN_COMMAND", arg_arr);
        flags = _val("BLTN_FLAGS", arg_arr);
        string s_args = _val("BLTN_PARAMS", arg_arr);
        argv = _val("BLTN_ARGV", arg_arr);
        if (!s_args.empty())
            (args, ) = _split(s_args, " ");
        argv.append(format("> bltn_get_args: s_args \"{}\", flags \"{}\", page {}\n", s_args, flags, arg_arr));
    }

}