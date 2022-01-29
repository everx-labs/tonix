pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract look is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;
        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_look(flags, fs.get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(s_arg);
        }
    }

    function _look(string flags, string texts, string[] params) private pure returns (string out) {
        (string[] text, ) = stdio.split(texts, "\n");
        bool use_term_char = arg.flag_set("t", flags);

        string pattern = !params.empty() ? params[0] : "";
        string term_char = use_term_char && params.length > 1 ? params[1] : "\n";

        uint p = str.chr(pattern, term_char);
        if (p > 0)
            pattern = pattern.substr(0, p - 1);

        uint pattern_len = pattern.byteLength();
        for (string line: text) {
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
