pragma ton-solidity >= 0.67.0;

import "putil.sol";

contract tail is putil {
    using libstring for string;
    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        (bool use_num_bytes, bool use_num_lines, bool never_headers, bool always_headers, bool null_delimiter, , ,) = e.flag_values("cnqvz");
        uint16 num_bytes = use_num_bytes ? e.opt_value_int("c") : 0;
        uint16 num_lines = use_num_bytes ? 0 : use_num_lines ? e.opt_value_int("n") : 10;
        string line_delimiter = null_delimiter ? "\x00" : "\n";
        string[] params = e.params();

        bool print_headers = always_headers || !never_headers && params.length > 1;
        for (string param: params) {
//            s_of f = p.fopen(param, "r");
            string text = e.read_file(param);
//            if (!f.ferror()) {
                if (print_headers)
                    e.puts("==> " + param + " <==");
//                string text = f.buf.sbuf_data();
                if (num_lines > 0) {
                    (string[] lines, uint n_lines) = text.split("\n");
                    uint len = math.min(n_lines, num_lines);
                    for (uint i = n_lines - len; i < n_lines; i++)
                        e.puts(lines[i] + line_delimiter);
                } else if (num_bytes > 0) {
                    uint len = str.strlen(text);
                    string out = len < num_bytes ? text : text.substr(len - num_bytes);
                    if (null_delimiter)
                        out.translate("\n", "\x00");
                    e.puts(out);
                }
  //          } else
//                p.perror(param + ": cannot open");
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
"0.02");
    }

}
