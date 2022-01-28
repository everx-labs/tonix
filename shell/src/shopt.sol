pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract shopt is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);

        bool print_reusable = arg.flag_set("p", flags);
        bool set_opt = arg.flag_set("s", flags);
        bool unset_opt = arg.flag_set("u", flags);
        string s_attrs = set_opt ? "-s" : unset_opt ? "-u" : "";

        if (params.empty()) {
            (string[] lines, ) = stdio.split(pool, "\n");
            for (string line: lines) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(s_attrs, attrs))
                    out.append(print_reusable ? "shopt " + attrs + " " + name + "\n" :
                    name + "\t" + (stdio.strchr(attrs, "s") > 0 ? "on" : "off") + "\n");
            }
        }
        for (string p: params) {
            string line = vars.get_pool_record(p, pool);
            if (!line.empty()) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(s_attrs, attrs))
//                    out.append(print_reusable ? vars.print_reusable(line) : (name + "\t" + (set_opt ? "on" : "off") + "\n"));
                    out.append(print_reusable ? "shopt " + attrs + " " + name + "\n" :
                    name + "\t" + (stdio.strchr(attrs, "s") > 0 ? "on" : "off") + "\n");
            } else {
                ec = EXECUTE_FAILURE;
                out.append("shopt: " + p + " not found\n");
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool set_opt = arg.flag_set("s", flags);
        bool unset_opt = arg.flag_set("u", flags);
        string page = pool;
        string s_attrs = set_opt ? "-s" : unset_opt ? "-u" : "";

        ec = EXECUTE_SUCCESS;
        for (string p: params)
            page = vars.set_var(s_attrs, p, page);
        res = page;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"shopt",
"[-pqsu] [-o] [optname ...]",
"Set and unset shell options.",
"Change the setting of each shell option OPTNAME.  Without any option arguments, list each supplied OPTNAME,\n\
or all shell options if no OPTNAMEs are given, with an indication of whether or not each is set.",
"-o        restrict OPTNAMEs to those defined for use with `set -o'\n\
-p        print each shell option with an indication of its status\n\
-q        suppress output\n\
-s        enable (set) each OPTNAME\n\
-u        disable (unset) each OPTNAME",
"",
"Returns success if OPTNAME is enabled; fails if an invalid option is given or OPTNAME is disabled.");
    }
}
