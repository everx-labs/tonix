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
contract disown is job_control {

    using libtable for table;
    function _main(shell_env e_in, job_list j_in) internal override pure returns (uint8 rc, shell_env e, job_list j) {
        e = e_in;
        (bool remove_all, bool nohup, bool pid_only, bool running, , , , ) = e.flag_values("har");
        if (remove_all) {
            return (rc, e, j);
        }
        j = j_in;
        string[] page = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;

        if (!remove_all) {
        }

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
        return "disown";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"disown",
"[-h] [-ar] [jobspec ... | pid ...]",
"Remove jobs from current shell.",
"Removes each JOBSPEC argument from the table of active jobs.  Without\n\
any JOBSPECs, the shell uses its notion of the current job.",
"-a        remove all jobs if JOBSPEC is not supplied\n\
-h        mark each JOBSPEC so that SIGHUP is not sent to the job if the shell receives a SIGHUP\n\
-r        remove only running jobs",
"",
"Returns success unless an invalid option or JOBSPEC is given.");
    }

}
