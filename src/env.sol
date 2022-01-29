pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract env is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        (string[] params, string flags, ) = arg.get_args(argv);
        string delimiter = arg.flag_set("0", flags) ? "\x00" : "\n";

        string s_attrs = "-x";
        if (params.empty()) {
            (string[] lines, ) = stdio.split(argv, "\n");
            for (string line: lines) {
                (string attrs, string stmt) = str.split(line, " ");
                if (vars.match_attr_set(s_attrs, attrs)) {
                    (string name, string value) = vars.item_value(stmt);
                    out.append(name + "=" + value + delimiter);
                }
            }
        } else {
            string cmd = vars.val("COMMAND", argv);
            string s_args = vars.val("@", argv);
            string exec_line = "./command " + cmd + " " + s_args;
            out = exec_line;
            ec = EXECUTE_SUCCESS;
            err = "";
        }
    }

    function _export_env(string args, string pool) internal pure returns (string exports) {
        string s_attrs = "-x";
        (string[] lines, ) = stdio.split(pool, "\n");
        for (string line: lines) {
            (string attrs, ) = str.split(line, " ");
            if (vars.match_attr_set(s_attrs, attrs))
                exports.append(line + "\n");
        }
        exports.append(args);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"env",
"[OPTION]... [COMMAND [ARG]...]",
"run a program in a modified environment",
"Run COMMAND in the environment.",
"-i      start with an empty environment\n\
-0      end each output line with NUL, not newline\n\
-u      remove variable from the environment\n\
-C      change working directory to DIR\n\
-S      process and split S into separate arguments; used to pass multiple arguments on shebang lines\n\
-v      print verbose information for each processing step",
"A mere - implies -i.  If no COMMAND, print the resulting environment.",
"Written by Boris",
"",
"",
"0.01");
    }

}
