pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract export is pbuiltin_special {

    function _retrieve_pages(shell_env e) internal pure override returns (uint8[]) {
        return [e.flag_set("f") ? sh.FUNCTION : sh.VARIABLE];
    }
    function _attr_set(shell_env e) internal pure override returns (string sattrs) {
        sattrs = e.flag_set("n") ? "+x" : "-x";
        if (e.flag_set("f"))
            sattrs.append("f");
    }
    function _print_record(string record) internal pure override returns (string) {
        return vars.print_reusable(record);
    }
    function _name() internal pure override returns (string) {
        return "export";
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
