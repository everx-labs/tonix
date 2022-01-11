pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract getopts is Shell {

    function _next_option(string s_args, string opt_string) internal pure returns (uint opt_index, string opt_sym, string opt_arg) {
        opt_index = _strstr(" " + s_args, " -");
        if (opt_index > 0) {
            opt_sym = _strval(s_args, " -", " ");
            uint opt_string_len = opt_string.byteLength();
            uint sym_len = opt_sym.byteLength();
            if (sym_len > 1) {
                if (opt_sym.substr(0, 1) == "-") { // long option
                    uint q = _strstr(opt_string, opt_sym);
                    if (q > 0) {
                        if (q + 1 < opt_string_len) {
                            if (opt_string.substr(q, 1) == ":")
                                opt_arg = _strval(s_args, " -" + opt_sym, " ");
                        }
                    }
                } else {
                    // short opts combo
                }
            } else {
                uint q = _strchr(opt_string, opt_sym);
                if (q > 0) {
                    if (q + 1 < opt_string_len) {
                        if (opt_string.substr(q, 1) == ":")
                            opt_arg = _strval(s_args, " -" + opt_sym, " ");
                    }
                }
            }
        }
    }

//        uint opt_str_len = opt_string.byteLength();
//        uint args_len = s_args.byteLength();
//        uint opt_index = 1;
//        string opt_sym;
//        string opt_arg;
//        string opt_values;

        /*while (opt_index > 0) {
            (opt_index, opt_sym, opt_arg) = _next_option(s_args, opt_string);
            dbg.append(format("{} {} -> {} {} {}\n", s_args, opt_string, opt_index, opt_sym, opt_arg));
            if (!opt_sym.empty()) {
                opt_values.append(_encode_item(opt_sym, opt_arg));
                s_flags.append(opt_sym);
                s_args = s_args.substr(opt_index);
            } else
                break;
        }*/

//        env[IS_SPEC] = opt_values;
        /*for (uint i = 0; i < opt_str_len; i++) {
            string o = opt_string.substr(i, 1);
            uint p = _strstr(s_args, "-"
        }*/

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        ec = 0;
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        /*string res;
        string s_args = _value_of("@", env_in[IS_SPECIAL_VAR]);
        string tosh_vars = env_in[IS_TOSH_VAR];
        string dbg;

//        (string arr_attrs, string aliases, string arr_entry) = _fetch_var("TOSH_ALIASES", tosh_vars);
        string argv = _value_of("ARGV", env_in[IS_TOSH_VAR]);
        string page = env_in[IS_VARIABLE];
        string tosh_argv = _value_of("TOSH_ARGV", env_in[IS_TOSH_VAR]);
        (string[] args, uint n_args) = _split(argv, " ");
        if (n_args > 1) {
            string opt_string = args[0];
            string name = args[1];
            string optind = _value_of("OPTIND", env_in[IS_VARIABLE]);
            uint16 opt_index = _atoi(optind);
            opt_index++;
            string opt_index_pattern = format("[{}]=", opt_index);
            string token = _fetch(format("{}", opt_index), "TOSH_ARGV", env_in[IS_TOSH_VAR]);
            uint t_len = token.byteLength();
            string o;
            string val;
            if (token.substr(0, 1) == "-") {
                if (t_len == 1)
                    continue; // stdin redirect
                if (token.substr(1, 1) == "-") {
                    if (t_len == 2) // arg separator
                        continue;
                    o = token.substr(2); // long option
                    long_opts.push(o);
                } else {
                    o = token.substr(1); // short option(s)
                    short_opts.append(o);
                    if (t_len > 2)      // short option sequence has no value
                        continue;
                }
                /*uint p = _strchr(opt_string, o); // _strstr() for long options ?
                if (p > 0) {
                    if (p < opt_str_len && opt_string.substr(p, 1) == ":") {
                        val = (i + 1 < n_params) ? params[i + 1] : "error: missing option value";
                        dbg.append(val);
                        ec = 1;
                        i++;
                    } else
                        val = o;
                } else
                    val = "error: unrecognized option";
//                opt_values.append(o + "=" + val + "\n");
//                opt_values.append(format(" [{}]={}", o, val));
//                pos_map.append(format(" [{}]={}", i + 1, token));
//                s_flags.append(" " + o);*/

//            env[IS_VARIABLE] = _assign(s_attrs, arg, page);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"getopts",
"optstring name [arg]",
"Parse option arguments.",
"Getopts is used by shell procedures to parse positional parameters as options.",
"OPTSTRING contains the option letters to be recognized; if a letter is followed by a colon, the option\n\
is expected to have an argument, which should be separated from it by white space.\n\n\
Each time it is invoked, getopts will place the next option in the shell variable $name, initializing name\n\
if it does not exist, and the index of the next argument to be processed into the shell variable OPTIND.\n\
OPTIND is initialized to 1 each time the shell or a shell script is invoked.  When an option requires an argument,\n\
getopts places that argument into the shell variable OPTARG.",
"getopts reports errors in one of two ways. If the first character of OPTSTRING is a colon, getopts uses silent error\n\
reporting. In this mode, no error messages are printed.  If an invalid option is seen, getopts places the option character\n\
found into OPTARG. If a required argument is not found, getopts places a ':' into NAME and sets OPTARG to the option character\n\
found. If getopts is not in silent mode, and an invalid option is seen, getopts places '?' into NAME and unsets OPTARG.\n\
If a required argument is not found, a '?' is placed in NAME, OPTARG is unset, and a diagnostic message is printed.\n\n\
If the shell variable OPTERR has the value 0, getopts disables the printing of error messages, even if the first character\n\
of OPTSTRING is not a colon.  OPTERR has the value 1 by default.\n\n\
Getopts normally parses the positional parameters ($0 - $9), but if more arguments are given, they are parsed instead.",
"Returns success if an option is found; fails if the end of options is encountered or an error occurs.");
    }
}
