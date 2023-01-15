pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libcommand.sol";
import "libjobcommand.sol";

contract dispose_cmd {

    using libfdt for s_of[];
    using libshellenv for shell_env;
    using libstring for string;
    using vars for string[];
    using vars for string;
    using libjobcommand for job_cmd;
    uint8 constant NO_PIPE = 255;

    function main(shell_env e_in, s_command cmd_in, job_cmd cc_in) external pure returns (shell_env e, uint8 rc, string stdout, string stderr, string comm, string cmdline, job_spec cj, job_cmd cc, s_command cmd) {
        e = e_in;
        cc = cc_in;
        cmd = cmd_in;
        uint8 result;
        (result, e) = _dispose_cmd(e_in, cmd_in, cc_in);
        (stdout, stderr) = e.ofiles.fdflush();
    }

    function _dispose_cmd(shell_env e_in, s_command cmd_in, job_cmd cc_in) internal pure returns (uint8 ec, shell_env e) {
        (command_type c_type, uint16 flags, uint16 line, s_redirect[] redirects, simple_com value) = cmd_in.unpack();
        uint len = redirects.length;
        uint8 pipe_in;
        uint8 pipe_out;
        if (len > 0)
            pipe_in = redirects[0].redirector;
        if (len > 1)
            pipe_out = redirects[1].redirector;
        uint8[] fds_to_close;
        bool asynchronous;
        if (c_type == command_type.cm_simple) {
            (ec, e) = dispose_simple_command(e_in, value, cc_in, asynchronous, pipe_in, pipe_out, fds_to_close);
        }
    }

    function dispose_simple_command(shell_env e_in, simple_com cmd, job_cmd cc_in, bool asynchronous, uint8 pipe_in, uint8 pipe_out, uint8[] fds_to_close) internal pure returns (uint8 ec, shell_env e) {
        e = e_in;
        ec = 0;
        (uint16 flags, uint16 line, word_desc[] words, s_redirect[] redirects) = cmd.unpack();
        if (words.empty()) {
            return (ec, e);
        }
        (string cn, uint32 f) = words[0].unpack();
        if (cn == "echo" || cn == "pwd" || cn == "true" || cn == "false" || cn == "readonly" || cn == "export" || cn == "declare" || cn == "alias" ||
            cn == "unalias" || cn == "unset" || cn == "shopt" || cn == "dirs" || cn == "popd" || cn == "pushd") {
            (ec, e) = dispose_builtin (e_in, cn, cc_in, words, flags, false);
        }
//        string command_line;
    }

    function dispose_builtin(shell_env e_in, string cn, job_cmd cc_in, word_desc[] words, uint16 flags, bool subshell) internal pure returns (uint8 ec, shell_env e) {
        e = e_in;
    }
    uint8 constant EXIT_SUCCESS = 0;
    uint8 constant EXIT_FAILURE = 1;
    uint8 constant EX_BADUSAGE  = 2; // Usage messages by builtins result in a return status of 2
    function upgrade(TvmCell c) external pure {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

}
