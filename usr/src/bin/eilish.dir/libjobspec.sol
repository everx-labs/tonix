pragma ton-solidity >= 0.62.0;

import "libcommand.sol";

library libjobspec {
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
        job_cmd[] commands = [libcommand.get_cmd(page_spec)];
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
}