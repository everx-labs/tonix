pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract look is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);
        string[] params;
        for (string arg: args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_look(flags, _get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(arg);
        }
    }

    function _look(string flags, string texts, string[] params) private pure returns (string out) {
        (string[] text, ) = _split(texts, "\n");
//        bool binary_search = (flags & _b) > 0;
//        bool alphanum_set = (flags & _d) > 0;
//        bool ignore_case = (flags & _f) > 0;
        bool use_term_char = _flag_set("t", flags);

        string pattern = !params.empty() ? params[0] : "";
        string term_char = use_term_char && params.length > 1 ? params[1] : "\n";

        uint p = _strchr(pattern, term_char);
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

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("look", "display lines beginning with a given string", "[-bdf] [-t termchar] string [file ...]",
            "Displays any lines in file which contain string as a prefix.",
            "bdft", 1, 3, [
            "use a binary search on the given word list",
            "dictionary character set and order, i.e., only alphanumeric characters are compared",
            "ignore the case of alphabetic characters",
            "specify a string termination character, i.e., only the characters in string up to and including the first occurrence of termchar are compared"]);
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
