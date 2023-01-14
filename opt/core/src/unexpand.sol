pragma ton-solidity >= 0.62.0;

import "putil.sol";

contract unexpand is putil {

    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        bool use_tab_size = e.flag_set("t");
        uint16 tab_size = use_tab_size ? e.opt_value_int("t") : 8;
        bool convert_all_blanks = e.flag_set("a");
        string tab_spaces = fmt.spaces(tab_size);
        for (string param: params) {
            s_of f = e.fopen(param, "r");
            if (!f.ferror()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    if (convert_all_blanks)
                        e.puts(libstring.translate(line, tab_spaces, "\t"));
                    else {
                        uint q = 0;
                        while (line.substr(q, 1) == " ")
                            q++;
                        if (q > 0) {
                            (uint n_tabs, uint n_spaces) = math.divmod(q, tab_size);
                            string out;
                            for (uint i = 0; i < n_tabs; i++)
                                out.append("\t");
                            for (uint i = 0; i < n_spaces; i++)
                                out.append(" ");
                            e.puts(out + line.substr(q));
                        } else
                            e.puts(line);
                    }
                }
            } else
                e.perror(param + ": cannot open");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"unexpand",
"[OPTION]... [FILE]...",
"convert spaces to tabs",
"Convert blanks in each FILE to tabs, writing to standard output.",
"-a      convert all blanks, instead of just initial blanks\n\
-t      have tabs N characters apart instead of 8 (enables -a)",
"",
"Written by Boris",
"",
"expand",
"0.01");
    }

}
