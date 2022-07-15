pragma ton-solidity >= 0.62.0;

import "job_h.sol";
import "libstring.sol";
import "vars.sol";


library libcommand {
    function get_cmd(string[] page) internal returns (job_cmd) {
        string cmd = vars.val("COMMAND", page);
        string sarg = vars.val("@", page);
        string argv = vars.val("ARGV", page);
        string exec_line = vars.val("COMMAND_LINE", page);
        (string[] params, ) = libstring.split(vars.val("PARAMS", page), ' ');
        string flags = vars.val("FLAGS", page);
        uint16 n_args = vars.int_val("#", page);
        uint8 ec = uint8(vars.int_val("?", page));
        string last = vars.val("_", page);
        string opterr = vars.val("OPTERR", page);
        string redir_in = vars.val("REDIR_IN", page);
        string redir_out = vars.val("REDIR_OUT", page);
        return job_cmd(cmd, sarg, argv, exec_line, params, flags, n_args, ec, last, opterr, redir_in, redir_out);
    }
    function as_row(job_cmd c) internal returns (string[]) {
        (string cmd, string sarg, string argv, string exec_line, string[] params, string flags, uint16 n_args, uint8 ec, string last, string opterr, string redir_in, string redir_out) = c.unpack();
        string spar = libstring.join_fields(params, ' ');
        return [cmd, sarg, argv, exec_line, spar, flags, str.toa(n_args), str.toa(ec), last, opterr, redir_in, redir_out];
    }
}
