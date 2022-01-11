pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract printenv is Utility {

    function exec(string[] e) external pure returns (uint8 ec, string out, string err) {
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        string delimiter = _flag_set("0", flags) ? "\x00" : "\n";

        string s_attrs = "-x";
        string pool = e[IS_POOL];

        if (params.empty()) {
            (string[] lines, ) = _split(pool, "\n");
            for (string line: lines) {
                (string attrs, string stmt) = _strsplit(line, " ");
                if (_match_attr_set(s_attrs, attrs)) {
                    (string name, string value) = _item_value(stmt);
                    out.append(name + "=" + value + delimiter);
                }
            }
        }
        for (string p: params) {
            string cur_record = _get_pool_record(p, pool);
            if (!cur_record.empty()) {
                (string attrs, string stmt) = _strsplit(cur_record, " ");
                if (_match_attr_set(s_attrs, attrs)) {
                    (string name, string value) = _item_value(stmt);
                    out.append(name + "=" + value + delimiter);
                }
            } else {
                ec = EXECUTE_FAILURE;
                err.append("Environment variable " + p + " not found\n");
            }
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
"printenv",
"print all or part of environment",
"[OPTION]... [VARIABLE]...",
"Print the values of the specified environment VARIABLE(s).  If no VARIABLE is specified, print name and value pairs for them all.",
"0", 1, M, [
"end each output line with NUL, not newline"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"printenv",
"[OPTION]... [VARIABLE]...",
"print all or part of environment",
"Print the values of the specified environment VARIABLE(s).  If no VARIABLE is specified, print name and value pairs for them all.",
"-0      end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
