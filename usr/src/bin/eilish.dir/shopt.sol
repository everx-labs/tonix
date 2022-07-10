pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract shopt is pbuiltin_special {

    function _retrieve_pages(s_proc) internal pure override returns (uint8[]) {
        return [sh.SHOPT];
    }

    function _print(s_proc p, s_of f, string[] page) internal pure override returns (s_of res) {
        res = f;
        bool print_reusable = p.flag_set("p");
        bool set_opt = p.flag_set("s");
        bool unset_opt = p.flag_set("u");
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";

        if (p.params().empty()) {
            for (string line: page) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    res.fputs(print_reusable ? "shopt " + attrs + " " + name :
                    name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off"));
            }
        }
        for (string param: p.params()) {
            string line = vars.get_pool_record(param, page);
            if (!line.empty()) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    res.fputs(print_reusable ? "shopt " + attrs + " " + name :
                    name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off"));
            } else
                res.fputs(param + " not found");
        }
    }

    function _modify(s_proc p, string[] page_in) internal pure override returns (string[] page) {
        bool set_opt = p.flag_set("s");
        bool unset_opt = p.flag_set("u");
        page = page_in;
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";
        for (string param: p.params())
            page = vars.set_var(sattrs, param, page);
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
