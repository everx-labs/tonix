pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract cat is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string /*err*/, Err[] errors) {
        (, , string flags, string pi) = arg.get_env(argv);
        DirEntry[] contents = dirent.parse_param_index(pi);
        for (DirEntry de: contents) {
            (uint8 ft, string name, uint16 index) = de.unpack();
            if (ft != FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                (string[] lines, ) = stdio.split(text, "\n");
                out.append(_print(lines, flags));
            } else
                errors.push(Err(0, er.ENOENT, name));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _print(string[] lines, string flags) internal pure returns (string out) {
        (bool number_lines, bool number_nonempty_lines, bool show_ends, bool show_nonprint_ends, bool suppress_repeated_empty_lines,
            bool show_tabs, bool show_nonprint_tabs, bool show_all) = arg.flag_values("nbEesTtA", flags);
        bool dollar_at_line_end = show_ends || show_nonprint_ends || show_all;
        bool convert_tabs = show_tabs || show_nonprint_tabs || show_all;
        bool show_nonprints = arg.flag_set("v", flags) || show_nonprint_ends || show_nonprint_tabs || show_all;

        bool repeated_empty_line = false;
        uint n_lines = lines.length;
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
                line_out = str.aif(line_out, show_nonprints && len > 1 && line_in.substr(len - 2, 1) == "\x13", "^M");
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
