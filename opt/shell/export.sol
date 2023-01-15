pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";
contract export is pbuiltin {
    using libstring for string;
    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        (bool funcs, bool unexport, bool print, , , , , ) = cc.flag_values("fnp");
        uint8 pg = funcs ? sh.FUNCTION : sh.VARIABLE;
        string[] params = cc.params();
        string[] page = e.environ[pg];
        string[] res;
        if (params.empty())
            e.puts(_print_line(vars.filter(page, "-x", "", false, false)));
        else {
            for (string p: params) {
                if (print) {
                    res = vars.filter(page, "-x", p, true, true);
                    if (res.empty())
                        e.notfound(p);
                    else
                        e.puts(_print_line(res));
                } else
                    page.set_var_attr(unexport ? "+x" : "-x", p);
            }
            if (!print)
                e.environ[pg] = page;
        }
    }
    function _print_line(string[] lines) internal pure returns (string res) {
        for (string line: lines)
            res.append("declare " + line + "\n");
    }
    function _name() internal pure override returns (string) {
        return "export";
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
"[-fn] [name[=value] ...] or export -p",
"Set export attribute for shell variables.",
"Marks each NAME for automatic export to the environment of subsequently executed commands. If VALUE is supplied,\n\
assign VALUE before exporting.",
"-f        refer to shell functions\n\
-n        remove the export property from each NAME\n\
-p        display a list of all exported variables and functions",
"An argument of `--' disables further option processing.",
"Returns success unless an invalid option is given or NAME is invalid.");
    }
}
