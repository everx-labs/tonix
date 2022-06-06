pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract tail is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        (bool use_num_bytes, bool use_num_lines, bool never_headers, bool always_headers, bool null_delimiter, , ,) = p.flag_values("cnqvz");
        uint16 num_bytes = use_num_bytes ? p.opt_value_int("c") : 0;
        uint16 num_lines = use_num_bytes ? 0 : use_num_lines ? p.opt_value_int("n") : 10;
        string line_delimiter = null_delimiter ? "\x00" : "\n";
        string[] params = p.params();

        bool print_headers = always_headers || !never_headers && params.length > 1;
        for (string param: params) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {
                if (print_headers)
                    p.puts("==> " + param + " <==");
                string text = f.buf.sbuf_data();
                if (num_lines > 0) {
                    (string[] lines, uint n_lines) = text.split("\n");
                    uint len = math.min(n_lines, num_lines);
                    for (uint i = n_lines - len; i < n_lines; i++)
                        p.puts(lines[i] + line_delimiter);
                } else if (num_bytes > 0) {
                    uint len = text.strlen();
                    string out = len < num_bytes ? text : text.substr(len - num_bytes);
                    if (null_delimiter)
                        out.translate("\n", "\x00");
                    p.puts(out);
                }
            } else
                p.perror("cannot open");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tail",
"[OPTION]... [FILE]...",
"output the last part of files",
"Print the last 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
"-c     output the last NUM bytes; or use -c +NUM to output starting with byte NUM of each file\n\
-n      output the last NUM lines, instead of the last 10; or use -n +NUM to output starting with line NUM\n\
-q      never output headers giving file names\n\
-v      always output headers giving file names\n\
-z      line delimiter is NUL, not newline",
"",
"Written by Boris",
"positive argument values are not yet implemented",
"head",
"0.01");
    }

}
