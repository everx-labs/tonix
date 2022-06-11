pragma ton-solidity >= 0.61.0;

import "putil.sol";

contract tr is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        (, bool squeeze_repeats, , ) = p.flags_set("ds");
        string set_from = params.empty() ? params[0] : "";
        string set_to = p.opt_value("d");
        for (string param: params) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    if (squeeze_repeats)
                        line.tr_squeeze(set_from);
                    else
                        line.translate(set_from, set_to);
                    p.puts(line);
                }
            } else
                p.perror(param + ": cannot open");
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
