pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract head is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (, , , string pi) = p.get_env();
        (bool use_num_bytes, bool use_num_lines, bool never_headers, bool always_headers, bool null_delimiter, , ,) = p.flag_values("cnqvz");
        uint16 num_bytes = use_num_bytes ? p.opt_value_int("c") : 0;
        uint16 num_lines = use_num_bytes ? 0 : use_num_lines ? p.opt_value_int("n") : 10;
        string line_delimiter = null_delimiter ? "\x00" : "\n";

        DirEntry[] contents = udirent.parse_param_index(pi);
        bool print_headers = always_headers || !never_headers && contents.length > 1;
        for (DirEntry de: contents) {
            (uint8 t, string name, uint16 index) = de.unpack();
            if (t != ft.FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                p.puts(_print(text, print_headers ? name : "", num_lines, num_bytes, line_delimiter));
            } else
                p.perror(name);// er.ENOENT
        }
    }

    function _print(string text, string file_name, uint16 num_lines, uint16 num_bytes, string line_delimiter) private pure returns (string out) {
        if (!file_name.empty())
             out = "==> " + file_name + " <==\n";
        if (num_lines > 0) {
            (string[] lines, uint n_lines) = text.split("\n");
            uint len = math.min(n_lines, num_lines);
            for (uint i = 0; i < len; i++)
                out.append(lines[i] + line_delimiter);
        } else if (num_bytes > 0) {
            uint len = math.min(text.byteLength(), num_bytes);
            out = len < num_bytes ? text.substr(0, len) : text;
            return line_delimiter == "\x00" ? libstring.translate(out, "\n", "\x00") : out;
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
"0.02");
    }

}
