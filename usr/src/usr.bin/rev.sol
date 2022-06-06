pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract rev is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        for (string param: p.params()) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    uint line_len = line.strlen();
                    for (uint i = line_len; i > 0; i--)
                        p.putchar(bytes(line)[i - 1]);
                }
            } else
                p.perror("cannot open");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"rev",
"[option] [file...]",
"reverse lines characterwise",
"Copies the specified files to standard output, reversing the order of characters in every line.",
"",
"",
"Written by Boris",
"reading from standard input is not yet implemented",
"tac",
"0.01");
    }
}
