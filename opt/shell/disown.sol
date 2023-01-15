pragma ton-solidity >= 0.62.0;

import "job_control.sol";
import "libjobspec.sol";
import "libtable.sol";

contract disown is job_control {

    using libtable for s_table;
    function _main(shell_env e_in, job_list j_in, job_cmd cc_in) internal override pure returns (uint8 rc, shell_env e, job_list j, job_cmd cc) {
        e = e_in;
        cc = cc_in;
        (bool remove_all, bool nohup, bool running, , , , , ) = cc.flag_values("ahr");
        if (remove_all) {
            delete e.environ[sh.JOB];
            delete e.environ[sh.RUNNING];
            delete e.environ[sh.STOPPED];
            return (rc, e, j, cc);
        } else if (running) {
            delete e.environ[sh.RUNNING];
            for (job_spec js: j_in.jobs) {
                if (js.status != job_status.RUNNING)
                    j.jobs.push(js);
            }
            return (rc, e, j, cc);
        }
        j = j_in;
        string[] params = cc.params();
//        string[] page = e.environ[running ? sh.RUNNING : sh.JOB];
        rc = EXIT_SUCCESS;
//        string spid = vars.val("PPID", e.environ[sh.VARIABLE]);
        /*table t;
        t.add_header(["", "", "", ""],
                    [uint(6), 5, 8, 30], libtable.CENTER);
        for (job_spec js: j.jobs) {
            (uint8 jid, uint16 pid, job_status status, string exec_line, ) = js.unpack();
            t.add_row(['[' + str.toa(jid) + ']+', str.toa(pid), libjobspec.jobstatus(status), "\t\t" + exec_line]);
        }

        for (string line: page) {
            (string attrs, string name, string value) = vars.split_var_record(line);
            job_status status = str.strchr(attrs, "r") > 0 ? job_status.RUNNING : str.strchr(attrs, "s") > 0 ? job_status.STOPPED : job_status.UNDEF;
            string exec_line = value;
            if (!running || status == job_status.RUNNING)
                t.add_row(['[' + name + ']+', spid, libjobspec.jobstatus(status), "\t\t" + exec_line]);
        }
        t.compute();
        string out;
        out.append(t.out);
        e.puts(out);*/

        uint8 nval;
        uint8 job_id;
        uint16 pid;
        for (string param: params) {
            if (param == "%%")
                job_id = j_in.cur_job;
            else
                (job_id, pid) = libjobspec.find_job(j.jobs, param);
            /*if (param.substr(0, 1) == '%') {
                if (param == "%%")
                    nval = j_in.cur_job;
                else
                    nval = uint8(str.toi(param.substr(1)));
                pid = libjobspec.find_pid(j.jobs, nval);
            } else {
                pid = str.toi(param);
                job_id = libjobspec.find_jid(j.jobs, pid);
            }*/
            (job_id, pid) = libjobspec.find_job(j.jobs, param);
//            if (pid > 0 && job_id > 0)
        }

//        e.puts(out);
    }

    function _name() internal pure override returns (string) {
        return "disown";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
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
