pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract paste is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string line_delimiter = p.flag_set("z") ? "\x00" : "\n";

        for (string param: p.params()) {
            s_of f = p.fopen(param, "r");
            while (!f.feof()) {
                string line = f.fgetln();
                (string[] texts_s, uint n_fields) = line.split("\n");
                for (uint j = 0; j < n_fields; j++)
                    p.puts(texts_s[j] + line_delimiter);
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"paste",
"[OPTION]... [FILE]...",
"merge lines of files",
"Write lines consisting of the sequentially corresponding lines from each FILE, separated by TABs, to standard output.",
"-s      paste one file at a time instead of in parallel\n\
-z      line delimiter is NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
