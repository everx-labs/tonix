pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract export is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool functions_only = arg.flag_set("f", flags);
        string sattrs = "-x";
        if (functions_only)
            sattrs.append("-f");

        if (params.empty()) {
            (string[] lines, ) = pool.split("\n");
            for (string line: lines) {
                (string attrs, ) = line.csplit(" ");
                if (vars.match_attr_set(sattrs, attrs))
                    out.append(vars.print_reusable(line));
            }
        }
        for (string p: params) {
            (string name, ) = p.csplit("=");
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.csplit(" ");
                if (vars.match_attr_set(sattrs, cur_attrs))
                    out.append(vars.print_reusable(cur_record));
            } else {
                ec = EXECUTE_FAILURE;
                out.append("export: " + name + " not found\n");
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool functions_only = arg.flag_set("f", flags);
        bool unexport = arg.flag_set("n", flags);

        string page = pool;
        string sattrs = unexport ? "+x" : "-x";
        if (functions_only)
            sattrs.append("-f");
        ec = EXECUTE_SUCCESS;
        for (string p: params)
            page = vars.set_var(sattrs, p, page);
        res = page;
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
