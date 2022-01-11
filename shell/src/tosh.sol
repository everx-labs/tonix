pragma ton-solidity >= 0.53.0;

import "Shell.sol";
import "compspec.sol";

contract tosh is Shell, compspec {

    function on_b_exec(string ec, string out, Write[] delta, string[] e) external pure returns (string[] env) {
        env = e;
        string dbg = ec;

        env[IS_STDOUT].append(out);
//        string exec_line = e[IS_PIPELINE];
//        dbg.append("Executed " + exec_line + " with status " + ec + "\n");
//        uint len = e.length;

        for (Write d: delta) {
            (uint16 fd, string text, uint16 mode) = d.unpack();
            if ((mode & O_ACCMODE) > 0)
                if ((mode & O_APPEND) > 0)
                    env[fd].append(text);
                else
                    env[fd] = text;
            if (fd != IS_STDOUT && fd != IS_STDERR)
                dbg.append(format("page {} changes {} to {}\n", fd, e[fd], text));
        }
        env[IS_STDERR].append(dbg);
    }


    function on_exec(string ec, string out, string[] e) external pure returns (string[] env) {
        env = e;
        string dbg = ec;

        env[IS_STDOUT].append(out);
        string exec_line = e[IS_PIPELINE];
        dbg.append("Executed " + exec_line + " with status " + ec + "\n");
//        uint len = e.length;

        env[IS_STDERR].append(dbg);
    }

    function read_line(string args, string[] e) external pure returns (string[] env) {
        env = e;
        string s_input = _trim_spaces(args);
        delete env[IS_STDOUT];
        delete env[IS_STDERR];
        delete env[IS_PIPELINE];
        string dbg;

        // Parse redirections
        (string command_raw, string s_args) = _strsplit(s_input, " ");
        uint p = _strrchr(s_input, ">");
        uint q = _strrchr(s_input, "<");
        string redir_out = p > 0 ? _strtok(s_input, p, " ") : "";
        string redir_in = q > 0 ? _strtok(s_input, q, " ") : "";

        string pool = e[IS_POOL];
        /* Expand aliases */
        string tosh_aliases = _as_map(_get_map_value("TOSH_ALIASES", pool));
        string expanded = _val(command_raw, tosh_aliases);
        string cmd = expanded.empty() ? command_raw : expanded;

        (string[] params, uint n_params) = _split(s_args, " ");

        env[IS_BLTN_IN] = s_input;

        string tosh_path = "./vfs/usr/bin/tosh";
        string tosh_flags = "himBHs";

        string flags = tosh_flags;

        bool noexec = _flag_set("n", flags);
//        bool nounset = _flag_set("u", flags);
        bool verbose = _flag_set("v", flags);
        bool xtrace = _flag_set("x", flags);

        if (verbose)
            dbg.append(s_input + "\n");

        string opt_string = _val(cmd, e[IS_OPTSTRING]);

        (uint8 ec, string s_flags, string opt_values, string dbg_x, string pos_params, , string pos_map) = _parse_params(params, opt_string);
        pos_map = "( [0]=\"" + cmd + "\"" + pos_map + " )";
        dbg.append(dbg_x);

        env[IS_TOSH_VAR] = _trim_spaces(_encode_items([
            ["_", tosh_path],
            ["-", tosh_flags],
            ["#", format("{}", n_params)],
            ["@", s_args],
            ["?", format("{}", ec)],
            ["TOSH", tosh_path],
            ["TOSH_COMMAND", cmd],
            ["TOSHOPTS", _as_map("expand_aliases")],
            ["TOSHPID", ""],
            ["TOSH_ARGV", s_input],
            ["TOSH_SUBSHELL", "0"],
            ["TOSH_ALIASES", tosh_aliases],
            ["SHELLOPTS", "allexport:hashall"],
            ["TMPDIR", "vfs/tmp/tosh"],
            ["SHLVL", "1"]
            ]));

        /* Expand variables */
        for (string arg: params) {
            if (_strchr(arg, "$") > 0) {
                string ref = _strval(arg, "$", " ");
                if (_strchr(ref, "{") > 0)
                    ref = _unwrap(ref);
                Var v = _var_ext(ref, pool);
                string ref_val = v.value;
                pos_params = _translate(pos_params, arg, ref_val);
            }
        }
        env[IS_ARGS] = _trim_spaces(_encode_items([
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", s_flags],
            ["OPT_ARGS", opt_values],
            ["ARGV", s_input],
            ["POS_ARGS", pos_map],
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]]));

        /* Resolve execution commands */
        string comp_specs_page = e[IS_COMP_SPEC];
        string fn_name = _get_array_name(cmd, comp_specs_page);
        Var f_var = _var_ext(fn_name, pool);
        string f_body = f_var.value;
        dbg.append(f_body);

        string exec_queue;
        string exec_cmd;
        if (!f_body.empty()) {
            (string[] lines, uint n_lines) = _split(_unwrap(f_body), ";");
            for (uint i = 0; i < n_lines; i++) {
                string s_line = lines[i];
                if (s_line.empty())
                    continue;
                string first_sym = s_line.substr(0, 1);
                if (first_sym == '.')
                    s_line = tosh_path + s_line.substr(1);
                uint len = s_line.byteLength();
                if (len > 2) {
                    s_line = _translate(s_line, "$@", s_args);
                    s_line = _translate(s_line, "$0", cmd);
                }
                string exec_line = s_line + "\n";
                exec_queue.append(format("[{}]=\"{}\"\n", i, s_line));
                exec_cmd.append(exec_line);
            }
//            env = _set_val("FUNCNAME", fn_name, env);
//            env = _set_val("LINENO", "0", env);
        } else {
            exec_cmd = tosh_path + " " + fn_name + " " + cmd + " " + s_args + ";";
            exec_queue.append(format("[{}]=\"{}\"\n", 0, exec_cmd));
        }

        if (!noexec) {
            if (xtrace)
                dbg.append("+ " + exec_cmd + "\n");
            env[IS_CMD_QUEUE] = exec_queue;
            env[IS_PIPELINE] = exec_cmd;
        }

//        string exec_cmd = tosh_path + " " + s_input + ";";
        env[IS_BLTN_LINE] = exec_cmd;
        env[IS_STDERR].append(dbg);
    }

    /*function on_exec(string ec, string out, string err, string[] e) external pure returns (string[] env) {
        env = e;
//        string vv = e[IS_TOSH_VAR];
//        string flags = _val("-", vv);
//        bool interactive = _flag_set("i", flags);
//        bool errexit = _flag_set("e", flags);
//        bool xtrace = _flag_set("x", flags);

        string cmd_queue = e[IS_CMD_QUEUE];
        string pool = e[IS_POOL];
        Var f_name_v = _var_ext("FUNCNAME", pool);
        Var line_no_v = _var_ext("LINENO", pool);
        string line_no_s = line_no_v.value;
//        uint16 line_no = _atoi(line_no_s);
        env[IS_STDERR].append("Executing " + f_name_v.value + ", line " + line_no_s + ", status " + ec + "\n");
//        uint16 next_line_no = line_no++;
//        string next_line_no_s = format("{}", next_line_no);
  //      string next_line_val = _value()

//        env[IS_STDERR].append("-> " + )

//        env = _set_val("?", ec, env);
        env[IS_STDOUT].append(out);
        env[IS_STDERR].append(err);
//        if (xtrace) {
//        }

//        uint16
        (string[] items, uint n_items) = _split(cmd_queue, "\n");
        if (n_items > 0) {
            e[IS_CMD_QUEUE] = _translate(cmd_queue, items[0] + "\n", "");
        }
        if (n_items > 1) {
            env[IS_PIPELINE] = items[1];
        }
    }*/

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

    function _parse_params(string[] params, string opt_string) internal pure returns (uint8 ec, string s_flags, string opt_values, string dbg, string pos_params, string s_attrs, string pos_map) {
//        pos_map = "[0]=" + cmd;
        uint n_params = params.length;
        uint opt_str_len = opt_string.byteLength();
        opt_values = "(";
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
//                    long_opts.push(o);
                } else {
                    o = token.substr(1); // short option(s)
//                    short_opts.append(o);
                    if (t_len > 2)      // short option sequence has no value
                        continue;
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
                opt_values.append(format(" [{}]=\"{}\"", o, val));
                pos_map.append(format(" [{}]=\"{}\"", i + 1, token));
                s_flags.append(o);
            } else if (token.substr(0, 1) == "+") {
                s_attrs.append(token);
            } else {
                pos_map.append(format(" [{}]=\"{}\"", i + 1, token));
                if (pos_params.empty())
                    pos_params = token;
                else
                    pos_params.append(" " + token);
            }
        }
        opt_values.append(" )");
    }

    function execute_command(string[] e) external pure returns (string[] env) {
        env = e;
        // When executing a command, the words that the parser has marked as variable assignments (preceding the command name) and redirections
        // are saved for later reference. Words that are not variable assignments or redirections are expanded; the first remaining word after
        // expansion is taken to be the name of the command and the rest are arguments to that command. Then redirections are performed, then
        // strings assigned to variables are expanded. If no command name results, variables will affect the current shell environment.

        // An important part of the tasks of the shell is to search for commands. Bash does this as follows:
            // Check whether the command contains slashes. If not, first check with the function list to see if it contains a command by the name we are looking for.
            //    If command is not a function, check for it in the built-in list.
            //    If command is neither a function nor a built-in, look for it analyzing the directories listed in PATH. Bash uses a hash table (data storage area in memory) to remember the full path names of executables so extensive PATH searches can be avoided.
            //    If the search is unsuccessful, bash prints an error message and returns an exit status of 127.
            // If the search was successful or if the command contains slashes, the shell executes the command in a separate execution environment.
            // If execution fails because the file is not executable and not a directory, it is assumed to be a shell script.
            // If the command was not begun asynchronously, the shell waits for the command to complete and collects its exit status.
    }

    function read_script(string s_input, string[] e) external pure returns (string[] env) {
        e[IS_STDIN] = s_input;
        env = e;
        /*string s_arg = _trim_spaces(s_input);
        (string[] commands, uint n_commands) = _split(s_arg, ";");
        string pos_params;
        for (uint i = 0; i < n_commands; i++) {
            s_arg = _trim_spaces(commands[i]);
            if (s_arg.empty())
                continue;
            (string[] args, uint n_args) = _split(s_arg, " ");
            for (uint j = 0; j < n_args; j++)
                pos_params.append(args[j] + " ");
        }*/
    }

    function login_shell(string[] e) external pure returns (string[] env) {
        env = e;
        /*env.push(profile);
        string empty;
        (, uint n_lines) = _split(profile, "\n");
        for (uint i = 0; i < n_lines; i++)
            env.push(empty);*/
    }

    function read_profile(string profile) external pure returns (string[] env) {
        env.push(profile);
        string empty;
        (, uint n_lines) = _split(profile, "\n");
        for (uint i = 0; i < n_lines; i++)
            env.push(empty);
    }

    /*function _export_session(mapping (uint => ItemHashMap) env_in) internal pure returns (Session session) {
        mapping (uint => Item) shell_vars = env_in[tvm.hash("shell_vars")].value;

        return Session(
            _atoi(shell_vars[tvm.hash("PPID")].value),
            _atoi(shell_vars[tvm.hash("UID")].value),
            _atoi(shell_vars[tvm.hash("UID")].value),
            _atoi(shell_vars[tvm.hash("WD")].value),
            shell_vars[tvm.hash("USER")].value,
            shell_vars[tvm.hash("USER")].value,
            shell_vars[tvm.hash("NAME")].value,
            shell_vars[tvm.hash("PWD")].value
        );
    }*/

    function _check_args(string command_s, CommandInfo ci, string short_options, string[] args) private pure returns (Err[] errors) {
        uint16 n_args = uint16(args.length);
        string extra_flags;
        uint short_options_len = short_options.byteLength();
        string possible_options = ci.options;
        for (uint i = 0; i < short_options_len; i++) {
            string actual_option = short_options.substr(i, 1);
            uint p = _strchr(possible_options, actual_option);
            if (p == 0)
                extra_flags.append(actual_option);
        }

        if (n_args < ci.min_args)
            errors.push(Err(missing_file_operand, 0, command_s));
        if (n_args > ci.max_args)
            errors.push(Err(extra_operand, 0, args[ci.max_args]));
        if (!extra_flags.empty())
            errors.push(Err(invalid_option, 0, extra_flags));
        if (!errors.empty())
            errors.push(Err(try_help_for_info, 0, command_s));
    }

    function _parse_short_options(string short_options) private pure returns (uint flags) {
        bytes opts = bytes(short_options);
        for (uint i = 0; i < opts.length; i++)
            flags |= uint(1) << uint8(opts[i]);
    }

     function process_args() external accept {
    }

//    function _builtin_help() internal pure override returns (string synopsis, string purpose, string description, string options, string arguments, string exit_status) {
    function _builtin_help() internal pure override returns  (BuiltinHelp bh) {
        return BuiltinHelp("tosh",
            "[command ...]",
            "Command shell",
            "Command shell",
            "",
            "",
            "");
    }
//    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
    function _command_info() internal pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("tosh", "display", "[-dms]",
            "Displays brief summaries of builtin commands.",
            "dms", 0, M, [
            "output short description for each topic",
            "display usage in pseudo-manpage format",
            "output only a short usage synopsis for each topic"]);
    }
}
