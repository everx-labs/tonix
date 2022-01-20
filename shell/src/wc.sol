pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../include/Commands.sol";

contract wc is Utility, Commands {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = _get_env(argv);

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
            print_bytes = _flag_set("c", flags);
            print_chars = _flag_set("m", flags);
            print_lines = _flag_set("l", flags);
            print_max_width = _flag_set("L", flags);
            print_words = _flag_set("w", flags);
        }

        string[][] table;
        Column[] columns_format = [
            Column(print_lines, 4, ALIGN_LEFT),
            Column(print_words, 5, ALIGN_RIGHT),
            Column(print_chars, 6, ALIGN_RIGHT),
            Column(print_bytes, 6, ALIGN_RIGHT),
            Column(print_max_width, 4, ALIGN_RIGHT),
            Column(true, 32, ALIGN_LEFT)];

        for (string arg: params) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, wd, inodes, data);
            if (ft == FT_UNKNOWN) {
                ec = EXECUTE_FAILURE;
                err.append(arg + " not found\n");
            } else {
                string texts = _get_file_contents(index, inodes, data);
                (string[] text, uint n_fields) = _split(texts, "\n");
                if (n_fields == 0)
                    continue;
                (uint line_count, uint word_count, uint char_count, uint max_width, ) = _line_and_word_count(text);

                if (count_totals) {
                    total_lines += line_count;
                    total_words += word_count;
                    total_chars += char_count;
                    total_bytes += char_count;
                    if (overall_max_width < max_width)
                        overall_max_width = max_width;
                }

                table.push([
                    format("{}", line_count),
                    format("{}", word_count),
                    format("{}", char_count),
                    format("{}", char_count),
                    format("{}", max_width),
                    arg]);
            }
        }
        if (count_totals)
            table.push([
                format("{}", total_lines),
                format("{}", total_words),
                format("{}", total_chars),
                format("{}", total_bytes),
                format("{}", overall_max_width),
                "total"]);
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("wc", "print newline, word, and byte counts for each file", "[OPTION]... [FILE]...",
            "Print newline, word, and byte counts for each FILE, and a total line if more than one FILE is specified. A word is a non-zero-length sequence of characters delimited by white space.",
            "cmlLw", 1, M, [
            "print the byte counts",
            "print the character counts",
            "print the newline counts",
            "print the maximum display width",
            "print the word counts"]);
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
