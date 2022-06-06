pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract look is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        if (params.empty()) {
            (string name, string synopsis, , , , , , , , ) = _command_help().unpack();
            p.puts("Usage: " + name + " " + synopsis);
            return p;
        }
        bool use_term_char = p.flag_set("t");
        string term_char = use_term_char ? p.opt_value("t") : "\n";
        string pattern = !params.empty() ? params[0] : "";
        uint q = pattern.strchr(term_char);
        if (q > 0)
            pattern = pattern.substr(0, q - 1);
        uint pattern_len = pattern.strlen();

        for (string param: p.params()) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    uint line_len = line.strlen();
                    if (line_len >= pattern_len)
                        if (line.substr(0, pattern_len) == pattern)
                            p.puts(line);
                }
            } else
                p.perror("cannot open");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"look",
"[-bdf] [-t char] string [file ...]",
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
