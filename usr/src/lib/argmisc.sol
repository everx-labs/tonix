pragma ton-solidity >= 0.58.0;

import "stypes.sol";
import "../lib/str.sol";

library argmisc {

    using str for string;

    function flag_set(s_ar_misc m, string name) internal returns (bool) {
        return m.flags.empty() ? false : m.flags.strchr(name) > 0;
    }

    function flag_values(s_ar_misc m, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        uint len = flags_query.byteLength();
        string flags_set = m.flags;
        bool[] tmp;
        for (uint i = 0; i < len; i++)
            tmp.push(flags_set.strchr(flags_query.substr(i, 1)) > 0);
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false,
                len > 4 ? tmp[4] : false,
                len > 5 ? tmp[5] : false,
                len > 6 ? tmp[6] : false,
                len > 7 ? tmp[7] : false);
    }

    function flags_set(s_ar_misc m, string flags_query) internal returns (bool, bool, bool, bool) {
        uint len = flags_query.strlen();
        string flags = m.flags;
        bool[] tmp;
        for (uint i = 0; i < len; i++)
            tmp.push(flags.strchr(flags_query.substr(i, 1)) > 0);
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false);
    }

    function get_args(s_ar_misc m) internal returns (string[] args, string flags, string argv) {
        return (m.pos_params, m.flags, m.sargs);
    }

    function get_params(s_ar_misc m) internal returns (string[]) {
        return m.pos_params;
    }

    function opt_arg_value(s_ar_misc m, string opt_name) internal returns (string) {
        string[][2] opt_values = m.opt_values;
        for (string[2] p: opt_values)
            if (opt_name == p[0])
                return p[1];
    }
}
