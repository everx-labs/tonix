pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract column is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;
        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_column(flags, fs.get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(s_arg);
        }
    }

    function _column(string flags, string texts, string[] params) private pure returns (string out) {
        (string[] text, ) = stdio.split(texts, "\n");
        bool ignore_empty_lines = !arg.flag_set("e", flags);
        bool create_table = arg.flag_set("t", flags);
        bool use_delimiter = arg.flag_set("s", flags);

        string delimiter = use_delimiter && !params.empty() ? params[0] : " ";
        string[][] table;

        (, , , uint max_width, uint max_words_per_line) = stdio.line_and_word_count(text);
        uint max_columns = create_table ? max_words_per_line : (140 / max_width + 1);
        string[] cur_line;
        uint cur_columns;

        for (string s: text) {
            if (s.empty() && !ignore_empty_lines)
                continue;
            if (create_table) {
                (cur_line, cur_columns) = stdio.split(s, " ");
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
        out = fmt.format_table(table, delimiter, "\n", fmt.ALIGN_LEFT);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"column",
"[-entx] [-c columns] [-s sep] [file ...]",
"columnate lists",
"The column utility formats its input into multiple columns. Rows are filled before columns. Input is taken from file operands, or, by default, from the standard input. Empty lines are ignored unless the -e option is used.",
"-t      determine the number of columns the input contains and create a table. Columns are delimited with whitespace by default\n\
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
