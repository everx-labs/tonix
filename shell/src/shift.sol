pragma ton-solidity >= 0.54.0;

import "Shell.sol";

contract shift is Shell {

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, , ) = _get_args(args);

        uint16 shift_count = params.empty() ? 1 : _atoi(params[0]);
        if (shift_count == 0)
            return (EXECUTE_SUCCESS, pool);

        string cmd = _val("COMMAND", pool);
        string pos_params= _val("PARAMS", pool);
        string s_flags = _val("FLAGS", pool);
        string input = _val("ARGV", pool);
        string s_n_params = _val("#", pool);
        string s_args = _val("@", pool);
        string last_param = _val("_", pool);
        string dbg_x = _val("OPT_ERR", pool);
        string redir_in = _val("REDIR_IN", pool);
        string redir_out = _val("REDIR_OUT", pool);
        string pos_args = _val("POS_ARGS", pool);
        string opt_args = _val("OPT_ARGS", pool);

//        string pos_map = _as_indexed_array("POS_ARGS", cmd + " " + s_args, " ");

        uint16 n_params = _atoi(s_n_params);
        if (n_params < shift_count) {
            ec = EXECUTE_FAILURE;
            // can't shift that many
            return (ec, "Can't shift that many");
        }

//        string cmd_type = _get_array_name(cmd, index);
        string new_pos_str = " ";
        (string[] prev, uint n_prev) = _split(s_args, " ");
        uint n_new = n_prev - shift_count;
        string argv = cmd;
        for (uint i = 0; i < n_new; i++) {
            params[i] = prev[i + shift_count];
            new_pos_str.append(params[i] + " ");
            argv.append(" " + params[i]);
        }
        new_pos_str = _unwrap(new_pos_str);
//        n_params -= shift_count;
        string pos_map = _as_indexed_array("POS_ARGS", new_pos_str.empty() ? cmd : cmd + " " + new_pos_str, " ");
        last_param = n_new > 0 ? params[n_new - 1] : cmd;

        ec = EXECUTE_SUCCESS;
        res = _as_var_list([
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", s_flags],
            ["ARGV", input],
            ["#", _itoa(n_new)],
            ["@", new_pos_str],
            ["?", _itoa(ec)],
            ["_", last_param],
            ["OPT_ERR", dbg_x],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]);
//        res.append(_as_hashmap("OPT_ARGS", opt_values) + "\n");
        res.append(opt_args + "\n");
        res.append(pos_map + "\n");
    }

/*    function reindex(uint16 Item[] annotation) external pure returns (uint8 ec, Item[] res) {
        string flags = _item_val("FLAGS", annotation);
        string cmd = _item_val("COMMAND", annotation);
//        string params = _item_val("@", annotation);
        string s_args = _item_val("@", annotation);
        string params = _item_val("PARAMS", annotation);
    }*/

    /*&function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, string argv) = _get_args(e[IS_ARGS]);
        uint n_params = params.length;

        uint16 n;// = _atoi(s_args);
        string pos_str = e[IS_POSITIONAL];
        string special_vars;
        string dbg;
        ec = 0;
        string new_pos_str;
        for (uint i = 0; i < n_params - n; i++) {
            params[i] = params[i + n];
            new_pos_str.append(params[i] + " ");
            special_vars.append(format("{}={}\n", i, params[i]));
        }
        pos_str = _trim_spaces(new_pos_str);


        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));

    }*/

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
