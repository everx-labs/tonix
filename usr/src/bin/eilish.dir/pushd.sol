pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract pushd is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();
        string page = vmem.vmem_fetch_page(sv.vmem[1], 12);
        (string[] dir_stack, uint n_dirs) = page.split("\n");

        if (params.empty()) {
            if (n_dirs < 2)
                p.perror("no other directory");
            else {
                string tmp = dir_stack[n_dirs - 1];
                dir_stack[n_dirs - 1] = dir_stack[n_dirs - 2];
                dir_stack[n_dirs - 2] = tmp;
                page = libstring.join_fields(dir_stack, "\n");
                sv.vmem[1].vm_pages[12] = page;
            }
        }
        sv.cur_proc = p;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"pushd",
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
