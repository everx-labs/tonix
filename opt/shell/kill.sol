pragma ton-solidity >= 0.67.0;

import "job_control.sol";
import "libjobspec.sol";
import "libsyscall.sol";
import "libsignal.sol";

contract kill is job_control {

    using libtable for s_table;
    function _main(shell_env e_in, job_list j_in, job_cmd cc_in) internal override pure returns (uint8 rc, shell_env e, job_list j, job_cmd cc) {
        e = e_in;
        j = j_in;
        cc = cc_in;
//        string[] pg = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;
        string[] params = cc.params();
        if (cc.flags_empty() && params.empty()) {
            e.puts("kill: usage: kill [-s sigspec | -n signum | -sigspec] pid | jobspec ... or kill -l [sigspec]");
            return (rc, e, j, cc);
        }
        (, , bool list_names, bool list_names_alt, , , , ) = cc.flag_values("snlL");
        bool do_list = list_names || list_names_alt;
        (string[] sigspec, uint n_sigs) = libstring.split(vars.val("signal", e.environ[sh.ARRAYVAR]), ' ');
        if (n_sigs == 0) {
            rc = EXIT_FAILURE;
            return (rc, e, j, cc);
        }
        uint8 sig_no;
        string sig_name;

        if (do_list) {
            if (params.empty()) {
                for (uint i = 0; i < libsignal.SIGRTMIN; i++) {
                    ( , , string sval0) = libsignal.get_name(uint8(i), sigspec);
                    e.puts(format("{}) SIG{}\t", i, sval0));
                }
            }
            for (string param: params) {
                sig_no = _arg_to_signo(param, true, sigspec);
                ( , , string sval0) = libsignal.get_name(sig_no, sigspec);
                e.puts(sval0);
            }
            return (rc, e, j, cc);
        }
        uint8 nv = uint8(e.opt_value_int('n'));
        string sval = e.opt_value('s');
        bool success;
        (success, sig_no, sig_name) = libsignal.validate(nv, sval, sigspec);
        if (!success) {
            e.perror(sig_name);
            rc = EXIT_FAILURE;
            return (rc, e, j, cc);
        }
//            sig_no = use_num ? uint8(e.opt_value_int("n")) : use_name ? libsignal.get_no(e.opt_value('s'), sigspec) : libsignal.SIGTERM;
//            sig_name = libsignal.get_name(sig_no, sigspec);
        uint8 job_id;
        uint16 pid;
        for (string param: params) {
            if (param.substr(0, 1) == '%') {
                if (param == "%%")
                    nv = j_in.cur_job;
                else
                    nv = uint8(str.toi(param.substr(1)));
                pid = libjobspec.find_pid(j.jobs, nv);
            } else {
                pid = str.toi(param);
                job_id = libjobspec.find_jid(j.jobs, pid);
            }
            if (pid > 0 && job_id > 0)
                e.syscall(libsyscall.SYS_kill, [str.toa(pid), str.toa(sig_no)]);
            else {
                rc = EXIT_FAILURE;
                e.perror(param + ": arguments must be process or job IDs");
            }
        }
    }

    function _arg_to_signo(string arg, bool is_num, string[] sigspec) internal pure returns (uint8 sig_no) {
        if (is_num) {
            uint16 n = str.toi(arg);
            return n > libsignal.SIGRTMAX ? 0 : uint8(n);
        } else
            ( , sig_no, ) = libsignal.get_no(arg, sigspec);
    }

    function _name() internal pure override returns (string) {
        return "kill";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
"[-s sigspec | -n signum | -sigspec] pid | jobspec ... or kill -l [sigspec]",
"Send a signal to a job.",
"Send the processes identified by PID or JOBSPEC the signal named by SIGSPEC or SIGNUM.\n\
If neither SIGSPEC nor SIGNUM is present, then SIGTERM is assumed.",
"-s sig    SIG is a signal name\n\
-n sig    SIG is a signal number\n\
-l        list the signal names; if arguments follow `-l' they are assumed to be signal numbers for which names should be listed\n\
-L        synonym for -l",
"Kill is a shell builtin for two reasons: it allows job IDs to be used instead of process IDs,\n\
and allows processes to be killed if the limit on processes that you can create is reached.",
"Returns success unless an invalid option is given or an error occurs.");
    }
}
