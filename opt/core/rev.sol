pragma ton-solidity >= 0.67.0;

import "putil.sol";
contract rev is putil {
    function _main(shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        s_of res = e.stdout();
        for (string param: e.params()) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    uint line_len = str.strlen(line);
                    for (uint i = line_len; i > 0; i--)
                        res.fputc(bytes(line)[i - 1]);
                }
            } else
                e.perror(param);
        }
        e.ofiles[libfdt.STDOUT_FILENO] = res;
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
"0.02");
    }
}
