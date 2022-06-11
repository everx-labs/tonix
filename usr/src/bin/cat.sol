pragma ton-solidity >= 0.61.0;

import "../include/putil.sol";

contract cat is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;
        (bool number_lines, bool number_nonempty_lines, bool show_ends, bool show_nonprint_ends, bool suppress_repeated_empty_lines,
            bool show_tabs, bool show_nonprint_tabs, bool show_all) = p.flag_values("nbEesTtA");
        bool dollar_at_line_end = show_ends || show_nonprint_ends || show_all;
        bool convert_tabs = show_tabs || show_nonprint_tabs || show_all;
        bool show_nonprints = p.flag_set("v") || show_nonprint_ends || show_nonprint_tabs || show_all;

        for (string param: p.params()) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {
                bool repeated_empty_line = false;
                uint i = 0;
                while (!f.feof()) {
                    string line_in = f.fgetln();
                    i++;
                    uint len = line_in.byteLength();

                    string line_out = (number_lines || (len > 0 && number_nonempty_lines)) ? format("   {}  ", i) : "";
                    if (len == 0) {
                        if (suppress_repeated_empty_lines) {
                            if (repeated_empty_line)
                                continue;
                            repeated_empty_line = true;
                        }
                    } else {
                        if (suppress_repeated_empty_lines && repeated_empty_line)
                            repeated_empty_line = false;
                        line_out.append(convert_tabs ? line_in.translate("\t", "^I") : line_in);
                        line_out.aif(show_nonprints && len > 1 && line_in.substr(len - 2, 1) == "\x13", "^M");
                    }
                    line_out.aif(dollar_at_line_end, "$");
                    p.puts(line_out);
                }
            } else
                p.perror(param);
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
