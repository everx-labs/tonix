pragma ton-solidity >= 0.54.0;

import "Shell.sol";
import "compspec.sol";

contract complete is Shell, compspec {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = _get_args(args);

    /*function command_info(string s_input, string[] e) external pure returns (string cmd, string cmd_type, string exec_path) {
        if (s_input.empty())
            return ("", "", "");
        (string cmd, string s_args) = _strsplit(s_input, " ");
        string cmd_type = _get_array_name(cmd, e[IS_INDEX]);
        string value;
        string input = s_input;
        if (cmd_type == "alias") {
            value = _val(cmd, e[IS_ALIAS]);
            input = value + " " + s_args;
            (cmd, s_args) = _strsplit(input, " ");
            cmd_type = _get_array_name(cmd, e[IS_INDEX]);
        }
        if (cmd_type == "function") {
//            value = 
        }
//         = value.empty() ? s_input : 
        string cmd_expanded = _val(cmd_raw, e[IS_ALIAS]);
        string input = cmd_expanded.empty() ? s_input : cmd_expanded + " " + s_args;
        string cmd;
        (cmd, s_args) = _strsplit(input, " ");
        string cmd_opt_string = _val(cmd, opt_string);
    }

    function args_info(string input, string[] e) external pure returns (string cmd, string cmd_type, string exec_path) {
        if (s_input.empty())
            return (EXECUTE_FAILURE, "");
        (string cmd_raw, string s_args) = _strsplit(s_input, " ");
        string cmd_expanded = _val(cmd_raw, aliases);
        string input = cmd_expanded.empty() ? s_input : cmd_expanded + " " + s_args;
        string cmd;
        (cmd, s_args) = _strsplit(input, " ");
        string cmd_opt_string = _val(cmd, opt_string);

        string redir_out;
        string redir_in;
        string s_flags;
        string opt_values;
        string pos_params;
        string pos_map;
        string dbg_x;
        string[] params;
        uint n_params;
        string last_param;
        uint8 ec;
        if (!s_args.empty()) {
            (params, n_params) = _split(s_args, " ");

            uint p = _strrchr(s_input, ">");
            uint q = _strrchr(s_input, "<");
            redir_out = p > 0 ? _strtok(s_input, p, " ") : "";
            redir_in = q > 0 ? _strtok(s_input, q, " ") : "";
            uint8 t_ec;
            (t_ec, s_flags, opt_values, dbg_x, pos_params, , pos_map) = _parse_params(params, cmd_opt_string);
            ec = t_ec;
            pos_map = "( [0]=\"" + cmd + "\"" + pos_map + " )";

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
        }
        string cmd_type = _get_array_name(cmd, index);

        return (ec, _encode_items([
            ["COMMAND", cmd],
            ["PARAMS", pos_params],
            ["FLAGS", s_flags],
            ["OPT_ARGS", opt_values],
            ["ARGV", input],
            ["POS_ARGS", pos_map],
            ["#", format("{}", n_params)],
            ["@", s_args],
            ["?", format("{}", ec)],
            ["_", last_param],
            ["OPT_ERR", dbg_x],
//            ["CMD_TYPE", ]
            ["REDIR_IN", redir_in],
            ["REDIR_OUT", redir_out]], "\n"));
    }*/

        ec = EXECUTE_SUCCESS;
        if (flags.empty())
            flags = "p";
        bool xprint = _flag_set("p", flags);
        bool print_all = params.empty();
        bool remove = _flag_set("r", flags);
        bool add = !xprint && !remove;
        bool add_function = _flag_set("F", flags);
        bool apply_to_command = _flag_set("C", flags);
//        string comp_specs_page = e[IS_COMP_SPEC];
        string comp_specs_page = pool;

        if (xprint || params.empty()) {
            (string[] comp_specs, ) = _split(comp_specs_page, "\n");
            for (string cs: comp_specs) {
                (string comp_func, string command_list) = _item_value(cs);
                (string[] items, ) = _split(_trim_spaces(command_list), " ");
                for (string item: items)
                    out.append("complete -F " + comp_func + " " + item + "\n");
            }
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"complete",
"[-abcdefgjksuv] [-pr] [-DEI] [-o option] [-A action] [-G globpat] [-W wordlist]  [-F function] [-C command] [-X filterpat] [-P prefix] [-S suffix] [name ...]",
"Specify how arguments are to be completed",
"For each NAME, specify how arguments are to be completed.  If no options are supplied, existing completion specifications are\n\
printed in a way that allows them to be reused as input.",
"-p        print existing completion specifications in a reusable format\n\
-r        remove a completion specification for each NAME, or, if no NAMEs are supplied, all completion specifications\n\
-D        apply the completions and actions as the default for commands without any specific completion defined\n\
-E        apply the completions and actions to \"empty\" commands -- completion attempted on a blank line\n\
-I        apply the completions and actions to the initial (usually the command) word",
"When completion is attempted, the actions are applied in the order the uppercase-letter options are listed above.\n\
If multiple options are supplied, the -D option takes precedence over -E, and both take precedence over -I.",
"Returns success unless an invalid option is supplied or an error occurs.");
    }
}
