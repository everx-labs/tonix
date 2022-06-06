pragma ton-solidity >= 0.60.0;

import "Utility.sol";
//import "..//parg.sol";

contract env_ is Utility {

    using parg for s_proc;
//    function main(string argv, s_proc p_in) external pure returns (s_proc p) {
    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
//        s_ar_misc m = p.p_args.ar_misc;
//        (, string[] params, string fflags, ) = arg.get_env(argv);
        (string[] params, string fflags, string av) = p.get_args();
        string delimiter = arg.flag_set("0", fflags) ? "\x00" : "\n";
        string op;
        string param;
        uint32 val;
        string sval;
        string sout;

        for (string name: params) {
                if (op == "export") {
                    if (param == "syserr") {
                        sout.append("exporting syserr\n");
                        s_of sf = er.export();
                    }
                }

            s_of f = p.fopen(name, "r");
            if (f.file > 0) {
                uint32 pos;
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
