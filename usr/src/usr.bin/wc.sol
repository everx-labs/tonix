pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract wc is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (uint16 wd, string[] params, , ) = p.get_env();

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

        if (!p.flags_empty()) {
            print_bytes = p.flag_set("c");
            print_chars = p.flag_set("m");
            print_lines = p.flag_set("l");
            print_max_width = p.flag_set("L");
            print_words = p.flag_set("w");
        }

        string[][] table;
        Column[] columns_format = [
            Column(print_lines, 4, fmt.LEFT),
            Column(print_words, 5, fmt.RIGHT),
            Column(print_chars, 6, fmt.RIGHT),
            Column(print_bytes, 6, fmt.RIGHT),
            Column(print_max_width, 4, fmt.RIGHT),
            Column(true, 32, fmt.LEFT)];

        for (string arg: params) {
            (uint16 index, uint8 t, , ) = fs.resolve_relative_path(arg, wd, inodes, data);
            if (t == ft.FT_UNKNOWN) {
                p.perror(arg + " not found");
            } else {
                string texts = fs.get_file_contents(index, inodes, data);
                (string[] text, uint n_fields) = texts.split("\n");
                if (n_fields == 0)
                    continue;
                (uint line_count, uint word_count, uint char_count, uint max_width, ) = libstring.line_and_word_count(text);

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
        p.puts(fmt.format_table_ext(columns_format, table, " ", "\n"));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"wc",
"[OPTION]... [FILE]...",
"print newline, word, and byte counts for each file",
"Print newline, word, and byte counts for each FILE, and a total line if more than one FILE is specified.\n\
A word is a non-zero-length sequence of characters delimited by white space.",
"-c      print the byte counts\n\
-m      print the character counts\n\
-l      print the newline counts\n\
-L      print the maximum display width\n\
-w      print the word counts",
"",
"Written by Boris",
"",
"",
"0.02");
    }
}
