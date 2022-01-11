pragma ton-solidity >= 0.53.0;

import "Shell.sol";
import "compspec.sol";

contract complete is Shell, compspec {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, string argv) = _get_args(e[IS_ARGS]);
        ec = 0;
        if (flags.empty())
            flags = "p";
        bool print = _flag_set("p", flags);
        bool print_all = params.empty();
        bool remove = _flag_set("r", flags);
        bool add = !print && !remove;
        bool add_function = _flag_set("F", flags);
        bool apply_to_command = _flag_set("C", flags);
        string comp_specs_page = e[IS_COMP_SPEC];

        if (print || params.empty()) {
            (string[] comp_specs, ) = _split(comp_specs_page, "\n");
            for (string cs: comp_specs) {
                (string comp_func, string command_list) = _item_value(cs);
                (string[] items, ) = _split(_trim_spaces(command_list), " ");
                for (string item: items)
                    out.append("complete -F " + comp_func + " " + item + "\n");
            }
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"complete",
"[-abcdefgjksuv] [-pr] [-DEI] [-o option] [-A action] [-G globpat] [-W wordlist]  [-F function] [-C command] [-X filterpat] [-P prefix] [-S suffix] [name ...]",
"Specify how arguments are to be completed",
"For each NAME, specify how arguments are to be completed.  If no options are supplied, existing completion specifications are\n\
printed in a way that allows them to be reused as input.",
"-p        print existing completion specifications in a reusable format\n\
-r        remove a completion specification for each NAME, or, if no NAMEs are supplied, all completion specifications\n\
-D        apply the completions and actions as the default for commands without any specific completion defined\n\
-E        apply the completions and actions to \"empty\" commands -- completion attempted on a blank line\n\
-I        apply the completions and actions to the initial (usually the command) word",
"When completion is attempted, the actions are applied in the order the uppercase-letter options are listed above.\n\
If multiple options are supplied, the -D option takes precedence over -E, and both take precedence over -I.",
"Returns success unless an invalid option is supplied or an error occurs.");
    }
}
