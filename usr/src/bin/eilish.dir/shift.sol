pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract shift is pbuiltin {

    function _main(s_proc p, string[] params, shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        string[] pool = e.environ[sh.ARRAYVAR];

        uint16 shift_count = params.empty() ? 1 : str.toi(params[0]);
        if (shift_count == 0)
            return e;

        string cmd = vars.val("COMMAND", pool);
        string pos_params = vars.val("PARAMS", pool);
        string sflags = vars.val("FLAGS", pool);
        string input = vars.val("ARGV", pool);
        string sn_params = vars.val("#", pool);
        string sargs = vars.val("@", pool);
        string last_param = vars.val("_", pool);
        string dbg_x = vars.val("OPTERR", pool);
        string redir_in = vars.val("REDIR_IN", pool);
        string redir_out = vars.val("REDIR_OUT", pool);
        string opt_args = vars.val("OPT_ARGS", pool);

        uint16 n_params = str.toi(sn_params);
        if (n_params < shift_count)
            p.perror("can't shift that many");

        string new_pos_str = " ";
        (string[] prev, uint n_prev) = sargs.split(" ");
        uint n_new = n_prev - shift_count;
        string argv = cmd;
        for (uint i = 0; i < n_new; i++) {
            params[i] = prev[i + shift_count];
            new_pos_str.append(params[i] + " ");
            argv.append(" " + params[i]);
        }
        new_pos_str.unwrap();
        string pos_map = vars.as_indexed_array("POS_ARGS", new_pos_str.empty() ? cmd : cmd + " " + new_pos_str, " ");
        last_param = n_new > 0 ? params[n_new - 1] : cmd;

        s_ar_misc prev_misc = p.p_args.ar_misc;
        p.p_args.ar_misc = s_ar_misc(input, sflags, sargs, uint16(n_new), params, prev_misc.ec, last_param,
            dbg_x, redir_in, redir_out, prev_misc.pos_args, prev_misc.opt_values); // Fix this after streamlining args passing

//        sv.cur_proc = p;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"shift",
"[n]",
"Shift positional parameters.",
"Rename the positional parameters $N+1,$N+2 ... to $1,$2 ...  If N is not given, it is assumed to be 1.",
"",
"",
"Returns success unless N is negative or greater than $#.");
    }

}
