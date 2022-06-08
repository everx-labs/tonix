pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract popd is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();
        string page = vmem.vmem_fetch_page(sv.vmem[1], 12);
        (string[] dir_stack, uint n_dirs) = page.split("\n");

        if (params.empty()) {
            if (n_dirs < 2)
                p.perror("directory stack empty");
            else {
                dir_stack.pop();
                page = libstring.join_fields(dir_stack, "\n");
                sv.vmem[1].vm_pages[12] = page;
            }
        }
        sv.cur_proc = p;
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
