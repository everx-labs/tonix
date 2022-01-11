pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract export is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        bool functions_only = _flag_set("f", flags);
        bool unexport = _flag_set("n", flags);

        string s_attrs = unexport ? "+x" : "-x";
        if (functions_only)
            s_attrs.append("-f");
        bool print_reusable = _flag_set("p", flags);
        string dbg;

        string pool = e[IS_POOL];

        if (params.empty()) {
            (string[] lines, ) = _split(pool, "\n");
            for (string line: lines) {
                (string attrs, ) = _strsplit(line, " ");
                if (_match_attr_set(s_attrs, attrs))
                    out.append(_print_reusable(line));
            }
        }
        if (print_reusable) {
            for (string p: params) {
                (string name, string value) = _strsplit(p, "=");
                string cur_record = _get_pool_record(name, pool);
                if (!cur_record.empty()) {
                    (string cur_attrs, ) = _strsplit(cur_record, " ");
                    if (_match_attr_set(s_attrs, cur_attrs))
                        out.append(_print_reusable(cur_record));
                } else {
                    ec = EXECUTE_FAILURE;
                    out.append("export: " + name + " not found\n");
                }
            }
        } else
            for (string p: params)
                pool = _set_var(s_attrs, p, pool);

        if (pool != e[IS_POOL])
            wr.push(Write(IS_POOL, pool, O_WRONLY));

        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"export",
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
