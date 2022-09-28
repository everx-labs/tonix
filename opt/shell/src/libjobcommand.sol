pragma ton-solidity >= 0.62.0;

import "job_h.sol";
import "libstring.sol";
import "libtable.sol";
import "vars.sol";

library libjobcommand {

    using libstring for string;
// Possible values for the `flags' field of a WORD_DESC.

    function flag_set(job_cmd jc, byte b) internal returns (bool) {
        bytes flags = jc.flags;
        return flags.empty() ? false : str.strchr(flags, b) > 0;
    }
    function flag_values(job_cmd jc, string flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        return _flag_values(jc.flags, flags_query);
    }
    function _flag_values(string flags_actual, bytes flags_query) internal returns (bool, bool, bool, bool, bool, bool, bool, bool) {
        bool[] tmp;
        uint len = flags_query.length;
        for (byte b: flags_query)
            tmp.push(str.strchr(flags_actual, b) > 0);
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false,
                len > 4 ? tmp[4] : false,
                len > 5 ? tmp[5] : false,
                len > 6 ? tmp[6] : false,
                len > 7 ? tmp[7] : false);
    }
    function flags_set(job_cmd jc, bytes flags_query) internal returns (bool, bool, bool, bool) {
        uint len = flags_query.length;
        string flags = jc.flags;
        bool[] tmp;
        uint i;
        for (byte b: flags_query) {
            tmp.push(str.strchr(flags, b) > 0);
            i++;
        }
        return (len > 0 ? tmp[0] : false,
                len > 1 ? tmp[1] : false,
                len > 2 ? tmp[2] : false,
                len > 3 ? tmp[3] : false);
    }

    function params(job_cmd jc) internal returns (string[] args) {
        for (string p: jc.pargs)
            if (p.substr(0, 1) != '-')
                args.push(p);
    }

    function flags_empty(job_cmd jc) internal returns (bool) {
        return jc.flags.empty();
    }

    /*function opt_value(job_cmd jc, string opt_name) internal returns (string) {
        return vars.val(opt_name, e.environ[sh.OPTARGS]);
    }
    function opt_value_int(job_cmd jc, string opt_name) internal returns (uint16) {
        return vars.int_val(opt_name, e.environ[sh.OPTARGS]);
    }*/

    function get_cmd(string[] page) internal returns (job_cmd) {
        string cmd = vars.val("COMMAND", page);
        string sarg = vars.val("@", page);
        string argv = vars.val("ARGV", page);
        string exec_line = vars.val("COMMAND_LINE", page);
        (string[] parms, ) = libstring.split(vars.val("PARAMS", page), ' ');
        string flags = vars.val("FLAGS", page);
        uint16 n_args = vars.int_val("#", page);
        uint8 ec = uint8(vars.int_val("?", page));
        string last = vars.val("_", page);
        string opterr = vars.val("OPTERR", page);
        string redir_in = vars.val("REDIR_IN", page);
        string redir_out = vars.val("REDIR_OUT", page);
        return job_cmd(cmd, sarg, argv, exec_line, parms, flags, n_args, ec, last, opterr, redir_in, redir_out);
    }
    function as_row(job_cmd c) internal returns (string[]) {
        (string cmd, string sarg, string argv, string exec_line, string[] parms, string flags, uint16 n_args, uint8 ec, string last, string opterr, string redir_in, string redir_out) = c.unpack();
        string spar = libstring.join_fields(parms, ' ');
        return [cmd, sarg, argv, exec_line, spar, flags, str.toa(n_args), str.toa(ec), last, opterr, redir_in, redir_out];
    }
}
