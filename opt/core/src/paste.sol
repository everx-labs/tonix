pragma ton-solidity >= 0.62.0;

import "putil.sol";

contract paste is putil {

    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        string line_delimiter = e.flag_set("z") ? "\x00" : "\n";

        for (string param: e.params()) {
            s_of f = e.fopen(param, "r");
            while (!f.feof()) {
                string line = f.fgetln();
                (string[] texts_s, uint n_fields) = line.split("\n");
                for (uint j = 0; j < n_fields; j++)
                    e.puts(texts_s[j] + line_delimiter);
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
"0.02");
    }
}
