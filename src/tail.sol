pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract tail is Utility {

   function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, Err[] errors) {
        (, , string flags, string pi) = arg.get_env(argv);
        (bool use_num_bytes, bool use_num_lines, bool never_headers, bool always_headers, bool null_delimiter, , ,) = arg.flag_values("cnqvz", flags);
        uint16 num_bytes = use_num_bytes ? str.toi(arg.opt_arg_value("c", argv)) : 0;
        uint16 num_lines = use_num_bytes ? 0 : use_num_lines ? str.toi(arg.opt_arg_value("n", argv)) : 10;
        string line_delimiter = null_delimiter ? "\x00" : "\n";

        DirEntry[] contents = dirent.parse_param_index(pi);
        bool print_headers = always_headers || !never_headers && contents.length > 1;
        for (DirEntry de: contents) {
            (uint8 ft, string name, uint16 index) = de.unpack();
            if (ft != FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                out.append(_print(text, print_headers ? name : "", num_lines, num_bytes, line_delimiter));
            } else
                errors.push(Err(0, er.ENOENT, name));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
        err = "";
    }

    function _print(string text, string file_name, uint16 num_lines, uint16 num_bytes, string line_delimiter) private pure returns (string out) {
        if (!file_name.empty())
             out = "==> " + file_name + " <==\n";
        if (num_lines > 0) {
            (string[] lines, uint n_lines) = stdio.split(text, "\n");
            uint len = math.min(n_lines, num_lines);
            for (uint i = n_lines - len; i < n_lines; i++)
                out.append(lines[i] + line_delimiter);
        } else if (num_bytes > 0) {
            uint len = text.byteLength();
            out = len < num_bytes ? text : text.substr(len - num_bytes);
            return line_delimiter == "\x00" ? stdio.translate(out, "\n", "\x00") : out;
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tail",
"[OPTION]... [FILE]...",
"output the last part of files",
"Print the last 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
"-c     output the last NUM bytes; or use -c +NUM to output starting with byte NUM of each file\n\
-n      output the last NUM lines, instead of the last 10;  or use -n +NUM to output starting with line NUM\n\
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
