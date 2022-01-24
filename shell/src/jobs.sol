pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract jobs is Shell {

    function _index_of(string s_array, string arg) internal pure returns (uint) {
        (string[] fields, uint n_fields) = stdio.split(s_array, " ");
        for (uint i = 0; i < n_fields; i++)
            if (arg == fields[i])
                return i + 1;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"jobs",
"[-lnprs] [jobspec ...] or jobs -x command [args]",
"Display status of jobs.",
"Lists the active jobs.  JOBSPEC restricts output to that job. Without options, the status of all active jobs is displayed.",
"-l        lists process IDs in addition to the normal information\n\
-n        lists only processes that have changed status since the last notification\n\
-p        lists process IDs only\n\
-r        restrict output to running jobs\n\
-s        restrict output to stopped jobs",
"If -x is supplied, COMMAND is run after all job specifications that appear in ARGS have been replaced with the process ID\n\
of that job's process group leader.",
"Returns success unless an invalid option is given or an error occurs. If -x is used, returns the exit status of COMMAND.");
    }
}
