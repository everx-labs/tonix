pragma ton-solidity >= 0.56.0;

import "Shell.sol";

struct Command {
    string cmd;
    string s_args;
    string redir_in;
    string redir_out;
}

contract eilish is Shell {

    function compound(string s_input, string aliases) external pure returns (Command[] res) {
        return _compound(s_input, aliases);
    }

    function _compound(string s_input, string aliases) internal pure returns (Command[] res) {
        if (s_input.empty())
            return res;
        (string[] commands, ) = stdio.split(s_input, ";");
        for (string line: commands) {
            (string cmd_raw, string s_args) = stdio.strsplit(line, " ");
            string cmd_expanded = vars.val(cmd_raw, aliases);
            string input = cmd_expanded.empty() ? line : cmd_expanded + " " + s_args;
            string cmd;
            (cmd, s_args) = stdio.strsplit(input, " ");
            string redir_in;
            string redir_out;
            if (!s_args.empty()) {
                uint p = stdio.strrchr(s_args, ">");
                if (p > 0) {
                    redir_out = stdio.strtok(s_args, p, " ");
                    s_args = stdio.trim_spaces(s_args.substr(0, p - 1));
                }
                uint q = stdio.strrchr(s_args, "<");
                if (q > 0) {
                    redir_in = stdio.strtok(s_args, q, " ");
                    s_args = stdio.trim_spaces(s_args.substr(0, q - 1));
                }
            }
            res.push(Command(cmd, s_args, redir_in, redir_out));
        }
    }

    /*function set_args_simple(Command s_cmd, string opt_string, string index, string pool) external pure returns (Command[] res) {
        (string cmd, string s_args, string redir_in, string redir_out) = s_cmd.unpack();
        string cmd_opt_string = vars.val(cmd, opt_string);

        string s_flags;
        string[][2] opt_values;
        string pos_params;
        string pos_map;
        string err;
        string[] params;
        uint n_params;
        string last_param;
        string opt_args;
        if (!s_args.empty()) {
            (params, n_params) = stdio.split(s_args, " ");
            (s_flags, opt_values, err, pos_params, ) = _parse_params(params, cmd_opt_string);
            if (!err.empty())
                ec = EX_BADUSAGE;
            for (string arg: params) {
                if (stdio.strchr(arg, "$") > 0) {
                    string ref = stdio.strval(arg, "$", " ");
                    if (stdio.strchr(ref, "{") > 0)
                        ref = vars.unwrap(ref);
                    string ref_val = vars.val(ref, pool);
                    pos_params = stdio.translate(pos_params, arg, ref_val);
                    s_args = stdio.translate(s_args, arg, ref_val);
                }
            }
            opt_args = vars.as_hashmap("OPT_ARGS", opt_values);
            if (!vars.val("help", opt_args).empty() || !vars.val("version", opt_args).empty()) {
                s_args = cmd;
                pos_params = cmd;
                params = [cmd];
                n_params = 1;
                cmd = "man";
            }
        }
        string cmd_type = vars.get_array_name(cmd, index);
        string exec_line;
        if (cmd_type == "builtin")
            exec_line = "./tosh run_builtin " + input;
        else if (cmd_type == "command")
            exec_line = "./tosh execute_command " + input;
        else if (cmd_type == "function")
            exec_line = "./tosh execute_function " + input;
        else if (!cmd_type.empty()) {
            exec_line = "echo error: eilish: " + cmd + " unkown commmand type: " + cmd_type;
            ec = EXECUTE_FAILURE;
        }
        res = exec_line;
        pos_map = vars.as_indexed_array("POS_ARGS", s_args.empty() ? cmd : (cmd + " " + s_args), " ");
        last_param = s_args.empty() ? cmd : params[n_params - 1];
        out = vars.as_var_list([
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", s_flags],
            ["ARGV", input],
            ["#", stdio.itoa(n_params)],
            ["@", s_args],
            ["?", stdio.itoa(ec)],
            ["_", last_param],
            ["OPTERR", err],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]);
        out.append(pos_map + "\n");
        out.append(opt_args + "\n");
    }*/

    function set_args(string s_input, string aliases, string opt_string, string index, string pool) external pure returns (uint8 ec, string out, string res, string redir_in, string redir_out) {
        if (s_input.empty())
            return (EXECUTE_FAILURE, "", "", "", "");
        (string cmd_raw, string s_args) = stdio.strsplit(s_input, " ");
        string cmd_expanded = vars.val(cmd_raw, aliases);
        string input = cmd_expanded.empty() ? s_input : cmd_expanded + " " + s_args;
        string cmd;
        (cmd, s_args) = stdio.strsplit(input, " ");
        string cmd_opt_string = vars.val(cmd, opt_string);

        string s_flags;
        string[][2] opt_values;
        string pos_params;
        string pos_map;
        string err;
        string[] params;
        uint n_params;
        string last_param;
        string opt_args;
        if (!s_args.empty()) {
            uint p = stdio.strrchr(s_args, ">");
            if (p > 0) {
                redir_out = stdio.strtok(s_args, p, " ");
                s_args = s_args.substr(0, p - 1);
            }
            uint q = stdio.strrchr(s_args, "<");
            if (q > 0) {
                redir_in = stdio.strtok(s_args, q, " ");
                s_args = s_args.substr(0, q - 1);
            }
            (params, n_params) = stdio.split(s_args, " ");
            (s_flags, opt_values, err, pos_params, ) = _parse_params(params, cmd_opt_string);
            if (!err.empty())
                ec = EX_BADUSAGE;
            for (string arg: params) {
                if (stdio.strchr(arg, "$") > 0) {
                    string ref = stdio.strval(arg, "$", " ");
                    if (stdio.strchr(ref, "{") > 0)
                        ref = vars.unwrap(ref);
                    string ref_val = vars.val(ref, pool);
                    pos_params = stdio.translate(pos_params, arg, ref_val);
                    s_args = stdio.translate(s_args, arg, ref_val);
                }
            }
            opt_args = vars.as_hashmap("OPT_ARGS", opt_values);
            if (!vars.val("help", opt_args).empty() || !vars.val("version", opt_args).empty()) {
                s_args = cmd;
                pos_params = cmd;
                params = [cmd];
                n_params = 1;
                cmd = "man";
            }
        }
        string cmd_type = vars.get_array_name(cmd, index);
        string exec_line;
        if (cmd_type == "builtin")
            exec_line = "./tosh run_builtin " + input;
        else if (cmd_type == "command")
            exec_line = "./tosh execute_command " + input;
        else if (cmd_type == "function")
            exec_line = "./tosh execute_function " + input;
        else if (!cmd_type.empty()) {
            exec_line = "echo error: eilish: " + cmd + " unkown commmand type: " + cmd_type;
            ec = EXECUTE_FAILURE;
        }
        res = exec_line;
        pos_map = vars.as_indexed_array("POS_ARGS", s_args.empty() ? cmd : (cmd + " " + s_args), " ");
        last_param = s_args.empty() ? cmd : params[n_params - 1];
        out = vars.as_var_list([
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", s_flags],
            ["ARGV", input],
            ["#", stdio.itoa(n_params)],
            ["@", s_args],
            ["?", stdio.itoa(ec)],
            ["_", last_param],
            ["OPTERR", err],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]);
        out.append(pos_map + "\n");
        out.append(opt_args + "\n");
    }

    function set_tosh_vars(string profile) external pure returns (uint8 ec, string out) {
        ec = EXECUTE_SUCCESS;
        out = vars.as_var_list([
            ["_", vars.val("TOSH", profile)],
            ["-", vars.val("-", profile)],
            ["TOSH", vars.val("TOSH", profile)],
            ["TOSHOPTS", vars.as_map("expand_aliases")],
            ["TOSHPID", vars.val("TOSHPID", profile)],
            ["TOSH_SUBSHELL", vars.val("TOSH_SUBSHELL", profile)],
            ["TOSH_ALIASES", vars.val("TOSH_ALIASES", profile)],
            ["SHELLOPTS", "allexport:hashall"],
            ["TMPDIR", vars.val("TMPDIR", profile)],
            ["SHLVL", vars.val("SHLVL", profile)]]);
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

    function _parse_params(string[] params, string opt_string) internal pure returns (string s_flags, string[][2] opt_values, string err, string pos_params, string s_attrs) {
        uint n_params = params.length;
        uint opt_str_len = opt_string.byteLength();
        bool expect_options = true;
        for (uint i = 0; i < n_params; i++) {
            string token = params[i];
            uint t_len = token.byteLength();
            if (t_len == 0)
                continue;
            if (expect_options && token.substr(0, 1) == "-") {
                string o;
                string val;
                if (t_len == 1)
                    continue; // stdin redirect
                if (token.substr(1, 1) == "-") {
                    if (t_len == 2) { // arg separator
                        expect_options = false;
                        continue;
                    }
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
                uint o_len = o.byteLength();
                if (o_len == 1) {
                    uint p = stdio.strchr(opt_string, o); // _strstr() for long options ?
                    if (p > 0) {
                        if (p < opt_str_len && opt_string.substr(p, 1) == ":") {
                            if (i + 1 < n_params) {
                                val = params[i + 1];
                                i++;
                            } else
                                err.append(format("error: missing option {} value in {} at {} pos {}\n", o, opt_string, p, i));
                        } else
                            val = o;
                        opt_values.push([o, val]);
                        s_flags.append(o);
                    } else
                        err.append("error: unrecognized option: " + o + " opt_string: " + (opt_string.empty() ? "empty" : opt_string) + "\n");
                } else {
                    if (o == "help" || o == "version")
                        opt_values.push([o, o]);
                    else
                        err.append("error: unrecognized option: " + o + ". Long options are not yet supported\n");
                }
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
        return BuiltinHelp("eilish",
            "[command ...]",
            "Command shell",
            "Command shell",
            "",
            "",
            "");
    }
}
