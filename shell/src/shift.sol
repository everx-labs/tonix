pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract shift is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
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
