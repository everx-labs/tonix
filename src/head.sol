pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract head is Utility {

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
            for (uint i = 0; i < len; i++)
                out.append(lines[i] + line_delimiter);
        } else if (num_bytes > 0) {
            uint len = math.min(text.byteLength(), num_bytes);
            out = len < num_bytes ? text.substr(0, len) : text;
            return line_delimiter == "\x00" ? stdio.translate(out, "\n", "\x00") : out;
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"head",
"[OPTION]... [FILE]...",
"output the first part of files",
"Print the first 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
"-c     print the first NUM bytes of each file; with the leading '-', print all but the last NUM bytes of each file\n\
-n      print the first NUM lines instead of the first 10;  with the leading '-', print all but the last  NUM lines of each file\n\
-q      never print headers giving file names\n\
-v      always print headers giving file names\n\
-z      line delimiter is NUL, not newline",
"",
"Written by Boris",
"negative argument values are not yet implemented",
"tail",
"0.01");
    }

}
