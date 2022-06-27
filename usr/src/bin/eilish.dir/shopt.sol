pragma ton-solidity >= 0.61.2;

import "pbuiltin_special.sol";

contract shopt is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc) internal pure override returns (mapping (uint8 => string) pages) {
        pages[13] = e.options;
    }

    function _update_shell_env(shell_env e_in, uint8, string page) internal pure override returns (shell_env e) {
        e = e_in;
        e.options = page;
    }

//    function _print(s_proc p_in, string[] params, string page) internal pure override returns (s_proc p) {
//        p = p_in;
    function _print(s_proc p, s_of f, string[] params, string page) internal pure override returns (s_of res) {
        res = f;
        bool print_reusable = p.flag_set("p");
        bool set_opt = p.flag_set("s");
        bool unset_opt = p.flag_set("u");
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";

        if (params.empty()) {
            (string[] lines, ) = page.split("\n");
            for (string line: lines) {
                (string attrs, string name, ) = vars.split_var_record(line);
                if (vars.match_attr_set(sattrs, attrs))
                    res.fputs(print_reusable ? "shopt " + attrs + " " + name :
                    name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off"));
            }
        }
        for (string param: params) {
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

    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        bool set_opt = p.flag_set("s");
        bool unset_opt = p.flag_set("u");
        page = page_in;
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";
        for (string param: params)
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
