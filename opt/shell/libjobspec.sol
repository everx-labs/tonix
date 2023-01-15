pragma ton-solidity >= 0.62.0;

import "libjobcommand.sol";

struct s_process {
    uint16 pid;	    // Process ID.
    s_wait status;  // The status of this command as returned by wait.
    uint8 running;  // Non-zero if this process is running.
    string command; // The particular program that is running.
}

enum JOB_STATE { JNONE, JRUNNING, JSTOPPED, RESERVED1, JDEAD, JMIXED }

struct s_wait {
    uint8 w_termsig;
    uint8 w_retcode;
    uint8 w_stopval;
    uint8 w_stopsig;
}

struct s_job {
    string wd;	      // The working directory at time of invocation.
    s_process[] pipe; // The pipeline of processes that make up this job.
    uint16 pgrp;      // The process ID of the process group (necessary).
    JOB_STATE state;  // The state that this job is in.
    uint8 flags;      // Flags word: J_NOTIFIED, J_FOREGROUND, or J_JOBCONTROL.
}

library libjobspec {

    // Values for the `running' field of a struct process
    uint8 constant PS_DONE     = 0;
    uint8 constant PS_RUNNING  = 1;
    uint8 constant PS_STOPPED  = 2;
    uint8 constant PS_RECYCLED = 4;

    uint8 constant J_FOREGROUND = 0x01; // Non-zero if this is running in the foreground
    uint8 constant J_NOTIFIED   = 0x02; // Non-zero if already notified about job state.
    uint8 constant J_JOBCONTROL = 0x04; // Non-zero if this job started under job control.
    uint8 constant J_NOHUP      = 0x08; // Don't send SIGHUP to job if shell gets SIGHUP.
    uint8 constant J_STATSAVED  = 0x10; // A process in this job had status saved via $!
    uint8 constant J_ASYNC      = 0x20; // Job was started asynchronously
    uint8 constant J_PIPEFAIL   = 0x40; // pipefail set when job was started
    uint8 constant J_WAITING    = 0x80; // one of a list of jobs for which we are waiting

    // flags for make_child()
    uint8 constant FORK_SYNC   = 0; // normal synchronous process
    uint8 constant FORK_ASYNC  = 1; // background process
    uint8 constant FORK_NOJOB  = 2; // don't put process in separate pgrp
    uint8 constant FORK_NOTERM = 4; // don't give terminal to any pgrp

    string[] constant JOB_SPEC_HEADER = ["jid", "pid", "status", "exec_line"];

    function as_row(job_spec js) internal returns (string[]) {
        (uint8 jid, uint16 pid, job_status status, string exec_line, ) = js.unpack();
        return [str.toa(jid), str.toa(pid), str.toa(uint8(status)), exec_line];
    }

    function jobstatus(job_status jst) internal returns (string) {
        if (jst == job_status.STOPPED) return "Stopped";
        if (jst == job_status.RUNNING) return "Running";
        return "Unknown";
    }
    function get_job_spec(string[] page_jobs, string[] page_vars, string[] page_spec) internal returns (job_spec) {
        uint8 jid = uint8(page_jobs.length);
        uint16 pid = vars.int_val("PPID", page_vars);
        job_status status = job_status.NEW;
        string exec_line = vars.val("COMMAND_LINE", page_vars);
        job_cmd[] commands = [libjobcommand.get_cmd(page_spec)];
        return job_spec(jid, pid, status, exec_line, commands);
    }
    function find_pid(job_spec[] jss, uint8 jid) internal returns (uint16) {
        for (job_spec js: jss)
            if (jid == js.jid)
                return js.pid;
    }
    function find_jid(job_spec[] jss, uint16 pid) internal returns (uint8) {
        for (job_spec js: jss)
            if (pid == js.pid)
                return js.jid;
    }

    function find_job(job_spec[] jss, string arg) internal returns (uint8 jid, uint16 pid) {
        if (arg.substr(0, 1) == '%') {
            jid = uint8(str.toi(arg.substr(1)));
            pid = find_pid(jss, jid);
        } else {
            pid = str.toi(arg);
            jid = find_jid(jss, pid);
        }
    }
}