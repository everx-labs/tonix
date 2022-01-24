pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract shopt is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        ec = 0;
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);

        string s_args = _value_of("@", e[IS_SPECIAL_VAR]);

        uint16 page_index = IS_SHELL_OPTION;
        string page = e[page_index];

        bool print_reusable = _flag("p", e);
        bool print_list = e[IS_OPTION_VALUE].empty();
        bool all = params.empty();

        bool set_opt = _flag("s", e);
        bool unset_opt = _flag("u", e);
        bool filter = set_opt || unset_opt;
        bool do_unset = unset_opt && !all;
        bool print = print_reusable || print_list;

        string s_attrs = "--";

        if (print) {
            (string[] items, ) = stdio.split_line(page, "\n", "\n");
            for (string item: items) {
                /*(string attrs, string name, string value);// = _parse_var(item);
                bool is_on = stdio.strchr(s_attrs, "n") == 0;
                bool show = !filter || is_on && set_opt || !is_on && unset_opt;
                if (!show)
                    continue;
                if (print_reusable)
                    out.append("shopt -" + (is_on ? "s" : "u") + name + "\n");
                else if (print_list)
                    out.append(name + "\t" + (is_on ? "on\n" : "off\n"));*/
            }
        } else {
//            (string[] args, ) = stdio.split(s_args, " ");
            for (string arg: params) {
                /*uint arg_hash = tvm.hash(arg);
                Item i = shell_options.exists(arg_hash) ? shell_options[arg_hash] : Item(arg, attrs, "");
                i.attrs = do_unset ? (i.attrs | ATTR_DISABLED) : (i.attrs & ~ATTR_DISABLED);
                env_in[shell_options_key].value[arg_hash] = i;*/
//                page = _assign(s_attrs, arg, page);
            }
            e[page_index] = page;
        }
            /*for ((, Item i): shell_options) {
                bool is_on = (i.attrs & ATTR_DISABLED) == 0;
                bool show = !filter || is_on && set_opt || !is_on && unset_opt;
                if (!show)
                    continue;
                if (print_reusable)
                    out.append("shopt -" + (is_on ? "s" : "u") + i.name + "\n");
                else if (print_list)
                    out.append(i.name + "\t" + (is_on ? "on\n" : "off\n"));
            }
            s_action = "print_out";
            }}*/
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
