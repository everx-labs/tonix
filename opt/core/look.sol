pragma ton-solidity >= 0.67.0;

import "putil.sol";

contract look is putil {
    using str for string;
    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        if (params.empty()) {
            (string name, string synopsis, , , , , , , , ) = _command_help().unpack();
            e.puts("Usage: " + name + " " + synopsis);
            return e;
        }
        bool use_term_char = e.flag_set("t");
        bytes1 term_char = '\n';
        if (use_term_char) {
            bytes bb = e.opt_value("t");
            term_char = bb[0];
        }
        string pattern = !params.empty() ? params[0] : "";
        uint q = pattern.strchr(term_char);
        if (q > 0)
            pattern = pattern.substr(0, q - 1);
        uint pattern_len = pattern.strlen();

        for (string param: e.params()) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    uint line_len = line.strlen();
                    if (line_len >= pattern_len)
                        if (line.substr(0, pattern_len) == pattern)
                            e.puts(line);
                }
            } else
                e.perror(param + ": cannot open");
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
