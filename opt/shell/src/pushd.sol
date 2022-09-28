pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract pushd is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] dir_stack = e.environ[sh.DIRSTACK];
        string[] dir_list = vars.array_val("dirstack", e.environ[sh.ARRAYVAR]);
        e.environ[sh.ARRAYVAR][sh.DIRSTACK];
        uint n_dirs = dir_stack.length;
        string[] params = e.params();
        if (params.empty()) {
            if (n_dirs < 2) {
                e.perror("no other directory");
                rc = EXIT_FAILURE;
            } else {
                string tmp = dir_stack[n_dirs - 1];
                dir_stack[n_dirs - 1] = dir_stack[n_dirs - 2];
                dir_stack[n_dirs - 2] = tmp;
                e.environ[sh.DIRSTACK] = dir_stack;
            }
            return (rc, e);
        }
        string dir = params[0];
        e.environ[sh.DIRSTACK].push(dir);
        dir_list.push(dir);
        e.environ[sh.ARRAYVAR][sh.DIRSTACK].append(" " + dir);
        if (!cc.flag_set("n"))
            e.syscall(libsyscall.SYS_chdir, [dir]);
        e.puts(libstring.join_fields(dir_list, ' '));
    }

    function _name() internal pure override returns (string) {
        return "pushd";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
"[-n] [+N | -N | dir]",
"Add directories to stack.",
"Adds a directory to the top of the directory stack, or rotates the stack, making the new top\n\
of the stack the current working directory.  With no arguments, exchanges the top two directories.",
"-n        Suppresses the normal change of directory when adding directories to the stack, so only the stack is manipulated.",
"+N        Rotates the stack so that the Nth directory (counting from the left of the list shown by `dirs', starting with zero) is at the top.\n\
-N        Rotates the stack so that the Nth directory (counting from the right of the list shown by `dirs', starting with zero) is at the top.\n\
dir       Adds DIR to the directory stack at the top, making it the new current working directory.\n\
The `dirs' builtin displays the directory stack.",
"Returns success unless an invalid argument is supplied or the directory change fails.");
    }
}
