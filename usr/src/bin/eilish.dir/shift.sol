pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract shift is Shell {

    using str for string;

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, , ) = arg.get_args(args);

        uint16 shift_count = params.empty() ? 1 : str.toi(params[0]);
        if (shift_count == 0)
            return (EXECUTE_SUCCESS, pool);

        string cmd = vars.val("COMMAND", pool);
        string pos_params= vars.val("PARAMS", pool);
        string sflags = vars.val("FLAGS", pool);
        string input = vars.val("ARGV", pool);
        string sn_params = vars.val("#", pool);
        string sargs = vars.val("@", pool);
        string last_param = vars.val("_", pool);
        string dbg_x = vars.val("OPT_ERR", pool);
        string redir_in = vars.val("REDIR_IN", pool);
        string redir_out = vars.val("REDIR_OUT", pool);
        string opt_args = vars.val("OPT_ARGS", pool);

        uint16 n_params = str.toi(sn_params);
        if (n_params < shift_count) {
            ec = EXECUTE_FAILURE;
            // can't shift that many
            return (ec, "Can't shift that many");
        }

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

        ec = EXECUTE_SUCCESS;
        res = vars.as_var_list("", [
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", sflags],
            ["ARGV", input],
            ["#", str.toa(n_new)],
            ["@", new_pos_str],
            ["?", str.toa(ec)],
            ["_", last_param],
            ["OPT_ERR", dbg_x],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]);
        res.append(opt_args + "\n");
        res.append(pos_map + "\n");
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
