pragma ton-solidity >= 0.62.0;

import "job_control.sol";
import "libjobspec.sol";
import "libtable.sol";
/*
enum job_status { UNDEF, NEW, RUNNING, STOPPED, DONE }
struct job_cmd {
    string cmd;
    string sarg;
    string argv;
    string exec_line;
    string[] params;
    string flags;
    uint16 n_args;
    uint8 ec;
    string last;
    string opterr;
    string redir_in;
    string redir_out;
}
struct job_spec {
    uint8 jid;
    uint16 pid;
    job_status status;
    string exec_line;
    job_cmd[] commands;
}
struct job_list {
    uint8 cur_job;
    job_spec[] jobs;
}
*/
contract jobs is job_control {

    using libtable for table;
    function _main(shell_env e_in, job_list j_in) internal override pure returns (uint8 rc, shell_env e, job_list j) {
        e = e_in;
        j = j_in;
        string[] page = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;
        (bool list_pid, bool list_changed, bool pid_only, bool running, bool stopped, bool run_cmd, , ) = e.flag_values("lnprsx");
        for (string line: page)
            e.puts(line);
        string out;
        table t;
        t.add_header(["", "", "", ""],
                    [uint(4),   5,      8,      20], libtable.CENTER);
        for (job_spec js: j.jobs) {
            (uint8 jid, uint16 pid, job_status status, string exec_line, job_cmd[] commands) = js.unpack();
            t.add_row(['[' + str.toa(jid) + ']+', str.toa(pid), libjobspec.jobstatus(status), exec_line]);
        }
        t.compute();
        out.append(t.out);
//        for (job_spec js: j.jobs) {
//            [1]+  Stopped                 du -sh /
//            out.append('[' + str.toa(jid) + ']' + '+' + " Stopped" + "\t\t" + exec_line);
        e.puts(out);
    }


    function _name() internal pure override returns (string) {
        return "jobs";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"jobs",
"[-lnprs] [jobspec ...] or jobs -x command [args]",
"Display status of jobs.",
"Lists the active jobs.  JOBSPEC restricts output to that job.\n\
Without options, the status of all active jobs is displayed.",
"-l        lists process IDs in addition to the normal information\n\
-n        lists only processes that have changed status since the last notification\n\
-p        lists process IDs only\n\
-r        restrict output to running jobs\n\
-s        restrict output to stopped jobs",
"If -x is supplied, COMMAND is run after all job specifications that appear in ARGS\n\
have been replaced with the process ID of that job's process group leader.",
"Returns success unless an invalid option is given or an error occurs.\n\
If -x is used, returns the exit status of COMMAND.");
    }

}
