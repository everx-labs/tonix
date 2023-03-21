pragma ton-solidity >= 0.67.0;

import "libshellenv.sol";
import "libcommand.sol";
import "libjobcommand.sol";

contract execute_cmd {

    using libstring for string;
    using vars for string[];
    using vars for string;
    uint8 constant NO_PIPE = 255;

    function main(shell_env e_in, s_command cmd_in, job_cmd cc_in) external pure returns (shell_env e, s_command cmd, job_cmd cc, string comm, string cmdline) {
        uint8 result;
        uint8[] fds_to_close;
        (result, e, cmd, cc) = execute_command_internal(e_in, cmd_in, cc_in, false, NO_PIPE, NO_PIPE, fds_to_close);
        comm = cc.cmd;
        cmdline = cc.exec_line;
    }
    /*function execute_command(shell_env e_in, s_command cmd_in, job_cmd cc_in) external pure returns (shell_env e) {
        uint8 result;
        uint8[] fds_to_close;
        (result, e) = execute_command_internal(e_in, cmd_in, cc_in, false, NO_PIPE, NO_PIPE, fds_to_close);
    }*/

    function execute_command_internal(shell_env e_in, s_command cmd_in, job_cmd cc_in, bool asynchronous, uint8 pipe_in, uint8 pipe_out, uint8[] fds_to_close) internal pure returns (uint8 ec, shell_env e, s_command cmd, job_cmd cc) {
        e = e_in;
        cmd = cmd_in;
        cc = cc_in;
        (command_type c_type, uint16 flags, uint16 line, s_redirect[] redirects, simple_com value) = cmd_in.unpack();
        if (c_type == command_type.cm_simple) {
            (ec, e, cc) = execute_simple_command (e_in, value, cc_in, asynchronous, pipe_in, pipe_out, fds_to_close);
        }
    }

    function execute_simple_command(shell_env e_in, simple_com cmd, job_cmd cc_in, bool asynchronous, uint8 pipe_in, uint8 pipe_out, uint8[] fds_to_close) internal pure returns (uint8 ec, shell_env e, job_cmd cc) {
        e = e_in;
        cc = cc_in;
        (uint16 flags, uint16 line, word_desc[] words, s_redirect[] redirects) = cmd.unpack();
        if (words.empty()) {
            return (ec, e, cc);
        }
        (string cn, uint32 f) = words[0].unpack();
//        string executor = vars.val(cn, e.environ[sh.BUILTIN]);
//        (string exec_driver, string exec_module) = libstring.csplit(executor, ' ');
        (ec, e, cc) = execute_builtin (e_in, cn, cc_in, words, flags, false);
        /*if (cn == "echo" || cn == "pwd" || cn == "true" || cn == "false" || cn == "readonly" || cn == "export" || cn == "declare" || cn == "alias" ||
            cn == "unalias" || cn == "unset" || cn == "shopt" || cn == "dirs" || cn == "popd" || cn == "pushd") {
            (ec, e) = execute_builtin (e_in, cn, cc_in, words, flags, false);
        }
//        string command_line;*/
    }

    function execute_builtin (shell_env e_in, string cn, job_cmd cc_in, word_desc[] words, uint16 flags, bool subshell) internal pure returns (uint8 ec, shell_env e, job_cmd cc) {
        e = e_in;
        cc = cc_in;
        (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fh) = cc_in.flag_values("abcdefgh");
        (bool fi, bool fj, bool fk, bool fl, bool fm, bool fn, bool fo, bool fp) = cc_in.flag_values("ijklmnop");
        (bool fq, bool fr, bool fs, bool ft, bool fu, bool fv, bool fw, bool fx) = cc_in.flag_values("qrstuvwx");
        (bool fy, bool fz, bool fE, bool fL, bool fP, bool fA, bool fR, bool fT) = cc_in.flag_values("yzELPART");
        string[] args = libjobcommand.params(cc_in);
        bool no_flags = cc_in.flags_empty();
        bool no_args = args.empty();
        string out;
        string pf;
        function (shell_env, job_cmd) returns (shell_env) fun;
        string[] page;
        if (cn == "true")
            ec = EXIT_SUCCESS;
        else if (cn == "false")
            ec = EXIT_FAILURE;
        else if (cn == "echo") {
            e.puts(libstring.join_fields(args, " "));
            if (!fn)
                e.putchar('\n');
        } else if (cn == "pwd") {
            if (!fP) {
                uint16 wd = e.get_cwd();
                if (wd == 0) {
                    e.perror("current directory cannot be read");
                    ec = EXIT_FAILURE;
                } else
                    e.puts(vars.val("PWD", e.environ[sh.VARIABLE]));
            }
        } else if (cn == "readonly" || cn == "export" || cn == "declare" || cn == "alias" || cn == "shopt") {
            uint8 n_page = cn == "alias" ? sh.ALIAS : cn == "shopt" ? sh.SHOPT : ff ? sh.FUNCTION : sh.VARIABLE;
            string sattrs;
            pf = cn == "alias" ? "alias %n=\'%v\'\n" : "declare %l\n";
            string[] res;
            bool print = fp || (no_flags && no_args);
            if (cn == "readonly") sattrs = "-r";
            else if (cn == "export") sattrs = fn ? "+x" : "-x";
            else if (cn == "declare") {
                bytes battrs = "aAxirtnf";
                for (bytes1 b: battrs)
                    if (cc_in.flag_set(b))
                        sattrs.append(bytes(b));
                if (sattrs.empty())
                    sattrs = "--";
                if (!fp)
                    pf = "%n=%v\n";
            } else if (cn == "shopt") {
                sattrs = fs ? "-s" : fu ? "-u" : "--";
                pf = "%n\t%o\n";
            }
            if (ff)
                sattrs.append("f");
            bytes1 ba;
            if (!sattrs.empty())
                ba = bytes(sattrs)[0];
            page = e.environ[n_page];
            if (no_args) {
                res = vars.filter(page, sattrs, "", false, false);
                e.puts(_printf_lines(res, pf));
            }
            if (print) {
                for (string param: args) {
                    res = vars.filter(page, sattrs, param, true, true);
                    if (!res.empty())
                        e.puts(_printf_lines(res, pf));
                    else
                        ec = EXIT_FAILURE;
                }
            } else {
                for (string param: args) {
                    (string nm, ) = vars.item_value(param);
                    e.environ[sh.ARRAYVAR][n_page].arrayvar_add(nm);
                    e.environ[n_page].set_var(sattrs, param);
                }
            }
        } else if (cn == "unalias") {
            if (!fa) {
                page = e.environ[sh.ALIAS];
                for (string param: args) {
                    page.unset_var(param);
                    e.environ[sh.ARRAYVAR][sh.ALIAS].arrayvar_remove(param);
                }
            }
            e.environ[sh.ALIAS] = page;
        } else if (cn == "unset") {
            uint8[] pages;
            if (fv) pages.push(sh.VARIABLE);
            if (ff) pages.push(sh.FUNCTION);
//            string sattrs = ff ? "-f" : fv ? "+f" : "--";
            for (uint8 n: pages)
                for (string arg: args)
                    e.environ[n].unset_var(arg);
        } else if (cn == "dirs") {
            page = e.environ[sh.DIRSTACK];
            bool print = fl || fp || fv || no_args;
            pf = fv ? " %N %l\n" : fp ? "%l\n" : "%l ";
            if (print) {
                out = fv ? _printf_lines_2(page, pf) : _printf_lines(page, pf);
                if (fl)
                    out.translate("~", e.env_value("HOME"));
                e.puts(out);
            } else if (fc)
                delete e.environ[sh.DIRSTACK];
        }
    }

    function _print_lines(string[] lines, string sattrs, string prefix, string suffix) internal pure returns (string res) {
        for (string line: lines)
            res.append(_print_line(line, sattrs, prefix, suffix) + "\n");
    }

    function _printf_lines(string[] lines, string pf) internal pure returns (string res) {
        for (string line: lines)
            res.append(_printf_line(line, pf));
    }

    function _printf_lines_2(string[] lines, string pf) internal pure returns (string res) {
        for (uint i = 0; i < lines.length; i++) {
            res.append(_printf_line_2(lines[i], pf, i));
        }
    }

    function _print_line(string line, string sattrs, string prefix, string suffix) internal pure returns (string) {
        (string attrs, string name, string value) = vars.split_var_record(line);
        if (vars.match_attr_set(sattrs, attrs)) {
            if (str.strchr(attrs, "f") > 0)
                return name + " ()\n{\n" + fmt.indent(value.translate(";", "\n"), 4, "\n") + "}\n";
            return prefix + line + suffix;
        }
    }

    function _printf_line(string line, string sfmt) internal pure returns (string res) {
        (string attrs, string name, string value) = vars.split_var_record(line);
        res = sfmt;
        res.translate("%a", attrs);
        res.translate("%n", name);
        res.translate("%v", value);
        res.translate("%l", line);
    }

    function _printf_line_2(string line, string pf, uint n) internal pure returns (string res) {
        res = line;
//        for ((string a, string b) : pf2)
//            res.translate(a, b);
        res.translate("%N", str.toa(n));
    }
    function getinterp(string sample, uint16 sample_len) external pure returns (string execname) {
    }

    // Call execve (), handling interpreting shell scripts, and handling exec failures.
    function shell_execve (string command, string[] args, string[] env) internal pure returns (string execname) {
        //execve (command, args, env);
        //i = errno;
        //CHECK_TERMSIG;

    }

    function execute_disk_command (word_desc[] words, s_redirect[] redirects, string command_line, uint8 pipe_in, uint8 pipe_out, bool async, uint8[] fds_to_close, uint16 cmdflags) internal pure returns (uint8 ec) {
        string pathname;
        string[] args;
        string command;// = search_for_command (pathname, CMDSRCH_HASH|(stdpath ? CMDSRCH_STDPATH : 0));
        if (!command.empty()) {
//            maybe_make_export_env ();
//            put_command_name_into_env (command);
        }
        //do_piping (pipe_in, pipe_out);
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
