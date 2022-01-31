pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract look is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, Err[] errors) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (, string[] params, string flags, string pi) = arg.get_env(argv);
        bool use_term_char = arg.flag_set("t", flags);
        string term_char = use_term_char ? arg.opt_arg_value("t", argv) : "\n";
        string pattern = !params.empty() ? params[0] : "";

        DirEntry[] contents = dirent.parse_param_index(pi);
        for (DirEntry de: contents) {
            (uint8 ft, string name, uint16 index) = de.unpack();
            if (ft != FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                (string[] lines, ) = stdio.split(text, "\n");
                out.append(_print(lines, flags, term_char, pattern));
            } else
                errors.push(Err(0, er.ENOENT, name));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _print(string[] lines, string /*flags*/, string term_char, string pattern) private pure returns (string out) {
        uint p = str.chr(pattern, term_char);
        if (p > 0)
            pattern = pattern.substr(0, p - 1);

        uint pattern_len = pattern.byteLength();
        for (string line: lines) {
            uint line_len = line.byteLength();
            if (line_len >= pattern_len)
                if (line.substr(0, pattern_len) == pattern)
                    out.append(line + "\n");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"look",
"[-bdf] [-t termchar] string [file ...]",
"display lines beginning with a given string",
"Displays any lines in file which contain string as a prefix.",
"-b      use a binary search on the given word list\n\
-d      dictionary character set and order, i.e., only alphanumeric characters are compared\n\
-f      ignore the case of alphabetic characters\n\
-t      specify a string termination character, i.e., only the characters in string up to and including the first occurrence of termchar are compared",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
