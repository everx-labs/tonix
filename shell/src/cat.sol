pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract cat is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        for (string s_arg: params) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_cat(flags, fs.get_file_contents(index, inodes, data)) + "\n");
            else {
                err.append("Failed to resolve relative path for" + s_arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _cat(string f, string text) private pure returns (string out) {
        bool number_lines = arg.flag_set("n", f);
        bool number_nonempty_lines = arg.flag_set("b", f);
        bool dollar_at_line_end = arg.flag_set("E", f) || arg.flag_set("e", f) || arg.flag_set("A", f);
        bool suppress_repeated_empty_lines = arg.flag_set("s", f);
        bool convert_tabs = arg.flag_set("T", f) || arg.flag_set("t", f) || arg.flag_set("A", f);
        bool show_nonprinting = arg.flag_set("v", f) || arg.flag_set("e", f) || arg.flag_set("t", f) || arg.flag_set("A", f);

        bool repeated_empty_line = false;
        (string[] lines, uint n_lines) = stdio.split(text, "\n");
        for (uint i = 0; i < n_lines; i++) {
            string line_in = lines[i];
            uint len = line_in.byteLength();

            string line_out = (number_lines || (len > 0 && number_nonempty_lines)) ? format("   {}  ", uint16(i + 1)) : "";
            if (len == 0) {
                if (suppress_repeated_empty_lines) {
                    if (repeated_empty_line)
                        continue;
                    repeated_empty_line = true;
                }
            } else {
                if (suppress_repeated_empty_lines && repeated_empty_line)
                    repeated_empty_line = false;
                line_out.append(convert_tabs ? stdio.translate(line_in, "\t", "^I") : line_in);
                line_out = str.aif(line_out, show_nonprinting && len > 1 && line_in.substr(len - 2, 1) == "\x13", "^M");
            }
            line_out = str.aif(line_out, dollar_at_line_end, "$");
            out.append(line_out + "\n");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"cat",
"[OPTION]... [FILE]...",
"concatenate files and print on the standard output",
"Concatenate FILE(s) to standard output.",
"-A      equivalent to -vET\n\
-b      number nonempty output lines, overrides -n\n\
-e      equivalent to -vE\n\
-E      display $ at end of each line\n\
-n      number all output lines\n\
-s      suppress repeated empty output lines\n\
-t      equivalent to -vT\n\
-T      display TAB characters as ^I\n\
-u      (ignored)\n\
-v      use ^ and M- notation, except for LFD and TAB",
"",
"Written by Boris",
"none known so far",
"tac(1)",
"0.01");
    }

}
