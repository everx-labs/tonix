pragma ton-solidity >= 0.55.0;

import "Shell.sol";
import "compspec.sol";

contract eilish is Shell, compspec {

    function pipe(uint8 ec, string out, Write[] delta, string[] e) external pure returns (string[] env) {
        env = e;
        string dbg;
        string exec_line = e[IS_PIPELINE];
        if (ec > EXECUTE_SUCCESS)
            dbg.append("Executed " + exec_line + " with status " + _itoa(ec) + "\n");
        string cmd_queue = e[IS_CMD_QUEUE];
        string pool = e[IS_POOL];
        string f_name_v = _val("FUNCNAME", pool);
        string line_no_v = _val("LINENO", pool);
        uint16 line_no_s = _atoi(line_no_v);
        env[IS_STDERR].append(format("Executing {}, line {}, status {}\n", f_name_v, line_no_s, ec));

        for (Write d: delta) {
            (uint16 fd, string text, uint16 mode) = d.unpack();
            if ((mode & O_ACCMODE) > 0)
                if ((mode & O_APPEND) > 0)
                    env[fd].append(text);
                else
                    env[fd] = text;
            if (fd != IS_STDOUT && fd != IS_STDERR)
                dbg.append(format("page {} changes from\n===\n{}\n===\n to \n===\n{}\n===\n", fd, e[fd], text));
        }

        (string[] items, uint n_items) = _split(cmd_queue, "\n");
        if (n_items > 0) {
            e[IS_CMD_QUEUE] = _translate(cmd_queue, items[0] + "\n", "");
        }
        if (n_items > 1) {
            env[IS_PIPELINE] = items[1];
        }

//        uint16 next_line_no = line_no++;
//        string next_line_no_s = _itoa(next_line_no);
  //      string next_line_val = _value()

//        env[IS_STDERR].append("-> " + )

//        env = _set_val("?", ec, env);

        env[IS_STDIN] = out;
    }

    function on_b_exec(uint8 ec, string out, Write[] delta, string[] e) external pure returns (string[] env) {
        env = e;
        string dbg;

        env[IS_STDOUT].append(out);
        string exec_line = e[IS_PIPELINE];
//        dbg.append("Executed " + exec_line + " with status " + ec + "\n");
//        uint len = e.length;
        if (ec > EXECUTE_SUCCESS)
            dbg.append("Executed " + exec_line + " with status " + _itoa(ec) + "\n");

        for (Write d: delta) {
            (uint16 fd, string text, uint16 mode) = d.unpack();
            if ((mode & O_ACCMODE) > 0)
                if ((mode & O_APPEND) > 0)
                    env[fd].append(text);
                else
                    env[fd] = text;
            if (fd != IS_STDOUT && fd != IS_STDERR)
                dbg.append(format("page {} changes from\n===\n{}\n===\n to \n===\n{}\n===\n", fd, e[fd], text));
        }
        env[IS_STDERR].append(dbg);
    }

    function on_exec(uint8 ec, string out, string[] e) external pure returns (string[] env) {
        env = e;
        string dbg;

        env[IS_STDOUT].append(out);
        string exec_line = e[IS_PIPELINE];
        if (ec > EXECUTE_SUCCESS)
            dbg.append("Executed " + exec_line + " with status " + _itoa(ec) + "\n");

        env[IS_STDERR].append(dbg);
    }

    function _match_function_comp_spec(string cmd, string flags, string comp_spec) internal pure returns (string) {
        (string[] lines, ) = _split(comp_spec, "\n");
        for (string line: lines) {
            if (_strstr(line, " " + cmd + " ") > 0) {
                (string fn_attrs, string fn_name, ) = _split_var_record(line);
                if (_match_attr_set(fn_attrs, flags))
                    return fn_name;
            }
        }
    }

    function annotate_args(string s_input, string aliases, string opt_string, string comp_spec, string index, string pool) external pure returns (Item[] res) {
        if (s_input.empty())
            return res;
        (string cmd_raw, string s_args) = _strsplit(s_input, " ");
        string cmd_expanded = _val(cmd_raw, aliases);
        string input = cmd_expanded.empty() ? s_input : cmd_expanded + " " + s_args;
        string cmd;
        (cmd, s_args) = _strsplit(input, " ");
        string cmd_opt_string = _val(cmd, opt_string);

        string redir_out;
        string redir_in;
        string s_flags;
        string[][2] opt_values;
        string pos_params;
        string pos_map;
        string dbg_x;
        string[] params;
        uint n_params;
        string last_param;
        uint8 ec;
        string err;
        string out;
        if (!s_args.empty()) {
            (params, n_params) = _split(s_args, " ");

            uint p = _strrchr(s_input, ">");
            uint q = _strrchr(s_input, "<");
            redir_out = p > 0 ? _strtok(s_input, p, " ") : "";
            redir_in = q > 0 ? _strtok(s_input, q, " ") : "";
            uint8 t_ec;
            (t_ec, s_flags, opt_values, dbg_x, pos_params, ) = _parse_params(params, cmd_opt_string);
            ec = t_ec;

            for (string arg: params) {
                if (_strchr(arg, "$") > 0) {
                    string ref = _strval(arg, "$", " ");
                    if (_strchr(ref, "{") > 0)
                        ref = _unwrap(ref);
                    string ref_val = _val(ref, pool);
                    pos_params = _translate(pos_params, arg, ref_val);
                }
            }
            last_param = params[n_params - 1];
            pos_map = cmd + " " + s_args;
        }
        string cmd_type = _get_array_name(cmd, index);
        string exec_path;
        string exec_line;
        string cmd_queue;
        string fn_name;

        if (cmd_type == "builtin") {
            exec_line = "./tosh run_builtin " + input;
//            fn_name = _get_array_name(cmd, comp_spec);
            string fn_spec = _get_pool_record(cmd, comp_spec);
            if (!fn_spec.empty())
                (, fn_name, ) = _split_var_record(fn_spec);
        } else if (cmd_type == "command") {
            exec_line = "./tosh execute_command " + input;
//            fn_name = _get_array_name(cmd, comp_spec);
            string fn_spec = _get_pool_record(cmd, comp_spec);
            if (!fn_spec.empty())
                (, fn_name, ) = _split_var_record(fn_spec);
        } else if (!cmd_type.empty()) {
            exec_path = "./" + cmd_type;
            fn_name = _match_function_comp_spec(cmd, s_flags, comp_spec);
            string f_body = _function_body(fn_name, pool);
            if (!f_body.empty()) {
                (string[] lines, uint n_lines) = _split(f_body, ";");
                for (uint i = 0; i < n_lines; i++) {
                    string s_line = lines[i];
                    if (s_line.empty())
                        continue;
                    if (s_line.substr(0, 1) == '.')
                        s_line = exec_path + s_line.substr(1);
                    if (s_line.byteLength() > 2) {
                        s_line = _translate(s_line, "$@", s_args);
                        s_line = _translate(s_line, "$0", cmd);
                    }
                    cmd_queue.append(format("[{}]=\"{}\"\n", i, s_line));
                    exec_line.append(s_line + "\n");
                }
            } else {
                fn_name = _get_array_name(cmd, comp_spec);
                exec_line = exec_path + " " + cmd + " " + fn_name + " " + s_args + ";";
                cmd_queue = "[0]=\"" + exec_line + "\"\n";
            }
        } else {
            ec = EXECUTE_FAILURE;
            err = cmd + ": command not found\n";
        }
        if (ec > EXECUTE_SUCCESS)
            exec_line = "echo " + err;
        res = [
            Item("COMMAND", 0, cmd),
            Item("PARAMS", 0, pos_params),
            Item("FLAGS", 0, s_flags),
            Item("OPT_ARGS", 0, _encode_items(opt_values, " ")),
            Item("ARGV", 0, input),
            Item("POS_ARGS", 0, pos_map),
            Item("#", 0, _itoa(n_params)),
            Item("@", 0, s_args),
            Item("?", 0, _itoa(ec)),
            Item("_", 0, last_param),
            Item("OPTERR", 0, dbg_x),
            Item("CMD_TYPE", 0, cmd_type),
            Item("EXEC_PATH", 0, exec_path),
            Item("EXEC_FUNCTION", 0, fn_name),
            Item("EXEC_LINE", 0, exec_line),
            Item("COMMAND_QUEUE", 0, cmd_queue),
            Item("S_OUT", 0, out),
            Item("S_ERR", 0, err),
            Item("REDIR_IN", 0, redir_in),
            Item("REDIR_OUT", 0, redir_out)];
    }


    function set_args(string s_input, string aliases, string opt_string, string pool) external pure returns (uint8 ec, string out) {
        if (s_input.empty())
            return (EXECUTE_FAILURE, "");
        /* Expand aliases */
        (string cmd_raw, string s_args) = _strsplit(s_input, " ");
        string cmd_expanded = _val(cmd_raw, aliases);
        string input = cmd_expanded.empty() ? s_input : cmd_expanded + " " + s_args;
        string cmd;
        (cmd, s_args) = _strsplit(input, " ");
        string cmd_opt_string = _val(cmd, opt_string);

        string redir_out;
        string redir_in;
        string s_flags;
        string[][2] opt_values;
        string pos_params;
        string pos_map;
        string dbg_x;
        string[] params;
        uint n_params;
        string last_param;
        if (!s_args.empty()) {
            (params, n_params) = _split(s_args, " ");
            uint p = _strrchr(s_input, ">");
            uint q = _strrchr(s_input, "<");
            redir_out = p > 0 ? _strtok(s_input, p, " ") : "";
            redir_in = q > 0 ? _strtok(s_input, q, " ") : "";
            uint8 t_ec;
            (t_ec, s_flags, opt_values, dbg_x, pos_params, ) = _parse_params(params, cmd_opt_string);
            ec = t_ec;
            for (string arg: params) {
                if (_strchr(arg, "$") > 0) {
                    string ref = _strval(arg, "$", " ");
                    if (_strchr(ref, "{") > 0)
                        ref = _unwrap(ref);
                    string ref_val = _val(ref, pool);
                    pos_params = _translate(pos_params, arg, ref_val);
                    s_args = _translate(s_args, arg, ref_val);
                }
            }
        }
        pos_map = _as_indexed_array("POS_ARGS", s_args.empty() ? cmd : (cmd + " " + s_args), " ");
        last_param = s_args.empty() ? cmd : params[n_params - 1];
        out = _as_var_list([
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", s_flags],
            ["ARGV", input],
            ["#", _itoa(n_params)],
            ["@", s_args],
            ["?", _itoa(ec)],
            ["_", last_param],
            ["OPTERR", dbg_x],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]);
        out.append(_as_hashmap("OPT_ARGS", opt_values) + "\n");
        out.append(pos_map + "\n");
    }

    function set_tosh_vars(string profile) external pure returns (uint8 ec, string out) {
        ec = EXECUTE_SUCCESS;
        out = _as_var_list([
            ["_", _val("TOSH", profile)],
            ["-", _val("-", profile)],
            ["TOSH", _val("TOSH", profile)],
            ["TOSHOPTS", _as_map("expand_aliases")],
            ["TOSHPID", _val("TOSHPID", profile)],
            ["TOSH_SUBSHELL", _val("TOSH_SUBSHELL", profile)],
            ["TOSH_ALIASES", _val("TOSH_ALIASES", profile)],
            ["SHELLOPTS", "allexport:hashall"],
            ["TMPDIR", _val("TMPDIR", profile)],
            ["SHLVL", _val("SHLVL", profile)]]);
    }

    function build_command_queue(string args, string tosh_vars, string comp_spec, string pool) external pure returns (uint8 ec, string out) {
        (ec, , out) = _build_command_queue(args, tosh_vars, comp_spec, pool);
    }

    function build_exec_pipeline(string args, string tosh_vars, string comp_spec, string pool) external pure returns (uint8 ec, string out) {
        (ec, out, ) = _build_command_queue(args, tosh_vars, comp_spec, pool);
    }

    function _build_command_queue(string args, string tosh_vars, string comp_spec, string pool) internal pure returns (uint8 ec, string exec_line, string cmd_queue) {
        ec = 0;
        string cmd = _val("COMMAND", args);
        string s_args = _val("@", args);
        string tosh_path = _val("TOSH", tosh_vars);
        string fn_name = _get_array_name(cmd, comp_spec);
        string f_body = _function_body(fn_name, pool);
        if (!f_body.empty()) {
            (string[] lines, uint n_lines) = _split(f_body, ";");
            for (uint i = 0; i < n_lines; i++) {
                string s_line = lines[i];
                if (s_line.empty())
                    continue;
                if (s_line.substr(0, 1) == '.')
                    s_line = tosh_path + s_line.substr(1);
                if (s_line.byteLength() > 2) {
                    s_line = _translate(s_line, "$@", s_args);
                    s_line = _translate(s_line, "$0", cmd);
                }
                cmd_queue.append(format("[{}]=\"{}\"\n", i, s_line));
                exec_line.append(s_line + "\n");
            }
        } else {
            exec_line = tosh_path + " " + fn_name + " " + cmd + " " + s_args + ";";
            cmd_queue = "[0]=\"" + exec_line + "\"\n";
        }
    }

    // Possible states for the parser that require it to do special things.
    uint16 constant PST_CASEPAT	    = 1;   // in a case pattern list
    uint16 constant PST_ALEXPNEXT	= 2;   // expand next word for aliases
    uint16 constant PST_ALLOWOPNBRC	= 4;   // allow open brace for function def
    uint16 constant PST_NEEDCLOSBRC	= 8;   // need close brace
    uint16 constant PST_DBLPAREN	= 16;  // double-paren parsing
    uint16 constant PST_SUBSHELL	= 32;  // ( ... ) subshell
    uint16 constant PST_CMDSUBST	= 64;  // $( ... ) command substitution
    uint16 constant PST_CASESTMT	= 128; // parsing a case statement
    uint16 constant PST_CONDCMD	    = 256; // parsing a [[...]] command
    uint16 constant PST_CONDEXPR	= 512; // parsing the guts of [[...]]
    uint16 constant PST_ARITHFOR	= 1024; // parsing an arithmetic for command

    function _parse_params(string[] params, string opt_string) internal pure returns (uint8 ec, string s_flags, string[][2] opt_values, string dbg, string pos_params, string s_attrs) {
        uint n_params = params.length;
        uint opt_str_len = opt_string.byteLength();
        for (uint i = 0; i < n_params; i++) {
            string token = params[i];
            uint t_len = token.byteLength();
            if (t_len == 0)
                continue;
            if (token.substr(0, 1) == "-") {
                string o;
                string val;
                if (t_len == 1)
                    continue; // stdin redirect
                if (token.substr(1, 1) == "-") {
                    if (t_len == 2) // arg separator
                        continue;
                    o = token.substr(2); // long option
                } else {
                    // short option(s)
                    o = token.substr(1);
                    if (t_len > 2) {     // short option sequence has no value
                        for (uint j = 1; j < t_len; j++)
                            s_flags.append(token.substr(j, 1));
                        continue;
                    }
                }
                uint p = _strchr(opt_string, o); // _strstr() for long options ?
                if (p > 0) {
                    if (p < opt_str_len && opt_string.substr(p, 1) == ":") {
                        if (i + 1 < n_params) {
                            val = params[i + 1];
                            i++;
                        } else {
                            ec = EX_BADUSAGE;
                            dbg.append(format("error: missing option {} value in {} at {} pos {}\n", o, opt_string, p, i));
                        }
                    } else
                        val = o;
                } else {
                    ec = EX_BADUSAGE;
                    dbg.append("error: unrecognized option: " + o + " opt_string: " + opt_string + "\n");
                }
                opt_values.push([o, val]);
                s_flags.append(o);
            } else if (token.substr(0, 1) == "+")
                s_attrs.append(token);
            else {
                if (pos_params.empty())
                    pos_params = token;
                else
                    pos_params.append(" " + token);
            }
        }
    }

    function _builtin_help() internal pure override returns  (BuiltinHelp bh) {
        return BuiltinHelp("tosh",
            "[command ...]",
            "Command shell",
            "Command shell",
            "",
            "",
            "");
    }

    function _command_info() internal pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("tosh", "display", "[-dms]",
            "Displays brief summaries of builtin commands.",
            "dms", 0, M, [
            "output short description for each topic",
            "display usage in pseudo-manpage format",
            "output only a short usage synopsis for each topic"]);
    }
}
