pragma ton-solidity >= 0.61.2;

import "pbuiltin_special.sol";

contract readonly is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc p) internal pure override returns (mapping (uint8 => string) pages) {
        if (p.flag_set("f"))
            pages[9] = e.functions;
        else
            pages[8] = e.vars;
    }

    function _update_shell_env(shell_env e_in, uint8 n, string page) internal pure override returns (shell_env e) {
        e = e_in;
        if (n == 8)
            e.vars = page;
        else if (n == 9)
            e.functions = page;
    }

//    function _print(s_proc p_in, string[] params, string page) internal pure override returns (s_proc p) {
//        p = p_in;
    function _print(s_proc p, s_of f, string[] params, string page) internal pure override returns (s_of res) {
        res = f;
        bool functions_only = p.flag_set("f");
        string sattrs = "-r";
        if (functions_only)
            sattrs.append("-f");

            if (params.empty()) {
                (string[] lines, ) = page.split("\n");
                for (string line: lines) {
                    (string attrs, ) = line.csplit(" ");
                    if (vars.match_attr_set(sattrs, attrs))
                        res.fputs(vars.print_reusable(line));
                }
            }
            for (string param: params) {
                (string name, ) = param.csplit("=");
                string cur_record = vars.get_pool_record(name, page);
                if (!cur_record.empty()) {
                    (string cur_attrs, ) = cur_record.csplit(" ");
                    if (vars.match_attr_set(sattrs, cur_attrs))
                        res.fputs(vars.print_reusable(cur_record));
                } else
                    res.fputs(name + " not found");
            }
    }

    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        bool functions_only = p.flag_set("f");
        string sattrs = "-r";
        page = page_in;
        if (functions_only)
            sattrs.append("-f");
        for (string param: params)
            page = vars.set_var(sattrs, param, page);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"readonly",
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
