pragma ton-solidity >= 0.55.0;

import "Shell.sol";
import "compspec.sol";

contract eilish is Shell, compspec {

    function set_args(string s_input, string aliases, string opt_string, string index, string pool) external pure returns (uint8 ec, string out, string res) {
        if (s_input.empty())
            return (EXECUTE_FAILURE, "", "");
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
        string err;
        string[] params;
        uint n_params;
        string last_param;
        string opt_args;
        if (!s_args.empty()) {
            (params, n_params) = _split(s_args, " ");
            uint p = _strrchr(s_input, ">");
            uint q = _strrchr(s_input, "<");
            redir_out = p > 0 ? _strtok(s_input, p, " ") : "";
            redir_in = q > 0 ? _strtok(s_input, q, " ") : "";
            uint8 t_ec;
            (t_ec, s_flags, opt_values, err, pos_params, ) = _parse_params(params, cmd_opt_string);
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
            opt_args = _as_hashmap("OPT_ARGS", opt_values);
            if (!_val("help", opt_args).empty() || !_val("version", opt_args).empty()) {
                s_args = cmd;
                pos_params = cmd;
                params = [cmd];
                n_params = 1;
                cmd = "man";
            }
        }
        string cmd_type = _get_array_name(cmd, index);
        string exec_line;
        if (cmd_type == "builtin") {
            exec_line = "./tosh run_builtin " + input;
        } else if (cmd_type == "command") {
            exec_line = "./tosh execute_command " + input;
        } else if (!cmd_type.empty()) {
            exec_line = "echo error: eilish: " + cmd + " unkown commmand type: " + cmd_type;
            ec = EXECUTE_FAILURE;
        }
        res = exec_line;
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
            ["OPTERR", err],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]);
        out.append(pos_map + "\n");
        out.append(opt_args + "\n");
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

    function _parse_params(string[] params, string opt_string) internal pure returns (uint8 ec, string s_flags, string[][2] opt_values, string err, string pos_params, string s_attrs) {
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
                    uint p = _strchr(opt_string, o); // _strstr() for long options ?
                    if (p > 0) {
                        if (p < opt_str_len && opt_string.substr(p, 1) == ":") {
                            if (i + 1 < n_params) {
                                val = params[i + 1];
                                i++;
                            } else {
                                ec = EX_BADUSAGE;
                                err.append(format("error: missing option {} value in {} at {} pos {}\n", o, opt_string, p, i));
                            }
                        } else
                            val = o;
                        opt_values.push([o, val]);
                        s_flags.append(o);
                    } else {
                        ec = EX_BADUSAGE;
                        err.append("error: unrecognized option: " + o + " opt_string: " + (opt_string.empty() ? "empty" : opt_string) + "\n");
                    }
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
