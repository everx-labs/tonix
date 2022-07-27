pragma ton-solidity >= 0.61.2;

import "argmisc.sol";
import "libstring.sol";
import "xio.sol";
library parg {

    using argmisc for s_ar_misc;
    using str for string;
    using libstring for string;
    using io for s_proc;
    using xio for s_of;

    /*function map_file(s_proc p, string name) internal returns (string[]) {
        string all_lines = read_file(p, name);
        if (!all_lines.empty()) {
            (string[] lines, ) = all_lines.split("\n");
            return lines;
        } else
            p.perror(name + ": empty");
    }

    function read_file(s_proc p, string name) internal returns (string) {
        s_of f = p.fopen(name, "r");
        if (!f.ferror()) {
            string all_lines = f.gets_s(0);
            if (!f.ferror())
                return all_lines;
        } else
            p.perror(name + ": failed to open");
    }*/

    function shift_args(s_proc p) internal {
        s_ar_misc misc = p.p_args.ar_misc;
//        (string argv, string flags, string sargs, uint16 n_params, string[] pos_params, uint8 ec, string last_param, string opt_err, string redir_in, string redir_out,
//            s_dirent[] pos_args, string[][2] opt_values) = misc.unpack();
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

    }

    function flag_set(s_proc p, byte b) internal returns (bool) {
        return p.p_args.ar_misc.flag_set(b);
    }

    function flag_values(s_proc p, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        return p.p_args.ar_misc.flag_values(flags_query);
    }

    function flags_set(s_proc p, string flags_query) internal returns (bool, bool, bool, bool) {
        uint len = flags_query.strlen();
        string flags = p.p_args.ar_misc.flags;
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

    function flags_empty(s_proc p) internal returns (bool) {
        return p.p_args.ar_misc.flags.empty();
    }

    function get_args(s_proc p) internal returns (string[] args, string flags, string argv) {
        return p.p_args.ar_misc.get_args();
    }

    function params(s_proc p) internal returns (string[]) {
        return p.p_args.ar_misc.get_params();
    }

    function get_cwd(s_proc p) internal returns (uint16) {
        return xio.inono(p.p_pd.pwd_cdir);
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
}