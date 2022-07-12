pragma ton-solidity >= 0.62.0;

//import "pbuiltin.sol";
import "libshellenv.sol";
import "libprocenv.sol";
import "xio.sol";
contract esh {

    using xio for s_of;
    using libstring for string;
    using str for string;

    function print_errors(shell_env e_in) external pure returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] page = e.environ[sh.ERRNO];
        string cmd = vars.val("COMMAND", e.environ[sh.SPECVARS]);
        string[] pipeline = e.environ[sh.PIPELINE];
        string exec_line = pipeline[pipeline.length - 1];
        (string attrs, , string value) = vars.split_var_record(exec_line);
//        string cmd = value.csplit(' ')
        uint8 return_code = uint8(vars.int_val("RETURN_CODE", page));
        uint8 error_no = uint8(vars.int_val("ERRNO", page));
        uint8 exit_status = uint8(vars.int_val("EXIT_STATUS", page));
        if (return_code + error_no + exit_status > 0) {
            s_of res = e.ofiles[libfdt.STDERR_FILENO];
            string err_msg = "-eilish: ";
            string reason = vars.val("REASON", page);
            string em;
            if (error_no > 0) {
//                err_msg.append(err.strerror(en));
                em = vars.val(str.toa(error_no), e.environ[sh.ERRORSTR]);
            }
            if (return_code > 0) {
                //em = vars.val(str.toa(return_code), e.environ[sh.ERRBUILTIN]);
                em = vars.val("BUILTIN_MOD", page) + ": ";
                em.append(reason);
            }
            err_msg.append(em);
            if (exit_status > 0)
                err_msg.append("exit code: " + str.toa(exit_status));
            rc = return_code;
            res.fputs(err_msg);
            e.ofiles[libfdt.STDERR_FILENO] = res;
        }
        delete e.environ[sh.PIPELINE][pipeline.length - 1];
    }

    function export_env(shell_env e_in) external pure returns (p_env p, string p_comm, string p_pid) {
        p = p_env(e_in.ofiles, e_in.cwd, e_in.umask, e_in.environ);
        p_comm = vars.val("COMMAND", e_in.environ[sh.SPECVARS]);
        p_pid = vars.val("PPID", e_in.environ[sh.VARIABLE]);
    }

    function parse_input(shell_env e_in, string input) external pure returns (shell_env e) {
        e = e_in;
        string[][] ev = e.environ;
        if (input.empty())
            return e;
        (string cmd_raw, string argv) = libstring.csplit(input, ' ');
        string cmd_expanded = vars.val(cmd_raw, ev[sh.ALIAS]);
        string sinput = cmd_expanded.empty() ? input : cmd_expanded + " " + argv;
        string cmd;
        (cmd, argv) = libstring.csplit(sinput, ' ');
        string cmd_opt_string = vars.val(cmd, ev[sh.OPTSTRING]);
        string sflags;
        string redir_in;
        string redir_out;
        uint8 ec;
        string[][2] opt_values;
        string pos_params;
        string res;
        string serr;
        string[] params;
        uint n_params;
        string last_param;
        string sargs = argv;
        if (!argv.empty()) {
            string sbody;
            (sbody, redir_out) = argv.csplit(">");
            (sargs, redir_in) = sbody.csplit("<");
            (params, n_params) = sargs.split(" ");
            (sflags, opt_values, serr, pos_params, ) = _parse_params(params, cmd_opt_string);
            if (!serr.empty())
                ec = EX_BADUSAGE;
            for (string arg: params) {
                if (str.strchr(arg, '$') > 0) {
                    string ref = arg.val("$", " ");
                    if (str.strchr(ref, '{') > 0)
                        ref.unwrap();
                    string ref_val;// = vars.val(ref, pool);
                    pos_params.translate(arg, ref_val);
                    sargs.translate(arg, ref_val);
                }
            }
        }
        string cmd_type = vars.get_array_name(cmd, ev[sh.ARRAYVAR]);
        string cattrs;
        string exec_engine;
        if (cmd_type == "builtin") {
            cattrs = "-b";
            exec_engine = "./bin/eilish.dir/builtin";
            res = "./bin/eilish.dir/builtin " + cmd + " " + sargs;
        } else if (cmd_type == "command") {
            cattrs = "-c";
            exec_engine = "./bin/eilish.dir/command";
            res = "./bin/eilish.dir/command " + cmd + " " + sargs;
        } else if (cmd_type == "sysmain") {
            cattrs = "-s";
            exec_engine = "./bin/eilish.dir/command";
            res = "./bin/eilish.dir/command " + cmd + " " + sargs;
        } else if (cmd_type == "rsu") {
            cattrs = "-r";
            exec_engine = "./sbin/rsu";
            res = "./sbin/rsu " + cmd + " " + sargs;
        } else if (cmd_type == "ki") {
            cattrs = "-k";
            exec_engine = "./sbin/ki";
            res = "./sbin/ki " + cmd + " " + sargs;
        } else if (cmd_type == "function") {
            cattrs = "-f";
            exec_engine = "./eilish";
            res = "./tosh execute_function " + sinput;
        } else {
            if (!cmd_type.empty())
                serr.append("unknown commmand type: " + cmd_type);
            else
                serr.append("command not found: " + cmd);
            res = "echo " + serr;
            ec = EXIT_FAILURE;
        }
        e.environ[sh.PIPELINE].push(cattrs + " " + exec_engine + "=" + cmd + " " + sargs);
        // -------------
        (params, n_params) = pos_params.split(" ");
        last_param = pos_params.empty() ? cmd : params[n_params - 1];
        s_dirent[] pas;
        for (string pm: params)
            pas.push(s_dirent(0, 0, pm));
        e.environ[sh.SPECVARS] = [
            "COMMAND=" + cmd,
            "COMMAND_LINE=" + res,
            "PARAMS=" + pos_params,
            "FLAGS=" + sflags,
            "ARGV=" + sinput,
            "#=" + str.toa(n_params),
            "@=" + sargs,
            "?=" + str.toa(ec),
            "_=" + last_param,
            "OPTERR=" + serr,
            "REDIR_IN=" + redir_in,
            "REDIR_OUT=" + redir_out
        ];
        e.environ[sh.OPTARGS] = vars.as_var_list("", opt_values);
    }

    function _parse_params(string[] params, string opt_string) internal pure returns (string sflags, string[][2] opt_values, string serr, string pos_params, string sattrs) {
        uint n_params = params.length;
        uint opt_str_len = opt_string.byteLength();
        bool expect_options = true;
        for (uint i = 0; i < n_params; i++) {
            string token = params[i];
            bytes bt = bytes(params[i]);
            uint t_len = bt.length;//token.byteLength();
            if (t_len == 0)
                continue;
//            if (expect_options && token.substr(0, 1) == "-") {
            if (expect_options && bt[0] == '-') {
                string o;
                bytes bo;
                string val;
                if (t_len == 1)
                    continue; // stdin redirect
//                if (token.substr(1, 1) == "-") {
                if (bt[1] == '-') {
                    if (t_len == 2) { // arg separator
                        expect_options = false;
                        continue;
                    }
                    o = token.substr(2); // long option
                    bo = bt[2 : ];
                } else {
                    // short option(s)
                    o = token.substr(1);
                    bo = bt[1 : ];
                    if (t_len > 2) {     // short option sequence has no value
                        for (uint j = 1; j < t_len; j++)
                            sflags.append(token.substr(j, 1));
                        continue;
                    }
                }
                uint o_len = bo.length;//o.byteLength();
                if (o_len == 1) {
                    byte b = bo[0];//bytes(o)[0];
                    uint p = str.strchr(opt_string, b); // _strstr() for long options ?
                    if (p > 0) {
                        if (p < opt_str_len && opt_string.substr(p, 1) == ":") {
                            if (i + 1 < n_params) {
                                val = params[i + 1];
                                i++;
                            } else
                                serr.append(format("error: missing option {} value in {} at {} pos {}\n", o, opt_string, p, i));
                        } else
                            val = o;//o;
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
//            } else if (token.substr(0, 1) == "+")
            } else if (bt[0] == '+')
                sattrs.append(token);
            else {
                if (pos_params.empty())
                    pos_params = token;
                else
                    pos_params.append(" " + token);
            }
        }
    }

    uint8 constant EXIT_SUCCESS = 0;
    uint8 constant EXIT_FAILURE = 1;
    uint8 constant EX_BADUSAGE  = 2; // Usage messages by builtins result in a return status of 2
    function upgrade(TvmCell c) external pure {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

}

