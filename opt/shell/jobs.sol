pragma ton-solidity >= 0.67.0;

import "job_control.sol";
import "libjobspec.sol";
import "libtable.sol";

contract jobs is job_control {

    using libtable for s_table;
    function _main(shell_env e_in, job_list j_in, job_cmd cc_in) internal override pure returns (uint8 rc, shell_env e, job_list j, job_cmd cc) {
        e = e_in;
        j = j_in;
        cc = cc_in;
        string[] page = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;
        (bool list_pid, bool list_changed, bool pid_only, bool running, bool stopped, bool run_cmd, , ) = cc.flag_values("lnprsx");
        string out;
        string spid = vars.val("PPID", e.environ[sh.VARIABLE]);
        s_table t;
//        t.add_header(["", "", "", ""],
//                    [uint(4),   5,      8,      20], libtable.CENTER);
        for (job_spec js: j.jobs) {
            (uint8 jid, uint16 pid, job_status status, string exec_line, ) = js.unpack();
            t.add_row(['[' + str.toa(jid) + ']+', str.toa(pid), libjobspec.jobstatus(status), exec_line]);
        }
        for (string line: page) {
            (string attrs, string name, string value) = vars.split_var_record(line);
            job_status status = str.strchr(attrs, "r") > 0 ? job_status.RUNNING : str.strchr(attrs, "s") > 0 ? job_status.STOPPED : job_status.UNDEF;
            string exec_line = value;
            t.add_row(['[' + name + ']+', spid, libjobspec.jobstatus(status), exec_line]);
        }
        t.compute();
//        out.append(t.out);
        if (run_cmd) {
        }
        e.puts(out);
    }

    function _name() internal pure override returns (string) {
        return "jobs";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
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
