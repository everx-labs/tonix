pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract shift is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] pool = e.environ[sh.VARIABLE];

        string[] params = cc.params();
        uint16 shift_count = params.empty() ? 1 : str.toi(params[0]);
        if (shift_count == 0)
            return (EXIT_SUCCESS, e);

        string cmd = vars.val("COMMAND", pool);
        string cmd_line = vars.val("COMMAND_LINE", pool);
        string pos_params = vars.val("PARAMS", pool);
        string sflags = vars.val("FLAGS", pool);
        string input = vars.val("ARGV", pool);
        string sn_params = vars.val("#", pool);
        string sec = vars.val("?", pool);
        string sargs = vars.val("@", pool);
        string last_param = vars.val("_", pool);
        string dbg_x = vars.val("OPTERR", pool);
        string redir_in = vars.val("REDIR_IN", pool);
        string redir_out = vars.val("REDIR_OUT", pool);
        string opt_args = vars.val("OPT_ARGS", pool);

        uint16 n_params = str.toi(sn_params);
        if (n_params < shift_count)
            e.perror("can't shift that many");

        string new_pos_str = " ";
        (string[] prev, uint n_prev) = sargs.split(" ");
        uint n_new = n_prev - shift_count;
        string argv = cmd;
        for (uint i = 0; i < n_new; i++) {
            params[i] = prev[i + shift_count];
            new_pos_str.append(params[i] + " ");
            argv.append(" " + params[i]);
        }
        last_param = n_new > 0 ? params[n_new - 1] : cmd;

        e.environ[sh.VARIABLE] = [
            "COMMAND=" + cmd,
            "COMMAND_LINE=" + cmd_line,
            "PARAMS=" + pos_params,
            "FLAGS=" + sflags,
            "ARGV=" + input,
            "#=" + str.toa(n_new),
            "@=" + sargs,
            "?=" + sec,
            "_=" + last_param,
            "OPTERR=" + dbg_x,
            "REDIR_IN=" + redir_in,
            "REDIR_OUT=" + redir_out
        ];
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
"[n]",
"Shift positional parameters.",
"Rename the positional parameters $N+1,$N+2 ... to $1,$2 ...  If N is not given, it is assumed to be 1.",
"",
"",
"Returns success unless N is negative or greater than $#.");
    }
    function _name() internal pure override returns (string) {
        return "shift";
    }
}
