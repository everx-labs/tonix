pragma ton-solidity >= 0.58.0;

import "argmisc.sol";
import "../lib/libstring.sol";
import "xio.sol";
library parg {

    using argmisc for s_ar_misc;
    using str for string;

    function flag_set(s_proc p, string name) internal returns (bool) {
        return p.p_args.ar_misc.flag_set(name);
    }

    function flag_values(s_proc p, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        return p.p_args.ar_misc.flag_values(flags_query);
    }

    function flags_set(s_proc p, string flags_query) internal returns (bool, bool, bool, bool) {
        return p.p_args.ar_misc.flags_set(flags_query);
    }

    function flags_empty(s_proc p) internal returns (bool) {
        return p.p_args.ar_misc.flags.empty();
    }

    function get_args(s_proc p) internal returns (string[] args, string flags, string argv) {
        return p.p_args.ar_misc.get_args();
    }

    function params(s_proc p) internal returns (string[]) {
        return p.p_args.ar_misc.get_params();
    }

    function get_env(s_proc p) internal returns (uint16 wd, string[] args, string flags, string indices) {
        string pistr = p.p_args.ar_length > 1 ? p.p_args.ar_args[1] : "";
        return (xio.inono(p.p_pd.pwd_cdir), p.p_args.ar_misc.pos_params, p.p_args.ar_misc.flags, pistr);
    }

    /*function get_user_data(string e) internal returns (uint16, uint16) {
        return (env.getuid(e), env.getgid(e));
    }*/

    function opt_value(s_proc p, string opt_name) internal returns (string) {
        return p.p_args.ar_misc.opt_arg_value(opt_name);
    }

    function env_value(s_proc p, string env_name) internal returns (string) {
        string pat = env_name + "=";
        for (string s: p.environ) {
            uint q = s.strstr(pat);
            if (q > 0)
                return s.strtok(q + pat.strlen() - 1, "\n");
        }
    }

    function opt_value_int(s_proc p, string opt_name) internal returns (uint16) {
        return str.toi(p.p_args.ar_misc.opt_arg_value(opt_name));
    }

    function get_users_groups(s_proc ) internal returns (mapping (uint16 => string) users, mapping (uint16 => string) groups) {
        users[0] = "root";
        groups[0] = "wheel";
//        for (s_of f: p.p_fd.fdt_ofiles) {
//            if (f.path == "/etc/passwd")
        /*for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            users[str.toi(name)] = value;
        }
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            groups[str.toi(name)] = value;
        }*/
    }

    /*function get_users_groups(string sarg) internal returns (mapping (uint16 => string) users, mapping (uint16 => string) groups) {
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            users[str.toi(name)] = value;
        }
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            groups[str.toi(name)] = value;
        }
    }*/
}