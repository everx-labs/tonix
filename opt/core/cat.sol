pragma ton-solidity >= 0.67.0;

import "putil.sol";
contract cat is putil {
    using libstring for string;
    function _main(shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        s_of res = e.stdout();
        for (string param: e.params()) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror())
                res = _process_file(f, res, e);
            else
                e.perror(param);
        }
        e.ofiles[libfdt.STDOUT_FILENO] = res;
    }

    function _process_file(s_of f, s_of f_in, shell_env e) internal pure returns (s_of res) {
        res = f_in;
        (bool number_lines, bool number_nonempty_lines, bool show_ends, bool show_nonprint_ends, bool suppress_repeated_empty_lines,
            bool show_tabs, bool show_nonprint_tabs, bool show_all) = e.flag_values("nbEesTtA");
        bool dollar_at_line_end = show_ends || show_nonprint_ends || show_all;
        bool convert_tabs = show_tabs || show_nonprint_tabs || show_all;
        bool show_nonprints = e.flag_set("v") || show_nonprint_ends || show_nonprint_tabs || show_all;
        bool repeated_empty_line = false;
        uint i = 0;
        string line_in;
        uint len;
        while (!f.feof()) {
            line_in = f.fgetln();
            i++;
            len = line_in.byteLength();
            if (number_lines || len > 0 && number_nonempty_lines)
                res.fputs(format("   {}  ", i));
            if (len == 0) {
                if (suppress_repeated_empty_lines) {
                    if (repeated_empty_line)
                        continue;
                    repeated_empty_line = true;
                }
            } else {
                if (suppress_repeated_empty_lines && repeated_empty_line)
                    repeated_empty_line = false;
                res.fputs(convert_tabs ? line_in.translate("\t", "^I") : line_in);
//                if (show_nonprints && len > 1 && line_in.substr(len - 2, 1) == "\x13")
                if (show_nonprints && len > 1 && bytes(line_in)[len - 2] == 0x13)
                    res.fputs("^M");
            }
            if (dollar_at_line_end)
                res.fputc('$');
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
"0.02");
    }

}
