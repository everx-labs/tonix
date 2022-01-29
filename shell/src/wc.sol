pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract wc is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);

        bool print_lines = true;
        bool print_words = true;
        bool print_chars = true;
        bool print_bytes = false;
        bool print_max_width = false;

        uint total_lines;
        uint total_words;
        uint total_chars;
        uint total_bytes;
        uint overall_max_width;

        uint n_texts = params.length;
        bool count_totals = n_texts > 1;

        if (!flags.empty()) {
            print_bytes = arg.flag_set("c", flags);
            print_chars = arg.flag_set("m", flags);
            print_lines = arg.flag_set("l", flags);
            print_max_width = arg.flag_set("L", flags);
            print_words = arg.flag_set("w", flags);
        }

        string[][] table;
        Column[] columns_format = [
            Column(print_lines, 4, fmt.ALIGN_LEFT),
            Column(print_words, 5, fmt.ALIGN_RIGHT),
            Column(print_chars, 6, fmt.ALIGN_RIGHT),
            Column(print_bytes, 6, fmt.ALIGN_RIGHT),
            Column(print_max_width, 4, fmt.ALIGN_RIGHT),
            Column(true, 32, fmt.ALIGN_LEFT)];

        for (string arg: params) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(arg, wd, inodes, data);
            if (ft == FT_UNKNOWN) {
                ec = EXECUTE_FAILURE;
                err.append(arg + " not found\n");
            } else {
                string texts = fs.get_file_contents(index, inodes, data);
                (string[] text, uint n_fields) = stdio.split(texts, "\n");
                if (n_fields == 0)
                    continue;
                (uint line_count, uint word_count, uint char_count, uint max_width, ) = stdio.line_and_word_count(text);

                if (count_totals) {
                    total_lines += line_count;
                    total_words += word_count;
                    total_chars += char_count;
                    total_bytes += char_count;
                    if (overall_max_width < max_width)
                        overall_max_width = max_width;
                }

                table.push([
                    str.toa(line_count),
                    str.toa(word_count),
                    str.toa(char_count),
                    str.toa(char_count),
                    str.toa(max_width),
                    arg]);
            }
        }
        if (count_totals)
            table.push([
                str.toa(total_lines),
                str.toa(total_words),
                str.toa(total_chars),
                str.toa(total_bytes),
                str.toa(overall_max_width),
                "total"]);
        out = fmt.format_table_ext(columns_format, table, " ", "\n");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"wc",
"[OPTION]... [FILE]...",
"print newline, word, and byte counts for each file",
"Print newline, word, and byte counts for each FILE, and a total line if more than one FILE is specified. A word is a non-zero-length sequence of characters delimited by white space.",
"-c      print the byte counts\n\
-m      print the character counts\n\
-l      print the newline counts\n\
-L      print the maximum display width\n\
-w      print the word counts",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
