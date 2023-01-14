pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";
//import "libjobspec.sol";
//import "libsyscall.sol";
import "libsignal.sol";

contract trap is pbuiltin {

    using libtable for table;

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {

        uint constant n_cols = 5;
        e = e_in;
        j = j_in;
        cc = cc_in;
        string[] page = e.environ[sh.JOB];
        rc = EXIT_SUCCESS;
        string[] params = cc.params();
        if (cc.flag_set('l')) {
            string[][] table;
            string[] index = ev[sh.ARRAYVAR]
            for (uint i = 0; i < n_cols; i++) {
                string[] row;
                for ()
        for (uint attr: index)
            table.push(as_row(attr));
        return libtable.format_rows(table, [uint(4), 3, 5, 2, 5, 5, 4, 6, 5, 3, 8, 8], libtable.CENTER);

            }
        }

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
                    ( , , string sval) = libsignal.get_name(uint8(i), sigspec);
                    e.puts(format("{}) SIG{}\t", i, sval));
                }
            }
            for (string param: params) {
                sig_no = _arg_to_signo(param, true, sigspec);
                ( , , string sval) = libsignal.get_name(sig_no, sigspec);
                e.puts(sval);
            }
            return (rc, e, j, cc);
        }
        uint8 nval = uint8(e.opt_value_int('n'));
        string sval = e.opt_value('s');
        bool success;
        (success, sig_no, sig_name) = libsignal.validate(nval, sval, sigspec);
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
                    nval = j_in.cur_job;
                else
                    nval = uint8(str.toi(param.substr(1)));
                pid = libjobspec.find_pid(j.jobs, nval);
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
        return "trap";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
"[-lp] [[arg] signal_spec ...]",
"Trap signals and other events.",
"Defines and activates handlers to be run when the shell receives signals or other conditions.\n\
ARG is a command to be read and executed when the shell receives the signal(s) SIGNAL_SPEC. If ARG is absent\n\
(and a single SIGNAL_SPEC is supplied) or `-', each specified signal is reset to its original value.\n\
If ARG is the null string each SIGNAL_SPEC is ignored by the shell and by the commands it invokes.\n\n\
If a SIGNAL_SPEC is EXIT (0) ARG is executed on exit from the shell.  If a SIGNAL_SPEC is DEBUG,\n\
ARG is executed before every simple command.  If a SIGNAL_SPEC is RETURN, ARG is executed each time\n\
a shell function or a script run by the . or source builtins finishes executing.  A SIGNAL_SPEC\n\
of ERR means to execute ARG each time a command's failure would cause the shell to exit when the -e option is enabled.\n\
If no arguments are supplied, trap prints the list of commands associated with each signal.",
"-l        print a list of signal names and their corresponding numbers\n\
-p        display the trap commands associated with each SIGNAL_SPEC",
"Each SIGNAL_SPEC is either a signal name in <signal.h> or a signal number.  Signal names are case insensitive\n\
and the SIG prefix is optional. A signal may be sent to the shell with "kill -signal $$".
"Returns success unless a SIGSPEC is invalid or an invalid option is given.");
    }
}
