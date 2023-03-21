pragma ton-solidity >= 0.67.0;

import "putil.sol";

contract expand is putil {
    using libstring for string;
    function _main(shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = e.params();
        (bool use_tab_size, bool convert_initial_tabs, , ) = e.flags_set("ti");
        uint16 tab_size = use_tab_size ? str.toi(e.opt_value("t")) : 8;
//        bool convert_initial_tabs = p.flag_set("i");
        string tab_spaces = fmt.spaces(tab_size);
        string out;
        for (string param: params) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    if (convert_initial_tabs) {
                        uint q = 0;
                        while (line.substr(q, 1) == "\t")
                            q++;
                        if (q > 0) {
                            for (uint i = 0; i < q; i++)
                                out.append(tab_spaces);
                            out.append(line.substr(q));
                        } else
                            out.append(line);
                    } else
                        out.append(line.translate("\t", tab_spaces));
                }
            } else
//                p.perror("cannot open");
                e.perror(param);
        }
        res.fputs(out);
        e.ofiles[libfdt.STDOUT_FILENO] = res;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"expand",
"[OPTION]... [FILE]...",
"convert tabs to spaces",
"Convert tabs in each FILE to spaces, writing to standard output.",
"-i     do not convert tabs after non blanks\n\
-t      have tabs N characters apart, not 8",
"",
"Written by Boris",
"",
"unexpand",
"0.01");
    }

}
