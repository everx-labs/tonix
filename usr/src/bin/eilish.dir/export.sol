pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract export is pbuiltin_special {

    function _retrieve_pages(s_proc p) internal pure override returns (uint8[]) {
        return [p.flag_set("f") ? sh.FUNCTION : sh.VARIABLE];
    }

    function _print(s_proc p, s_of f, string[] page) internal pure override returns (s_of res) {
        res = f;
        bool functions_only = p.flag_set("f");
        string sattrs = "-x";
        if (functions_only)
            sattrs.append("-f");
            if (p.params().empty()) {
                for (string line: page) {
                    (string attrs, ) = line.csplit(" ");
                    if (vars.match_attr_set(sattrs, attrs))
                        res.fputs(vars.print_reusable(line));
                }
            }
            for (string param: p.params()) {
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
    function _modify(s_proc p, string[] page_in) internal pure override returns (string[] page) {
        bool functions_only = p.flag_set("f");
        bool unexport = p.flag_set("n");

        string sattrs = unexport ? "+x" : "-x";
        page = page_in;
        if (functions_only)
            sattrs.append("-f");
        for (string param: p.params())
            page = vars.set_var(sattrs, param, page);
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
