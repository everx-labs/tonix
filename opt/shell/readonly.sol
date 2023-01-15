pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract readonly is pbuiltin {
//    using libstring for string;
    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        uint8 pg = cc.flag_set("f") ? sh.FUNCTION : sh.VARIABLE;
        string[] params = cc.params();
        bool no_params = params.empty();
        bool print = cc.flag_set("p") || no_params;
        string[] page = e.environ[pg];
        string[] res;
        if (no_params) {
            res = vars.filter(page, "-r", "", false, false);
            e.puts(_print_line(res));
        } else {
            for (string p: params) {
                if (print) {
                    res = vars.filter(page, "-r", p, true, true);
                    if (res.empty()) {
                        e.notfound(p);
                        rc = EXIT_FAILURE;
                    } else
                        e.puts(_print_line(res));
                } else
                    page.set_var_attr("-r", p);
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
        return "readonly";
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
"[-aAf] [name[=value] ...] or readonly -p",
"Mark shell variables as unchangeable.",
"Mark each NAME as read-only; the values of these NAMEs may not be changed by subsequent assignment.\n\
If VALUE is supplied, assign VALUE before marking as read-only.",
"-a        refer to indexed array variables\n\
-A        refer to associative array variables\n\
-f        refer to shell functions\n\
-p        display a list of all readonly variables or functions, depending on whether or not the -f option is given",
"An argument of `--' disables further option processing.",
"Returns success unless an invalid option is given or NAME is invalid.");
    }
}
