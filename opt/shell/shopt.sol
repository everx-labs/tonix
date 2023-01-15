pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract shopt is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        uint8 pg = sh.SHOPT;
        string[] params = cc.params();
        bool no_params = params.empty();
        bool print = cc.flag_set("p") || no_params;
        string[] page = e.environ[pg];
        bool set_opt = cc.flag_set("s");
        bool unset_opt = cc.flag_set("u");
        string sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";
        string[] res;
        if (no_params) {
            res = vars.filter(page, sattrs, "", false, false);
            e.puts(_print_line(res));
        } else {
            for (string p: params) {
                if (print) {
                    res = vars.filter(page, sattrs, p, true, true);
                    if (res.empty()) {
                        e.notfound(p);
                        rc = EXIT_FAILURE;
                    } else
                        e.puts(_print_line(res));
                } else
                    page.set_var_attr(sattrs, p);
            }
            if (!print)
                e.environ[pg] = page;
        }

    }

    function _print_line(string[] lines) internal pure returns (string res) {
        for (string line: lines) {
            (string attrs, string name, ) = vars.split_var_record(line);
            res.append(name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off"));
        }
    }

    function _name() internal pure override returns (string) {
        return "shopt";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
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
