pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract cut is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        (bool set_fields, bool use_delimiter, bool only_delimited, bool null_line_end, bool set_bytes, bool set_chars, , ) =
            arg.flag_values("fdszbc", flags);
        string line_delimiter = null_line_end ? "\x00" : "\n";
        string delimiter = use_delimiter ? arg.opt_arg_value("d", argv) : "\t";
        string opt_err;
        if (use_delimiter && !set_fields)
            opt_err = "an input delimiter may be specified only when operating on fields";

        uint16 from;
        uint16 to;
        string range = arg.opt_arg_value(set_fields ? "f" : set_bytes ? "b" : set_chars ? "c" : "", argv);
        if (!range.empty()) {
            if (str.chr(range, "-") > 0) {
                (string s_from, string s_to) = str.split(range, "-");
                from = s_from.empty() ? 1 : str.toi(s_from);
                to = s_to.empty() ? 0xFFFF : str.toi(s_to);
            } else {
                from = str.toi(range);
                to = from;
            }
            if (from == 0 || to == 0)
                opt_err = "invalid byte/character position: " + range;
        } else
            opt_err = "you must specify a list of bytes, characters, or fields";

        if (from == 0 || to == 0)
            opt_err = "fields are numbered from 1";
        if (to < from)
            opt_err = "invalid decreasing range";

        if (opt_err.empty()) {
            for (string s_arg: v_args) {
                (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
                if (ft != FT_UNKNOWN) {
                    string text = fs.get_file_contents(index, inodes, data);
                    (string[] lines, ) = stdio.split(text, "\n");
                    for (string line: lines) {
                        if (set_fields) {
                            if (only_delimited && str.chr(line, delimiter) == 0)
                                continue;
                            (string[] fields, uint n_fields) = stdio.split(line, delimiter);
                            uint cap = math.min(to, n_fields);
                            for (uint j = from - 1; j < cap; j++)
                                out.append(fields[j] + (j + 1 < cap ? delimiter : line_delimiter));
                        } else
                            out.append((to < line.byteLength() ? line.substr(from - 1, to - from + 1) : line.substr(from - 1)) + line_delimiter);
                   }
                } else
                    err.append("cut: " + s_arg + ": No such file or directory\n");
            }
        } else
            err.append("cut: " + opt_err + "\nTry 'cut --help' for more information.\n");
        ec = err.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"cut",
"OPTION... [FILE]...",
"remove sections from each line of files",
"Print selected parts of lines from each FILE to standard output.",
"-f     select only these fields; also print lines with no delimiter character, unless the -s option is specified\n\
-b      select only these bytes\n\
-c      select only these characters\n\
-d      use DELIM instead of TAB for field delimiter\n\
-s      do not print lines not containing delimiters\n\
-o      use STRING as the output delimiter. the default is to use the input delimiter\n\
-z      line delimiter is NUL, not newline empty",
"Use one, and only one of -b, -c or -f.  Each LIST is made up of one range, or many ranges separated by commas.\n\
Selected input is written in the same order that it is read, and is written exactly once. Each range is one of:\n\
  N     N\'th byte, character or field, counted from 1\n\
  N-    from N\'th byte, character or field, to end of line\n\
  N-M   from N\'th to M\'th (included) byte, character or field\n\
  -M    from first to M\'th (included) byte, character or field",
"Written by Boris",
"",
"",
"0.01");
    }
}
