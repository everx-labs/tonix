pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract dirs is Shell {

    function _print_dir_contents(uint16 start_dir_index, mapping (uint16 => bytes) data) internal pure returns (uint8 ec, string out) {
        (DirEntry[] contents, int16 status) = _read_dir_data(data[start_dir_index]);
        if (status < 0) {
            out.append(format("Error: {} \n", status));
            ec = EXECUTE_FAILURE;
        } else {
            uint len = uint(status);
            for (uint16 j = 0; j < len; j++) {
                (uint8 ft, string name, uint16 index) = contents[j].unpack();
                if (ft == FT_UNKNOWN)
                    continue;
                out.append(_dir_entry_line(index, name, ft));
            }
        }
    }

    function builtin_read_fs(string args, string pool, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = _get_args(args);
        (bool clear_dir_stack, bool expand_tilde, bool entry_per_line, bool pos_entry_per_line, , , , ) = _flag_values("clpv", flags);
        bool print = expand_tilde || entry_per_line || pos_entry_per_line || params.empty();
        string page = pool;
        string out;
        string s_attrs = "--";
        string home_dir = _val("HOME", page);

        uint16 root_dir_index = _resolve_absolute_path("/", inodes, data);
        if (root_dir_index >= ROOT_DIR) {
            (ec, out) = _print_dir_contents(root_dir_index, data);
            /*(DirEntry[] contents, int16 status) = _read_dir_data(data[root_dir_index]);
            if (status < 0) {
                out.append(format("Error: {} \n", status));
                ec = EXECUTE_FAILURE;
            } else {
                uint len = uint(status);
                for (uint16 j = 0; j < len; j++) {
                    (uint8 ft, string name, uint16 index) = contents[j].unpack();
                    if (ft == FT_UNKNOWN)
                        continue;
                    out.append(_dir_entry_line(index, name, ft));
                }
            }*/
        }
        res = out;
    }

    uint16 constant ARRAY_WALK_FORWARD  = 8;
    uint16 constant ARRAY_WALK_REVERSE  = 16;
    uint16 constant ARRAY_PRINT_INDEX   = 64;
    uint16 constant ARRAY_PRINT_INVERSE_INDEX = 128;

    /*function _print_array(string contents, uint16 attrs, string ifs, string ofs) internal pure returns (string out) {
        bool walk_reverse = (attrs & ARRAY_WALK_REVERSE) > 0;
        bool print_index = (attrs & ARRAY_PRINT_INDEX) > 0;
        bool print_inverse_index = (attrs & ARRAY_PRINT_INVERSE_INDEX) > 0;

        (string[] fields, uint n_fields) = _split(contents, ifs);
        for (uint i = 0; i < n_fields; i++) {
            if (print_index)
                out.append(format("{} ", i));
            if (print_inverse_index)
                out.append(format("{} ", n_fields - i));
            out.append(fields[walk_reverse ? n_fields - i : i] + ofs);
        }
    }

    function read_fs_to_env(Job job_in, mapping (uint => ItemHashMap) env_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (Job job, mapping (uint => ItemHashMap) env) {
        (, , , , , , , , , , string s_args, , string short_options, , , , , , ) = job_in.unpack();

        uint16 ec;
        string s_action;

        bool clear_dir_stack = _get_option_value(short_options, "c");
        bool expand_tilde = _get_option_value(short_options, "l");
        bool entry_per_line = _get_option_value(short_options, "p");
        bool pos_entry_per_line = _get_option_value(short_options, "v");
        bool print = expand_tilde || entry_per_line || pos_entry_per_line || s_args.empty();

        env = env_in;
        Item dir_stack = env[tvm.hash("stack")].value[tvm.hash("dirs")];
        if (print) {
            uint16 attrs = ARRAY_WALK_REVERSE;
            if (pos_entry_per_line)
                attrs += ARRAY_PRINT_INVERSE_INDEX;
            string line_delimiter = pos_entry_per_line || entry_per_line ? "\n" : " ";
            string s_dirs = _print_array(dir_stack.value, attrs , ":", line_delimiter);
            if (expand_tilde) {
                string home_dir = _lookup_value("shell_vars", "HOME", env);
                s_dirs = _translate(s_dirs, "~", home_dir);
            }
            job.stdout.append(s_dirs);
            s_action = "print_out";
        } else if (clear_dir_stack) {
            delete env[tvm.hash("stack")].value[tvm.hash("dirs")].value;
            s_action = "update_env";
        }
        job.ec = ec;
        if (ec == 0)
            job.s_action = "update_env";
        else
            job.s_action = "print_out";
    }*/

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
