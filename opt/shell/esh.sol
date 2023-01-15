pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "xio.sol";
import "job_h.sol";
import "libcommand.sol";

contract esh {

    using xio for s_of;
    using libstring for string;
    using str for string;
    using libshellenv for shell_env;
    using libcommand for simple_com;
    using vars for string[];

    function print_errors(shell_env e_in, string[] errmsg, job_spec cj_in, s_command cmd_in) external pure returns (uint8 rc, shell_env e, string stdout, string stderr, string comm, string cmdline, job_spec cj, job_cmd cc, s_command cmd) {
        cmd = cmd_in;
        e = e_in;
        cj = cj_in;
        (uint8 jid, uint16 pid, job_status status, string exec_line, job_cmd[] commands) = cj.unpack();
        uint ncomms = commands.length;
        if (status == job_status.NEW) {
            if (ncomms > 0) {
                cmdline = exec_line;
                cj.status = job_status.RUNNING;
                cc = commands[0];
                e = _job_env(e, cc);
                comm = cc.cmd;
            }
        } else if (status == job_status.RUNNING) {
            for (uint i = 0; i < ncomms - 1; i++)
                commands[i] = commands[i + 1];
                commands.pop();
            if (commands.length > 0) {
                cc = commands[0];
                e = _job_env(e, cc);
                comm = cc.cmd;
            }
        }
        string[] page = e.environ[sh.ERRNO];
        (bool errexit, bool notify, bool onecmd, bool monitor, , , , ) = e.shell_option_values("ebtm");
        (uint return_code, uint error_no, uint exit_status, ) = e.env_var_int_values(["RETURN_CODE", "ERRNO", "EXIT_STATUS"]);
        if (return_code + error_no + exit_status > 0) {
            s_of res = e.ofiles[libfdt.STDERR_FILENO];
            string err_msg = "-eilish: ";
            string reason = vars.val("REASON", page);
            string em;
            if (error_no > 0) {
                em = vars.val(str.toa(error_no), errmsg);
                e.environ[sh.ERRNO].unset_var("ERRNO");
            }
            if (return_code > 0) {
                em = vars.val("BUILTIN_MOD", page) + ": ";
                em.append(reason);
            }
            err_msg.append(em);
            if (exit_status > 0)
                err_msg.append("exit code: " + str.toa(exit_status));
            res.fputs(err_msg + "\n");
            e.ofiles[libfdt.STDERR_FILENO] = res;
        }
        (stdout, stderr) = e.ofiles.fdflush();
    }

    function _job_env(shell_env e_in, job_cmd c) internal pure returns (shell_env e) {
        e = e_in;
        (string cmd, string sarg, string argv, string exec_line, string[] params, string flags, uint16 n_args, uint8 ec, string last, string opterr, string redir_in, string redir_out) = c.unpack();
        e.set_env_vars(
            ["COMMAND", "COMMAND_LINE", "PARAMS", "FLAGS", "ARGV", "@", "_", "OPTERR", "REDIR_IN", "REDIR_OUT"],
            [cmd, exec_line, libstring.join_fields(params, ' '), flags, argv, sarg, last, opterr, redir_in, redir_out]);
        e.environ[sh.VARIABLE].set_int_val("#", n_args);
        e.environ[sh.VARIABLE].set_int_val("?", ec);
    }

    function export_env(shell_env e_in) external pure returns (shell_env e, string p_comm, string p_pid) {
        e = e_in;
        p_comm = vars.val("COMMAND", e_in.environ[sh.VARIABLE]);
        p_pid = vars.val("PPID", e_in.environ[sh.VARIABLE]);
    }

    using libfdt for s_of[];

    function main(shell_env e_in, string input, string[] optstring) external pure returns (shell_env e, job_spec cj, s_command cmd) {
        return _parse_input(e_in, input, optstring);
    }

    function parse_input(shell_env e_in, string input, string[] optstring) external pure returns (shell_env e, job_spec cj, s_command cmd) {
        return _parse_input(e_in, input, optstring);
    }

    function _parse_input(shell_env e_in, string input, string[] optstring) internal pure returns (shell_env e, job_spec cj, s_command cmd) {
        e = e_in;
        string[][] ev = e.environ;
        (bool xtrace, bool verbose, , bool noexec, , , , ) = e.shell_option_values("xvun");
        e.ofiles.fdflush();
        if (input.empty())
            return (e, cj, cmd);
        (string cmd_raw, string argv) = libstring.csplit(input, ' ');
        string cmd_expanded = vars.val(cmd_raw, ev[sh.ALIAS]);
        string sinput = cmd_expanded.empty() ? input : cmd_expanded + " " + argv;
        string scmd = cmd_expanded.empty() ? cmd_raw : cmd_expanded;
        e.ofiles[libfdt.STDIN_FILENO].fputs(sinput);
        string cmd_opt_string = vars.val(scmd, optstring);

        word_desc[] words;
        command_type c_type = command_type.cm_simple;
        uint16 flags;
        uint16 line = 1;
        s_redirect[] redirects;

        string sargs = argv;
        string sattrs;
        uint8 ec;
        string last;
        string opterr;
        string[][2] opt_values;
        string redir_in;
        string redir_out;
        string sflags;
        string exec_line;
        string[] params;
        string pos_params;
        string serr;
        uint n_params;
        if (!argv.empty()) {
            (params, n_params) = argv.split(" ");
            string sbody;
            (sbody, redir_out) = argv.csplit(">");
            (sargs, redir_in) = sbody.csplit("<");
            (params, n_params) = sargs.split(" ");
            (sflags, opt_values, serr, pos_params, sattrs) = _parse_params(params, cmd_opt_string);
            if (!serr.empty())
                ec = 2; //EX_BADUSAGE;
            if (!redir_in.empty())
                redirects.push(s_redirect(0, 0, 0, r_instruction.r_input_direction, uint8(str.toi(redir_in))));
            if (!redir_out.empty())
                redirects.push(s_redirect(1, 0, 0, r_instruction.r_output_direction, uint8(str.toi(redir_out))));
        }
        last = pos_params.empty() ? scmd : params[n_params - 1];

        string[] cmd_types = vars.get_all_array_names(scmd, ev[sh.ARRAYVAR]);
        if (cmd_types.empty())
            e.perror("command not found: " + scmd);
        else {
            string sline = vars.get_best_record(cmd_types, ev[sh.SERVICE]);
            if (!sline.empty()) {
                (, string name, string exec_engine) = vars.split_var_record(sline);
                if (name == "builtin")
                    exec_engine = vars.val(scmd, ev[sh.BUILTIN]);
                exec_line = exec_engine + " " + scmd + " " + sargs;
                if (!noexec)
                    e.environ[sh.NEXTCMD] = [exec_line];
            } else
                e.perror("unknown commmand types: " + libstring.join_fields(cmd_types, ' '));
        }

        uint16 ppid = vars.int_val("PPID", e.environ[sh.VARIABLE]);
        uint8 job_id = uint8(e.environ[sh.JOB].length);

        job_cmd jc = job_cmd(scmd, sinput, argv, exec_line, params, sflags, uint16(n_params), ec, last, opterr, redir_in, redir_out);
        cj = job_spec(job_id, ppid, job_status.NEW, exec_line, [jc]);

        simple_com value = simple_com(flags, line, words, redirects);
        value.add_word(scmd);
//        words.push(w);
        for (string arg: params) {
            value.add_word(arg);
        }
        cmd = s_command(c_type, flags, line, redirects, value);

        if (verbose)
            e.puts(sinput);
        if (xtrace)
            e.puts("+ " + exec_line);
        e.environ[sh.OPTARGS] = vars.as_var_list("", opt_values);
    }

    function _parse_params(string[] params, string opt_string) internal pure returns (string sflags, string[][2] opt_values, string serr, string pos_params, string sattrs) {
        uint n_params = params.length;
        uint opt_str_len = opt_string.byteLength();
        bool expect_options = true;
        for (uint i = 0; i < n_params; i++) {
            string token = params[i];
            if (token == "--") { // arg separator
                expect_options = false;
                continue;
            }
            if (token == "-")
                continue; // stdin redirect
            bytes bt = bytes(token);
            uint t_len = bt.length;
            if (t_len == 0)
                continue;
            if (!expect_options || bt[0] != '-' && bt[0] != '+') {
                if (pos_params.empty())
                    pos_params = token;
                else
                    pos_params.append(" " + token);
                continue;
            }
            if (bt[0] == '-') {
                string o;
                bytes bo;
                string val;
                if (bt[1] == '-') {
                    o = token.substr(2); // long option
                    bo = bt[2 : ];
                } else {
                    // short option(s)
                    o = token.substr(1);
                    bo = bt[1 : ];
                    if (t_len > 2) {     // short option sequence has no value
                        sflags.append(o);
                        continue;
                    }
                }
                if (bo.length == 1) {
                    uint p = str.strchr(opt_string, bo[0]); // _strstr() for long options ?
                    if (p > 0) {
                        if (p < opt_str_len && opt_string.substr(p, 1) == ":") {
                            if (i + 1 < n_params) {
                                val = params[i + 1];
                                i++;
                            } else
                                serr.append(format("error: missing option {} value in {} at {} pos {}\n", o, opt_string, p, i));
                        } else
                            val = o;
                        opt_values.push([o, val]);
                        sflags.append(o);
                    } else
                        serr.append("error: unrecognized option: " + o + " opt_string: " + (opt_string.empty() ? "empty" : opt_string) + "\n");
                } else {
                    if (o == "help" || o == "version")
                        opt_values.push([o, o]);
                    else
                        serr.append("error: unrecognized option: " + o + ". Long options are not yet supported\n");
                }
            } else if (bt[0] == '+')
                sattrs.append(token);
        }
    }

    function upgrade(TvmCell c) external pure {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

}
