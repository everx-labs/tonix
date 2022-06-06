pragma ton-solidity >= 0.60.0;

import "Shell.sol";
import "compspec.sol";

contract compopt is Shell, compspec {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        (bool apply_default, bool apply_empty, bool apply_initial, , , , , ) = arg.flag_values("DEI", flags);
        for (string p: params) {
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.strsplit(" ");
                if (apply_default) {
                    out.append("compopt ");
                    out.append(curr_attrs + "\n");
                    ec = EXECUTE_SUCCESS;
                } else if (apply_empty) {
                    out.append("compopt: _EmptycmD_: no completion specification\n");
                    ec = EXECUTE_FAILURE;
                } else if (apply_initial) {
                    out.append("compopt: _InitialWorD_: no completion specification\n");
                    ec = EXECUTE_FAILURE;
                }
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        (bool apply_default, bool apply_empty, bool apply_initial, , , , , ) = arg.flag_values("DEI", flags);
        for (string p: params) {
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.strsplit(" ");
                if (apply_default) {
                    res.append("compopt ");
                    res.append(curr_attrs + "\n");
                    ec = EXECUTE_SUCCESS;
                } else if (apply_empty) {
                    res.append("compopt: _EmptycmD_: no completion specification\n");
                    ec = EXECUTE_FAILURE;
                } else if (apply_initial) {
                    res.append("compopt: _InitialWorD_: no completion specification\n");
                    ec = EXECUTE_FAILURE;
                }
            }
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"compopt",
"[-o|+o option] [-DEI] [name ...]",
"Modify or display completion options.",
"ach NAME\n\
-D              Change options for the \"default\" command completion\n\
-E              Change options for the \"empty\" command completion\n\
-I              Change options for completion on the initial word\n\n\
Using `+o' instead of `-o' turns off the specified option.",
"Each NAME refModify the completion options for each NAME, or, if no NAMEs are supplied, the completion currently being\n\
executed.  If no OPTIONs are given, print the completion options for each NAME or the current completion specification.",
"-o option       Set completion option OPTION for eers to a command for which a completion specification must\n\
have previously been defined using the `complete' builtin.  If no NAMEs\n\
are supplied, compopt must be called by a function currently generating\n\
completions, and the options for that currently-executing completion\n\
generator are modified.",
"Returns success unless an invalid option is supplied or NAME does not have a completion specification defined.");
    }
}
