pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract command is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = _get_args(args);
        bool descr = _flag_set("v", flags);
        bool verbose = _flag_set("V", flags);
        for (string arg: params) {
            string t = _get_array_name(arg, pool);
            string value;
            if (t == "keyword")
                value = descr ? arg : (arg + " is a shell keyword");
            else if (t == "alias") {
                string val = _val(arg, pool);
                value = descr ? "alias " + arg + "=" + _wrap(val, W_SQUOTE) : (arg + " is aliased to `" + val + "\'");
            } else if (t == "function")
                value = descr ? arg : (arg + " is a function\n" + _print_reusable(_get_pool_record(arg, pool)));
            else if (t == "builtin")
                value = descr ? arg : (arg + " is a shell builtin");
            else if (t == "command") {
                string path_map = _get_pool_record(arg, pool);
                string path;
                if (!path_map.empty())
                    (, path, ) = _split_var_record(path_map);
                if (!path.empty())
                    value = descr ? arg : (arg + " is hashed (" + path + "/" + arg + ")");
                else {
                    value = "/bin/" + arg;
                    if (verbose)
                        value = arg + " is " + value;
                }
            } else {
                ec = EXECUTE_FAILURE;
                if (verbose)
                    out.append("-tosh: command: " + arg + ": not found\n");
            }
            out.append(value + "\n");
        }
    }

    function _update_hash_table(string cmd, string comp_spec, string pool) internal pure returns (uint8 ec, string fn_name, string cs_res) {
        string fn_map = _get_pool_record(cmd, comp_spec);
        if (fn_map.empty()) {
            string commands = _get_map_value("command", pool);
            if (_strstr(commands, " " + cmd + " ") > 0) {
                fn_name = "main";
                fn_map = _get_map_value(fn_name, comp_spec);
                string upd = _set_item_value(cmd, "0", fn_map);
                cs_res = _translate(comp_spec, fn_map, upd);
            } else {
                ec = EXECUTE_FAILURE;
            }
        } else {
            (, fn_name, ) = _split_var_record(fn_map);
//            out.append(cmd + " " + fn_name);
            string s_hit_count = _val(cmd, fn_map);
            uint16 hc = _atoi(s_hit_count);
            string upd = _set_item_value(cmd, _itoa(hc + 1), fn_map);
            cs_res = _translate(comp_spec, fn_map, upd);
        }
    }

    function _export_env(string args, string pool) internal pure returns (string exports) {
        string s_attrs = "-x";
        (string[] lines, ) = _split(pool, "\n");
        for (string line: lines) {
            (string attrs, ) = _strsplit(line, " ");
            if (_match_attr_set(s_attrs, attrs))
                exports.append(line + "\n");
        }
        exports.append(args);
    }

    function execute_command(string args, string page, string pool) external pure returns (uint8 ec, string exec_line, string exports, string cs_res) {
        string comp_spec = page;
        string cmd = _val("COMMAND", args);
        string s_args = _val("@", args);
        string fn_name;

        (ec, fn_name, cs_res) = _update_hash_table(cmd, comp_spec, pool);
        exports = _export_env(args, pool);

        if (ec == EXECUTE_SUCCESS)
            exec_line = "./command " + fn_name + " " + cmd + " " + s_args;
        else
            exec_line = "echo Error executing command: " + cmd + ", args " + s_args;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"command",
"[-pVv] command [arg ...]",
"Execute a simple command or display information about commands.",
"Runs COMMAND with ARGS suppressing  shell function lookup, or display information about the specified COMMANDs.  Can be used to invoke commands on disk when a function with the same name exists.",
"-p    use a default value for PATH that is guaranteed to find all of the standard utilities\n\
-v    print a description of COMMAND similar to the `type' builtin\n\
-V    print a more verbose description of each COMMAND",
"",
"Returns exit status of COMMAND, or failure if COMMAND is not found.");
    }
}
