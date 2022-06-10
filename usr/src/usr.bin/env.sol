pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract env_ is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
//        string delimiter = p.flag_set("0") ? "\x00" : "\n";
        string op;
        string param;
        uint32 val;
        string sval;
        string sout;

        for (string name: p.params()) {
                if (op == "export") {
                    if (param == "syserr") {
                        sout.append("exporting syserr\n");
                        s_of sf = er.export();
                    }
                }

            s_of f = p.fopen(name, "r");
            if (f.file > 0) {
                if (op == "fopen") {
                    p.fopen(name, "r");
                }
            } else {
                if (op.empty()) {
                    op = name;
                    p.puts("op = " + name + "\n");
                } else if (param.empty()) {
                    param = name;
                    p.puts("param = " + name + "\n");
                } else if (sval.empty()) {
                    sval = name;
                    optional (int) ov = stoi(sval);
                    if (ov.hasValue())
                        val = uint32(ov.get());
                }
            }
        }
        p.puts(sout);
    }

    function _export_env(string args, string pool) internal pure returns (string exports) {
        string sattrs = "-x";
        (string[] lines, ) = pool.split("\n");
        for (string line: lines) {
            (string attrs, ) = line.csplit(" ");
            if (vars.match_attr_set(sattrs, attrs))
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
