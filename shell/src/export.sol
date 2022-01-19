pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract export is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = _get_args(args);
        bool functions_only = _flag_set("f", flags);
        string s_attrs = "-x";
        if (functions_only)
            s_attrs.append("-f");

        if (params.empty()) {
            (string[] lines, ) = _split(pool, "\n");
            for (string line: lines) {
                (string attrs, ) = _strsplit(line, " ");
                if (_match_attr_set(s_attrs, attrs))
                    out.append(_print_reusable(line));
            }
        }
        for (string p: params) {
            (string name, ) = _strsplit(p, "=");
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
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = _get_args(args);
        bool functions_only = _flag_set("f", flags);
        bool unexport = _flag_set("n", flags);

        string page = pool;
        string s_attrs = unexport ? "+x" : "-x";
        if (functions_only)
            s_attrs.append("-f");
        ec = EXECUTE_SUCCESS;
        for (string p: params)
            page = _set_var(s_attrs, p, page);
        res = page;
    }

    function export_env(string args, string pool) external pure returns (uint8 ec, string res) {
        string s_attrs = "-x";
        (string[] lines, ) = _split(pool, "\n");
        for (string line: lines) {
            (string attrs, ) = _strsplit(line, " ");
            if (_match_attr_set(s_attrs, attrs))
                res.append(line + "\n");
        }
        res.append(args);
        ec = EXECUTE_SUCCESS;
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
