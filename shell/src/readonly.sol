pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract readonly is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        bool functions_only = _flag_set("f", flags);
        string dbg;
        string s_attrs = "-r";
        if (functions_only)
            s_attrs.append("-f");
        bool print_reusable = _flag_set("p", flags);
        string pool = e[IS_POOL];

        if (params.empty()) {
            (string[] lines, ) = _split(pool, "\n");
            for (string line: lines) {
                (string attrs, ) = _strsplit(line, " ");
                if (_match_attr_set(s_attrs, attrs))
                    out.append(_print_reusable(line));
//                    out.append("declare " + line + "\n");
            }
        }
        for (string p: params) {
            (string name, string value) = _strsplit(p, "=");
            string cur_record = _get_pool_record(name, pool);
            string new_record = _pool_str(s_attrs, name, value);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = _strsplit(cur_record, " ");
                if (print_reusable && _match_attr_set(s_attrs, cur_attrs))
                    out.append(_print_reusable(cur_record));
                else {
                    (, string cur_value) = _strsplit(cur_record, "=");
                    string new_value = !value.empty() ? value : !cur_value.empty() ? _unwrap(cur_value) : "";
                    new_record = _pool_str(_meld_attr_set(s_attrs, cur_attrs), name, new_value);
                    pool = _translate(pool, cur_record, new_record);
                }
            } else {
                if (print_reusable) {
                    ec = EXECUTE_FAILURE;
                    out.append("readonly: " + name + " not found\n");
                } else
                    pool.append(new_record);
            }
        }
        if (pool != e[IS_POOL])
            wr.push(Write(IS_POOL, pool, O_WRONLY));
        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
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
