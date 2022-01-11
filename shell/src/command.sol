pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract command is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);

        string hashes = e[IS_BINPATH];

        bool descr = _flag_set("v", flags);
        bool verbose = _flag_set("V", flags);
        bool print = descr || verbose;
        ec = EXECUTE_SUCCESS;
//        bool use_default_path = _get_option_value(short_options, "p");

        if (print) {
            for (string arg: args) {
                string t = _get_array_name(arg, e[IS_INDEX]);
                string value;
                if (t == "keyword")
                    value = descr ? arg : (arg + " is a shell keyword");
                else if (t == "alias") {
                    string val = _val(arg, _get_map_value("TOSH_ALIASES", e[IS_POOL]));
                    value = descr ? "alias " + arg + "=" + _wrap(val, W_SQUOTE) : (arg + " is aliased to `" + val + "\'");
                } else if (t == "function") {
                    value = descr ? arg : (arg + " is a function\n" + _print_reusable(_get_pool_record(arg, e[IS_POOL])));
                } else if (t == "builtin")
                    value = descr ? arg : (arg + " is a shell builtin");
                else if (t == "command") {
                    string path = _get_array_name(arg, hashes);
                    if (!path.empty())
                        value = descr ? arg : (arg + " is hashed (" + path + "/" + arg + ")");
                    else {
                        path = _get_array_name(arg, e[IS_BINPATH]);
                        value = path + "/" + arg;
                        if (verbose)
                            value = arg + " is " + value;
                    }
                } else
                    if (verbose)
                        out.append("-tosh: command: " + arg + ": not found\n");
                out.append(value + "\n");
            }
        }
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
