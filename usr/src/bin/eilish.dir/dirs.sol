pragma ton-solidity >= 0.60.0;

import "Shell.sol";
import "../../lib/fs.sol";

contract dirs is Shell {

    function _print_dir_contents(uint16 start_dir_index, mapping (uint16 => bytes) data) internal pure returns (uint8 ec, string out) {
        (DirEntry[] contents, int16 status) = udirent.read_dir_data(data[start_dir_index]);
        if (status < 0) {
            out.append(format("Error: {} \n", status));
            ec = EXECUTE_FAILURE;
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

    function builtin_read_fs(string /*args*/, string /*pool*/, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string res) {
//        (string[] params, string flags, ) = arg.get_args(args);
//        (bool clear_dir_stack, bool expand_tilde, bool entry_per_line, bool pos_entry_per_line, bool res_abs_path, bool dirent_stack, bool dump_dirs, ) =
//            arg.flag_values("clpvrsd", flags);
//        bool print = expand_tilde || entry_per_line || pos_entry_per_line || params.empty();
//        string page = pool;
        string out;
//        string sattrs = "--";
//        string home_dir = vars.val("HOME", page);
        /*if (res_abs_path) {
            string spath = params[0];
            uint16 dir_index = fs.resolve_abs_path(spath, inodes, data);
            res.append(spath + ": " + str.toa(dir_index) + "\n");
        }*/
        uint16 root_dir_index = fs.resolve_absolute_path("/", inodes, data);
        if (root_dir_index >= sb.ROOT_DIR) {
            (ec, out) = _print_dir_contents(root_dir_index, data);
        }
        res.append(out);
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
