pragma ton-solidity >= 0.62.0;

import "libstring.sol";
//import "xio.sol";
library libarg {

//    using str for string;
//    using libstring for string;
//    using io for s_proc;
//    using xio for s_of;

    /*function shift_args(s_proc p) internal {
        s_ar_misc misc = p.p_args.ar_misc;
        (, , string sargs, uint16 n_params, string[] pos_params, , string last_param, , , ,
            , ) = misc.unpack();
        if (n_params > 0) {
            p.p_comm = pos_params[0];
            for (uint i = 0; i < n_params - 1; i++)
                pos_params[i] = pos_params[i + 1];
            pos_params.pop();
            n_params--;
            last_param = pos_params[n_params - 1];
            sargs = libstring.join_fields(pos_params, " ");
        }
    }*/

    function flag_set(string[][] e, byte b) internal returns (bool) {
        bytes flags = vars.val("FLAGS", e[sh.SPECVARS]);
        return flags.empty() ? false : str.strchr(flags, b) > 0;
    }

    function flag_values(string[][] e, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        uint len = flags_query.byteLength();
        string flags_set = vars.val("FLAGS", e[sh.SPECVARS]);
        bool[] tmp;
        uint i;
        for (byte b: bytes(flags_query)) {
            tmp.push(str.strchr(flags_set, b) > 0);
            i++;
        }
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false,
                len > 4 ? tmp[4] : false,
                len > 5 ? tmp[5] : false,
                len > 6 ? tmp[6] : false,
                len > 7 ? tmp[7] : false);
    }
    function flags_set(string[][] e, string flags_query) internal returns (bool, bool, bool, bool) {
        uint len = flags_query.strlen();
        string flags = vars.val("FLAGS", e[sh.SPECVARS]);
        bool[] tmp;
        uint i;
        for (byte b: bytes(flags_query)) {
            tmp.push(str.strchr(flags, b) > 0);
            i++;
        }
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false);
    }
    function get_args(string[][] e) internal returns (string[] args, string flags, string argv) {
        string[] esv = e[sh.SPECVARS];
        return (libstring.split(vars.val("PARAMS", esv), ' '), vars.val("FLAGS", esv), vars.val("ARGV", esv));
    }
    function get_params(string[] ee) internal returns (string[]) {
        return libstring.split(vars.val("PARAMS", e[sh.SPECVARS]), ' ');
    }
    function get_cwd(string[][] e) internal returns (uint16) {
        return vars.int_val("WD", e[sh.VARIABLE]);
    }
    function opt_value(string[][] e, string opt_name) internal returns (string) {
        return vars.val(opt_name, e[sh.OPTARGS]);
    }
    function opt_value_int(string[][] e, string opt_name) internal returns (uint16) {
        return vars.int_val(opt_name, e[sh.OPTARGS]);
    }
    function flags_empty(string[][] e) internal returns (bool) {
        return vars.val("FLAGS", e[sh.SPECVARS]).empty();
    }

    /*function get_env(s_proc p) internal returns (uint16 wd, string[] args, string flags, string indices) {
        string pistr = p.p_args.ar_length > 1 ? p.p_args.ar_args[1] : "";
        return (xio.inono(p.p_pd.pwd_cdir), p.p_args.ar_misc.pos_params, p.p_args.ar_misc.flags, pistr);
    }*/

    /*function get_user_data(string e) internal returns (uint16, uint16) {
        return (env.getuid(e), env.getgid(e));
    }*/

    /*function opt_value(s_proc p, string opt_name) internal returns (string) {
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
        }
    }*/
}