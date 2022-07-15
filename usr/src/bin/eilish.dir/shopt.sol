pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract shopt is pbuiltin_special {

    function _retrieve_pages(shell_env) internal pure override returns (uint8) {
        return sh.SHOPT;
    }

    function _attr_set(shell_env e) internal pure override returns (string sattrs) {
        bool set_opt = e.flag_set("s");
        bool unset_opt = e.flag_set("u");
        sattrs = set_opt ? "-s" : unset_opt ? "-u" : "";
    }
    function _print_record(string record) internal pure override returns (string) {
        (string attrs, string name, ) = vars.split_var_record(record);
        return name + "\t" + (attrs.strchr("s") > 0 ? "on" : "off");
    }
    function _name() internal pure override returns (string) {
        return "shopt";
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
