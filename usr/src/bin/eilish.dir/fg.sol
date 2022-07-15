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
contract fg is job_control {

    using libtable for table;
    function _main(shell_env e_in, job_list j_in) internal override pure returns (uint8 rc, shell_env e, job_list j) {
        e = e_in;
        j = j_in;
        string[] page = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;
        string[] params = e.params();
        uint8 cur_job = params.empty() ? j_in.cur_job : uint8(str.toi(params[0]));
        j.jobs[cur_job].status = job_status.RUNNING;
    }


    function _name() internal pure override returns (string) {
        return "fg";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp("fg", "[job_spec]", "Move job to the foreground.",
        "Place the job identified by JOB_SPEC in the foreground, making it the current job.\n\
        If JOB_SPEC is not present, the shell's notion of the current job is used.",
        "", "", "Status of command placed in foreground, or failure if an error occurs.");
    }

}
