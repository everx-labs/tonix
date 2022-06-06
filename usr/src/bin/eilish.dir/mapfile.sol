pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract mapfile is Shell {

    function read_input(string args, string input, string pool) external pure returns (uint8 ec, string out, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        ec = EXECUTE_SUCCESS;
        string dbg;

        string sattrs = "-a";
        string delimiter = arg.flag_set("d", flags) ? arg.opt_arg_value("d", args) : "\n";
//        uint count = arg.flag_set("n", flags) ? str.toi(arg.opt_arg_value("n", args)) : 0;
//        uint origin = arg.flag_set("O", flags) ? str.toi(arg.opt_arg_value("O", args)) : 0;
        string array_name = params.empty() ? "MAPFILE" : params[params.length - 1];
//        string ofs = arg.flag_set("t", flags) ? " " : (delimiter + " ");
//        string ofs_2 = arg.flag_set("t", flags) ? "" : delimiter;
        uint16 page_index;
        if (arg.flag_set("u", flags)) {
            string sfd = arg.opt_arg_value("u", args);
            uint16 fd = str.toi(sfd);
            if (fd > 0)
                page_index = fd;
            else
                dbg.append(format("Invalid fd specified: {}, using stdin\n", sfd));
        }

        dbg.append(format("delim {} arr_name {} page_index {}\n", delimiter, array_name, page_index));
        string arr_val = vars.as_indexed_array(array_name, input, "\n");
        out = dbg;
        res = vars.set_var(sattrs, arr_val, pool);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"mapfile",
"[-d delim] [-n count] [-O origin] [-s count] [-t] [-u fd] [-C callback] [-c quantum] [array]",
"Read lines from the standard input into an indexed array variable.",
"Read lines from the standard input into the indexed array variable ARRAY, or from file descriptor FD if the -u option is supplied. The variable MAPFILE is the default ARRAY.",
"-d delim  Use DELIM to terminate lines, instead of newline\n\
-n count  Copy at most COUNT lines.  If COUNT is 0, all lines are copied\n\
-O origin Begin assigning to ARRAY at index ORIGIN.  The default index is 0\n\
-s count  Discard the first COUNT lines read\n\
-t        Remove a trailing DELIM from each line read (default newline)\n\
-u fd     Read lines from file descriptor FD instead of the standard input\n\
-C callback       Evaluate CALLBACK each time QUANTUM lines are read\n\
-c quantum        Specify the number of lines read between each call to CALLBACK",
"Arguments:\n\
  ARRAY     Array variable name to use for file data\n\n\
If -C is supplied without -c, the default quantum is 5000.  When CALLBACK is evaluated, it is supplied the index\n\
of the next array element to be assigned and the line to be assigned to that element as additional arguments.\n\n\
If not supplied with an explicit origin, mapfile will clear ARRAY before assigning to it.",
"Returns success unless an invalid option is given or ARRAY is readonly or not an indexed array.");
    }
}
