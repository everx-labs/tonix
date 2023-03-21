pragma ton-solidity >= 0.67.0;

import "putil.sol";

contract tr is putil {
    using libstring for string;
    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        (, bool squeeze_repeats, , ) = e.flags_set("ds");
        string set_from = params.empty() ? params[0] : "";
        string set_to = e.opt_value("d");
        for (string param: params) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    if (squeeze_repeats)
                        line.tr_squeeze(set_from);
                    else
                        line.translate(set_from, set_to);
                    e.puts(line);
                }
            } else
                e.perror(param + ": cannot open");
        }
    }
    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tr",
"[OPTION]... SET1 [SET2]",
"translate or delete characters",
"Translate, squeeze, and/or delete characters from standard input, writing to standard output.",
"-d      delete characters in SET1, do not translate\n\
-s      replace each sequence of a repeated character that is listed in the last specified SET, with a single occurrence of that character",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
