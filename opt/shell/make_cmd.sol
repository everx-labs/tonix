pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libcommand.sol";

contract make_cmd {

    using libfdt for s_of[];
    using libshellenv for shell_env;
    using libstring for string;
    using vars for string[];
    using libcommand for simple_com;

    function main(shell_env e_in, string input, string[] optstring) external pure returns (shell_env e, s_command cmd, job_cmd cc, string comm, string cmdline) {
        e = e_in;
        if (input.empty())
            return (e, cmd, cc, comm, cmdline);
        string[][] ev = e.environ;
        (string scmd, string argv) = _try_expand_alias(input, ev[sh.ALIAS]);
        string cmd_opt_string = vars.val(scmd, optstring);
        uint16 line;
        s_redirect[] redirects;
        string[] params;
        uint n_params;
        string redir_in;
        string redir_out;
        string pos_params;
        string serr;
        uint8 ec;
        string sflags;
        string sattrs;
        string sargs;
        string opterr;
        string[][2] opt_values;
        string exec_line;
        string sbody;
        if (!argv.empty()) {
            (sbody, redir_out) = libstring.csplit(argv, '>');
            (sargs, redir_in) = libstring.csplit(sbody, '<');
            if (!redir_in.empty())
                redirects.push(s_redirect(0, 0, 0, r_instruction.r_input_direction, uint8(str.toi(redir_in))));
            if (!redir_out.empty())
                redirects.push(s_redirect(1, 0, 0, r_instruction.r_output_direction, uint8(str.toi(redir_out))));
            (params, n_params) = libstring.split(sargs, ' ');
            (sflags, opt_values, serr, pos_params, sattrs) = _parse_params(params, cmd_opt_string);
            if (!serr.empty())
                ec = 2; //EX_BADUSAGE;
        }

        string[] cmd_types = vars.get_all_array_names(scmd, ev[sh.ARRAYVAR]);
        if (cmd_types.empty())
            e.perror("command not found: " + scmd);
        else {
            string sline = vars.get_best_record(cmd_types, ev[sh.SERVICE]);
            string shell_name = vars.val("SHELL", ev[sh.VARIABLE]);
            if (!sline.empty()) {
                (string attrs, string name, string executor) = vars.split_var_record(sline);
                if (name == "builtin")
                    executor = vars.val(scmd, ev[sh.BUILTIN]);
                if (str.strchr(executor, '$') > 0) {
                    sline = vars.get_pool_record(executor.substr(1), ev[sh.FUNCTION]);
                    (attrs, name, sbody) = vars.split_var_record(sline);
                    if (str.strchr(attrs, 'f') > 0) {
                        executor = name + "() " + sbody;
                        executor.translate(";", "\n");
                        executor.translate("$0", shell_name);
                        executor.translate("$@", input);
                        line = 1;
                    }
                }
                exec_line = executor + " " + input;
            }
        }
        word_desc[] words;
        uint16 flags;
        simple_com value = simple_com(flags, line, words, redirects);
        value.add_word(scmd);
        for (string arg: params)
            value.add_word(arg);
        cmd = s_command(command_type.cm_simple, flags, line, redirects, value);
        (params, n_params) = libstring.split(pos_params, ' ');
        string last = n_params == 0 ? scmd : params[n_params - 1];
        cc = job_cmd(scmd, input, argv, exec_line, params, sflags, uint16(n_params), ec, last, opterr, redir_in, redir_out);
        comm = scmd;
        cmdline = exec_line;

        e.set_env_vars(
            ["COMMAND", "COMMAND_LINE", "PARAMS", "FLAGS", "ARGV", "@", "_", "OPTERR", "REDIR_IN", "REDIR_OUT"],
            [scmd, exec_line, pos_params, sflags, argv, input, last, opterr, redir_in, redir_out]);
        e.environ[sh.VARIABLE].set_int_val("#", uint16(n_params));
        e.environ[sh.VARIABLE].set_int_val("?", ec);
    }

    function _try_expand_alias(string input, string[] aliases) internal pure returns (string scmd, string argv) {
        (scmd, argv) = libstring.csplit(input, ' ');
        string expanded = vars.val(scmd, aliases);
        if (!expanded.empty())
            return _try_expand_alias(expanded + " " + argv, aliases);
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
