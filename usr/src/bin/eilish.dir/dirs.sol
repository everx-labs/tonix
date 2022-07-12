pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract dirs is pbuiltin {

    function _main(shell_env e_in) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] page = e.environ[sh.DIRSTACK];
        rc = EXIT_SUCCESS;
        (bool clear_dir_stack, bool expand_tilde, bool entry_per_line, bool pos_entry_per_line, , , , ) =
            e.flag_values("clpv");
        bool print = expand_tilde || entry_per_line || pos_entry_per_line || e.params().empty();
        if (print) {
            for (string line: page)
                e.puts(line);
        } else if (clear_dir_stack)
            delete e.environ[sh.DIRSTACK];
    }

    function _name() internal pure override returns (string) {
        return "dirs";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"dirs",
"[-clpv] [+N] [-N]",
"Display directory stack.",
"Display the list of currently remembered directories.  Directories find their way onto the list\n\
with the `pushd' command; you can get back up through the list with the `popd' command.",
"-c        clear the directory stack by deleting all of the elements\n\
-l        do not print tilde-prefixed versions of directories relative to your home directory\n\
-p        print the directory stack with one entry per line\n\
-v        print the directory stack with one entry per line prefixed with its position in the stack",
"+N        Displays the Nth entry counting from the left of the list shown by dirs when invoked without options, starting with zero.\n\
-N        Displays the Nth entry counting from the right of the list shown by dirs when invoked without options, starting with zero.",
"Returns success unless an invalid option is supplied or an error occurs.");
    }

}
