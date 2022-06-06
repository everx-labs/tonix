pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract cut is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        (bool set_fields, bool use_delimiter, bool only_delimited, bool null_line_end, bool set_bytes, bool set_chars, , ) =
            p.flag_values("fdszbc");
        string line_delimiter = null_line_end ? "\x00" : "\n";
        string delimiter = use_delimiter ? p.opt_value("d") : "\t";
        string opt_err;
        if (use_delimiter && !set_fields)
            opt_err = "an input delimiter may be specified only when operating on fields";

        uint16 from;
        uint16 to;
        string range = p.opt_value(set_fields ? "f" : set_bytes ? "b" : set_chars ? "c" : "");
        if (!range.empty()) {
            if (range.strchr('-') > 0) {
                (string sfrom, string sto) = range.csplit('-');
                from = sfrom.empty() ? 1 : sfrom.toi();
                to = sto.empty() ? 0xFFFF : sto.toi();
            } else {
                from = range.toi();
                to = from;
            }
            if (from == 0 || to == 0)
                opt_err = "invalid byte/character position: " + range;
        } else
            opt_err = "you must specify a list of bytes, characters, or fields";

        if (opt_err.empty()) {
            if (from == 0 || to == 0)
                opt_err = "fields are numbered from 1";
            if (to < from)
                opt_err = "invalid decreasing range";
        }

        string out;
        if (opt_err.empty()) {
            for (string param: params) {
                s_of f = p.fopen(param, "r");
                if (!f.ferror()) {
                    while (!f.feof()) {
                        string line = f.fgetln();
                        if (set_fields) {
                            if (only_delimited && line.strchr(delimiter) == 0)
                                continue;
                            (string[] fields, uint n_fields) = line.split(delimiter);
                            uint cap = math.min(to, n_fields);
                            for (uint j = from - 1; j < cap; j++)
                                out.append(fields[j] + (j + 1 < cap ? delimiter : line_delimiter));
                        } else
                            out.append((to < line.strlen() ? line.substr(from - 1, to - from + 1) : line.substr(from - 1)) + line_delimiter);
                    }
                } else
                    p.perror("cannot open");
            }
        } else
            p.perror("cut: " + opt_err + "\nTry 'cut --help' for more information.\n");
        p.puts(out);
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
