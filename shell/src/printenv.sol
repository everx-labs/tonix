pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract printenv is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        (string[] params, string flags, ) = arg.get_args(argv);
        string delimiter = arg.flag_set("0", flags) ? "\x00" : "\n";

        string s_attrs = "-x";
        if (params.empty()) {
            (string[] lines, ) = stdio.split(argv, "\n");
            for (string line: lines) {
                (string attrs, string stmt) = stdio.strsplit(line, " ");
                if (vars.match_attr_set(s_attrs, attrs)) {
                    (string name, string value) = vars.item_value(stmt);
                    out.append(name + "=" + value + delimiter);
                }
            }
        }
        for (string p: params) {
            string cur_record = vars.get_pool_record(p, argv);
            if (!cur_record.empty()) {
                (string attrs, string stmt) = stdio.strsplit(cur_record, " ");
                if (vars.match_attr_set(s_attrs, attrs)) {
                    (string name, string value) = vars.item_value(stmt);
                    out.append(name + "=" + value + delimiter);
                }
            } else {
                ec = EXECUTE_FAILURE;
                err.append("Environment variable " + p + " not found\n");
            }
        }
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
