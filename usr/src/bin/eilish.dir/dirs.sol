pragma ton-solidity >= 0.61.1;

import "../../lib/fs.sol";
import "pbuiltin.sol";

contract dirs is pbuiltin {

    function _main(s_proc p_in, string[] params, shell_env e) internal pure override returns (s_proc p) {
        p = p_in;
        string page = e.e_dirstack; //vmem.vmem_fetch_page(sv.vmem[1], 12);

        (bool clear_dir_stack, bool expand_tilde, bool entry_per_line, bool pos_entry_per_line, , , , ) =
            p.flag_values("clpv");
        bool print = expand_tilde || entry_per_line || pos_entry_per_line || params.empty();
        if (print)
            p.puts(page);
        else if (clear_dir_stack)
            //sv.vmem[1].vm_pages[12] = "";
            e.e_dirstack = "";
    }

    function _print_dir_contents(uint16 start_dir_index, mapping (uint16 => bytes) data) internal pure returns (string out) {
        (DirEntry[] contents, int16 status) = udirent.read_dir_data(data[start_dir_index]);
        if (status < 0) {
            out.append(format("Error: {} \n", status));
        } else {
            uint len = uint(status);
            for (uint16 j = 0; j < len; j++) {
                (uint8 t, string name, uint16 index) = contents[j].unpack();
                if (t == ft.FT_UNKNOWN)
                    continue;
                out.append(udirent.dir_entry_line(index, name, t));
            }
        }
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
