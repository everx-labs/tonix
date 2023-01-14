pragma ton-solidity >= 0.63.0;

import "pbuiltin.sol";

contract complete is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        rc = EXIT_SUCCESS;

        string[] params = cc.params();
        bool xprint = cc.flag_set("p");
//        string comp_specs_page = vmem.vmem_fetch_page(sv.vmem[1], 11);
        /* bool print_all = params.empty();
        bool remove = arg.flag_set("r", flags);
        bool add = !xprint && !remove;
        bool add_function = arg.flag_set("F", flags);
        bool apply_to_command = arg.flag_set("C", flags); */
        string[] comp_specs_page = e.environ[sh.COMMAND];
        if (xprint || params.empty()) {
            for (string cs: comp_specs_page) {
                (string comp_func, string command_list) = vars.item_value(cs);
                command_list.trim_spaces();
                (string[] items, ) = command_list.split(" ");
                for (string item: items)
                    e.puts("complete -F " + comp_func + " " + item);
            }
        }
    }
    function _name() internal pure override returns (string) {
        return "complete";
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
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
