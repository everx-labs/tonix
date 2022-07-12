pragma ton-solidity >= 0.62.0;

import "putil.sol";

contract column is putil {

    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        (bool use_delimiter, bool use_width, bool dont_ignore_empty_lines, bool create_table) = e.flags_set("scet");
        uint16 width = use_width ? e.opt_value_int("c") : 140;
        string delimiter = use_delimiter ? e.opt_value("s") : " ";

        for (string param: e.params()) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror())
                e.puts(_print(f, dont_ignore_empty_lines, create_table, width, delimiter));
            else
                e.perror("cannot open");
        }
    }

    function _print(s_of f, bool dont_ignore_empty_lines, bool create_table, uint16 width, string delimiter) internal pure returns (string out) {
        (string[] lines, ) = f.split();
        string[][] table;

        (, , , uint max_width, uint max_words_per_line) = libstring.line_and_word_count(lines);
        uint max_columns = create_table ? max_words_per_line : (width / max_width + 1);
        string[] cur_line;
        uint cur_columns;

        while (!f.feof()) {
            string s = f.getline();
            if (s.empty() && !dont_ignore_empty_lines)
                continue;
            if (create_table) {
                (cur_line, cur_columns) = s.split(" ");
                for (uint i = 0; i < max_columns - cur_columns; i++)
                    cur_line.push(" ");
                table.push(cur_line);
            } else {
                cur_line.push(s);
                cur_columns++;
                if (cur_columns == max_columns) {
                    cur_columns = 0;
                    table.push(cur_line);
                    delete cur_line;
                }
            }
        }
        out = fmt.format_table(table, delimiter, "\n", fmt.LEFT);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"column",
"[-entx] [-c columns] [-s sep] [file ...]",
"columnate lists",
"The column utility formats its input into multiple columns. Rows are filled before columns. Input is taken from file operands, or, by default, from the standard input. Empty lines are ignored unless the -e option is used.",
"-t      determine the number of columns the input contains and create a table. Columns are delimited with whitespace by default\n\
-c      output is formatted for a display columns wide\n\
-x      fill columns before filling rows\n\
-n      disables merging multiple adjacent delimiters into a single delimiter when using the -t option\n\
-e      do not ignore empty lines",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
