pragma ton-solidity >= 0.63.0;

import "pbuiltin.sol";

contract alias_ is pbuiltin {
    using libstring for string;
    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        uint8 pg = sh.ALIAS;
        string[] params = cc.params();
        string[] page = e.environ[pg];
        string[] res;
        bool print = cc.flag_set("p");
        if (params.empty())
            e.puts(_print_line(vars.filter(page, "", "", false, false)));
        else {
            for (string p: params) {
                if (print) {
                    res = vars.filter(page, "", p, true, true);
                    if (res.empty()) {
                        rc = EXIT_FAILURE;
                        e.notfound(p);
                    } else
                        e.puts(_print_line(res));
                } else
                    page.set_var("", p);
            }
            if (!print)
                e.environ[pg] = page;
        }
    }
    function _print_line(string[] lines) internal pure returns (string res) {
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            res.append("alias " + name + "=\'" + value + "\'\n");
        }
    }

    function _name() internal pure override returns (string) {
        return "alias";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"alias",
"[-p] [name[=value] ... ]",
"Define or display aliases.",
"Without arguments, `alias' prints the list of aliases in the reusable form `alias NAME=VALUE' on standard output.\n\
Otherwise, an alias is defined for each NAME whose VALUE is given. A trailing space in VALUE causes the next word\n\
to be checked for alias substitution when the alias is expanded.",
"-p        print all defined aliases in a reusable format",
"",
"alias returns true unless a NAME is supplied for which no alias has been defined.");
    }
}
