pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract shopt is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();

        string pool = vmem.vmem_fetch_page(sv.vmem[1], 3);
        bool print_reusable = p.flag_set("p");
        bool set_opt = p.flag_set("s");
        bool unset_opt = p.flag_set("u");
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";

        if (params.empty()) {
            (string[] lines, ) = pool.split("\n");
            for (string line: lines) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    p.puts(print_reusable ? "shopt " + attrs + " " + name :
                    name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off"));
            }
        }
        for (string param: params) {
            string line = vars.get_pool_record(param, pool);
            if (!line.empty()) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    p.puts(print_reusable ? "shopt " + attrs + " " + name :
                    name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off"));
            } else {
                p.perror(param + " not found");
            }
        }
        sv.cur_proc = p;
    }


    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool set_opt = arg.flag_set("s", flags);
        bool unset_opt = arg.flag_set("u", flags);
        string page = pool;
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";

        ec = EXECUTE_SUCCESS;
        for (string p: params)
            page = vars.set_var(sattrs, p, page);
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
