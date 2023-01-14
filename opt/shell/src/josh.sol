pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libjobspec.sol";
import "libcommand.sol";

contract josh {

    using libtable for s_table;
    using xio for s_of;
    using libstring for string;
    using str for string;
    using libshellenv for shell_env;
    using libtable for s_table;

    function main(shell_env e_in, job_list j_in, job_spec js_in, s_command cmd_in, job_cmd cc_in) external pure returns (shell_env e, job_list j, job_spec js, s_command cmd, job_cmd cc) {
        e = e_in;
        j = j_in;
        js = js_in;
        cmd = cmd_in;
        cc = cc_in;
        (command_type c_type, uint16 flags, uint16 line, s_redirect[] redirects, simple_com value) = cmd_in.unpack();
        if (c_type == command_type.cm_simple) {
            (uint16 cflags, uint16 cline, word_desc[] words, s_redirect[] credirects) = value.unpack();
            if (words.empty()) {
                return (e, j, js, cmd, cc);
            }
            (string cn, uint32 f) = words[0].unpack();
            if (cn == "fg") {

            }
        }
    }
    function print_jobs(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        j = j_in;
        e = e_in;
    }

    function print_jobs_full(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        j = j_in;
        e = e_in;
        string s;
        s_table t0;
//        t0.add_header(["jid", "pid", "status", "exec_line"],
//                    [uint(2),   5,      8,      12], libtable.CENTER);
        for (job_spec js: j.jobs)
            t0.add_row(libjobspec.as_row(js));
        t0.compute();
//        s.append(t0.out);
        s_table t;
//        t.add_header(["cmd", "sarg", "argv", "exec_line", "params", "flags", "n_args", "ec", "last", "opterr", "redir_in", "redir_out"],
//                     [uint(10), 50,  50,        50,         50,     20,         3,      3,      10,     30,     20,         20],
//                    libtable.CENTER);
//        for (job_spec js: j.jobs)
//            for (job_cmd c: js.commands)
//                t.add_row(libcommand.as_row(c));

        t.compute();
//        s.append(t.out);
        e.puts(s);
    }

    function dispatch(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        e = e_in;
        j = j_in;
        string[][] ev = e.environ;
        job_spec js = libjobspec.get_job_spec(ev[sh.JOB], ev[sh.VARIABLE], ev[sh.SPECVARS]);
        j.jobs.push(js);
        j.cur_job = js.jid;
    }

    function disown(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        e = e_in;
//        j = j_in;
    }

    function suspend(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        e = e_in;
        j = j_in;
    }

    function fg(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        e = e_in;
        j = j_in;
    }

    function bg(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        e = e_in;
        j = j_in;
    }

    function wait(shell_env e_in, job_list j_in) external pure returns (shell_env e, job_list j) {
        e = e_in;
        j = j_in;
    }

    function upgrade(TvmCell c) external pure {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

}

