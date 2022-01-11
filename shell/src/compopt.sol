pragma ton-solidity >= 0.52.0;

import "Shell.sol";
import "compspec.sol";

contract compopt is Shell, compspec {

    function _compopt(string s_arg, string[] args, string short_options, mapping (uint => ItemHashMap) env_in) internal pure returns (uint16 ec, string out, mapping (uint => ItemHashMap) env, string s_action) {
        bool print_enabled = _get_option_value(short_options, "p");
        bool remove = _get_option_value(short_options, "r");
//        bool print = print_enabled || print_reusable;
        bool apply_default = _get_option_value(short_options, "D");
        bool apply_empty = _get_option_value(short_options, "E");
        bool apply_initial = _get_option_value(short_options, "I");

        bool use_option = _get_option_value(short_options, "o");

        mapping (uint => Item) comp_spec = env[tvm.hash("compspec")].value;

        env = env_in;

        if (use_option) {
            (string p_option, bool sign) = _get_dual_option_param(s_arg, "o");
            string s_option = sign ? " +o " : " -o ";
            s_option.append(p_option);
            for (string arg: args) {
                uint arg_hash = tvm.hash(arg);
                if (comp_spec.exists(arg_hash))
                    comp_spec[arg_hash].value.append(s_option);
            }
            s_action = "update_env";
        } else {
            for (string arg: args) {
                uint arg_hash = tvm.hash(arg);
                if (comp_spec.exists(arg_hash)) {
                    out.append("compopt " + comp_spec[arg_hash].value + " " + arg + "\n");
                }
            }
            s_action = "print_out";
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"compopt",
"[-o|+o option] [-DEI] [name ...]",
"Modify or display completion options.",
"Modify the completion options for each NAME, or, if no NAMEs are supplied,\n\
the completion currently being executed.  If no OPTIONs are given, print\n\
the completion options for each NAME or the current completion specification.",
"-o option       Set completion option OPTION for each NAME\n\
-D              Change options for the \"default\" command completion\n\
-E              Change options for the \"empty\" command completion\n\
-I              Change options for completion on the initial word\n\n\
Using `+o' instead of `-o' turns off the specified option.",
"Each NAME refers to a command for which a completion specification must\n\
have previously been defined using the `complete' builtin.  If no NAMEs\n\
are supplied, compopt must be called by a function currently generating\n\
completions, and the options for that currently-executing completion\n\
generator are modified.",
"Returns success unless an invalid option is supplied or NAME does not have a completion specification defined.");
    }
}
