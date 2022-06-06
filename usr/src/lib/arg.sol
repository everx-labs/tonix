pragma ton-solidity >= 0.57.0;

import "env.sol";
//import "xio.sol";
import "er.sol";
import "sb.sol";


library arg {

    using libstring for string;
    function flag_set(string name, string flags) internal returns (bool) {
        return flags.empty() ? false : str.strchr(flags, name) > 0;
    }

    function flag_values(string flags_query, string flags_set) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        uint len = flags_query.byteLength();
        bool[] tmp;
        for (uint i = 0; i < len; i++)
            tmp.push(str.strchr(flags_set, flags_query.substr(i, 1)) > 0);
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false,
                len > 4 ? tmp[4] : false,
                len > 5 ? tmp[5] : false,
                len > 6 ? tmp[6] : false,
                len > 7 ? tmp[7] : false);
    }

    function get_args(string sarg) internal returns (string[] args, string flags, string argv) {
        flags = env.get("FLAGS", sarg);
        string sargs = env.get("PARAMS", sarg);
        argv = env.get("ARGV", sarg);
        if (!sargs.empty())
            (args, ) = sargs.split(" ");
    }

    function get_env(string e) internal returns (uint16 wd, string[] args, string flags, string /*indices*/) {
        wd = str.toi(env.get("WD", e));
        flags = env.get("FLAGS", e);
        string sargs = env.get("PARAMS", e);
        if (!sargs.empty())
            (args, ) = sargs.split(" ");
//        indices = vars.get_map_value("PARAM_INDEX", e);
    }

    function get_user_data(string e) internal returns (uint16, uint16) {
        return (env.getuid(e), env.getgid(e));
    }

    function opt_arg_value(string opt_name, string sarg) internal returns (string) {
        return vars.val(opt_name, vars.get_map_value("OPT_ARGS", sarg));
    }

    function get_users_groups(string sarg) internal returns (mapping (uint16 => string) users, mapping (uint16 => string) groups) {
        string umap = vars.get_map_value("USERS", sarg);
        (string[] lines, ) = umap.split("\n");
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            users[str.toi(name)] = value;
        }
        umap = vars.get_map_value("GROUPS", sarg);
        (lines, ) = umap.split("\n");
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            groups[str.toi(name)] = value;
        }
    }

}