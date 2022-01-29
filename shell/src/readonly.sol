pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract readonly is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool functions_only = arg.flag_set("f", flags);
        string s_attrs = "-r";
        if (functions_only)
            s_attrs.append("-f");

        if (params.empty()) {
            (string[] lines, ) = stdio.split(pool, "\n");
            for (string line: lines) {
                (string attrs, ) = str.split(line, " ");
                if (vars.match_attr_set(s_attrs, attrs))
                    out.append(vars.print_reusable(line));
            }
        }
        for (string p: params) {
            (string name, ) = str.split(p, "=");
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = str.split(cur_record, " ");
                if (vars.match_attr_set(s_attrs, cur_attrs))
                    out.append(vars.print_reusable(cur_record));
            } else {
                ec = EXECUTE_FAILURE;
                out.append("readonly: " + name + " not found\n");
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool functions_only = arg.flag_set("f", flags);
        string s_attrs = "-r";
        string page = pool;
        if (functions_only)
            s_attrs.append("-f");
        ec = EXECUTE_SUCCESS;
        for (string p: params)
            page = vars.set_var(s_attrs, p, page);
        res = page;
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
