pragma ton-solidity >= 0.62.0;

import "job_control.sol";
import "libjobspec.sol";
import "libtable.sol";

contract fg is job_control {

    using libtable for s_table;
    function _main(shell_env e_in, job_list j_in, job_cmd cc_in) internal override pure returns (uint8 rc, shell_env e, job_list j, job_cmd cc) {
        e = e_in;
        j = j_in;
        cc = cc_in;
        string[] page = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;
        string[] params = cc.params();
        uint8 cur_job = params.empty() ? j_in.cur_job : uint8(str.toi(params[0]));
        j.jobs[cur_job].status = job_status.RUNNING;
    }

    function _name() internal pure override returns (string) {
        return "fg";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(_name(), "[job_spec]", "Move job to the foreground.",
"Place the job identified by JOB_SPEC in the foreground, making it the current job. If JOB_SPEC is not present,\n\
the shell's notion of the current job is used.",
        "", "", "Status of command placed in foreground, or failure if an error occurs.");
    }

}
