pragma ton-solidity >= 0.54.0;

import "Shell.sol";

contract command is Shell {

//    function print(string args, string hashes, string index, string pool) external pure returns (uint8 ec, string out) {
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
                    string val = _val(arg, _get_map_value("TOSH_ALIASES", pool));
                    value = descr ? "alias " + arg + "=" + _wrap(val, W_SQUOTE) : (arg + " is aliased to `" + val + "\'");
                } else if (t == "function") {
                    value = descr ? arg : (arg + " is a function\n" + _print_reusable(_get_pool_record(arg, pool)));
                } else if (t == "builtin")
                    value = descr ? arg : (arg + " is a shell builtin");
                else if (t == "command") {
                    string path = _get_array_name(" " + arg + " ", pool);
                    if (!path.empty())
                        value = descr ? arg : (arg + " is hashed (" + path + "/" + arg + ")");
                    else {
                        path = _get_array_name(" " + arg + " ", pool);
                        value = path + "/" + arg;
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

    function _item_val(string name, Item[] coll) internal pure returns (string) {
        for (Item i: coll)
            if (i.name == name)
                return i.value;
    }

    function execute_command(Item[] annotation) external pure returns (string res) {
//        string flags = _item_val("FLAGS", annotation);
        string cmd = _item_val("COMMAND", annotation);
        string s_args = _item_val("@", annotation);
//        string params = _item_val("PARAMS", annotation);

        string exec_path = "command";
        string fn;
        string cmds_exec = " ls file namei du stat cat paste tr head tail wc grep look expand unexpand rev colrm column cut basename dirname getent ";
        string cmds_exec_env = " id whoami printenv ";
        string pattern = " " + cmd + " ";
        if (_strstr(cmds_exec, pattern) > 0)
            fn = "exec";
        else if (_strstr(cmds_exec_env, pattern) > 0)
            fn = "exec_env";
//        string exec_line = "./" + exec_path + " " + cmd + " " + fn + " " + params;
        string exec_line = "./" + exec_path + " " + fn + " " + cmd + " " + s_args;
        res = exec_line;

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
