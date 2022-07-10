pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract popd is pbuiltin {

    function _main(s_proc, string[] params, shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        string[] dir_stack = e.environ[sh.DIRSTACK];
        uint n_dirs = dir_stack.length;
        if (params.empty()) {
            if (n_dirs < 2)
                e.perror("directory stack empty");
            else {
                dir_stack.pop();
                e.environ[sh.DIRSTACK] = dir_stack;
            }
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"popd",
"[-n] [+N | -N]",
"Remove directories from stack.",
"Removes entries from the directory stack.  With no arguments, removes the top directory from the stack, and changes to the new top directory.",
"-n     Suppresses the normal change of directory when removing directories from the stack, so only the stack is manipulated.",
"+N Removes the Nth entry counting from the left of the list shown by `dirs', starting with zero.  For example:\n\
    `popd +0' removes the first directory, `popd +1' the second.\n\
-N  Removes the Nth entry counting from the right of the list shown by `dirs', starting with zero.  For example:\n\
    `popd -0' removes the last directory, `popd -1' the next to last.\n\
The `dirs' builtin displays the directory stack.",
"Returns success unless an invalid argument is supplied or the directory change fails.");
    }
}
