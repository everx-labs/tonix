pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract column is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, Err[] errors) {
        err = "";
        (, , string flags, string pi) = arg.get_env(argv);
        (bool use_delimiter, bool use_width, , , , , , ) = arg.flag_values("sc", flags);
        uint16 width = use_width ? str.toi(arg.opt_arg_value("c", argv)) : 140;
        string delimiter = use_delimiter ? arg.opt_arg_value("s", argv) : " ";

        DirEntry[] contents = dirent.parse_param_index(pi);
        for (DirEntry de: contents) {
            (uint8 ft, string name, uint16 index) = de.unpack();
            if (ft != FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                out.append(_print(text, flags, width, delimiter));
            } else
                errors.push(Err(0, er.ENOENT, name));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _print(string text, string flags, uint16 width, string delimiter) internal pure returns (string out) {
        (bool dont_ignore_empty_lines, bool create_table, , , , , , ) = arg.flag_values("et", flags);
        (string[] lines, ) = stdio.split(text, "\n");

        string[][] table;

        (, , , uint max_width, uint max_words_per_line) = stdio.line_and_word_count(lines);
        uint max_columns = create_table ? max_words_per_line : (width / max_width + 1);
        string[] cur_line;
        uint cur_columns;

        for (string s: lines) {
            if (s.empty() && !dont_ignore_empty_lines)
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
