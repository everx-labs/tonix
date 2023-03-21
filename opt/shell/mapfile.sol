pragma ton-solidity >= 0.67.0;

import "pbuiltin.sol";

contract mapfile is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] pool = e.environ[sh.ARRAYVAR];

        string sattrs = "-a";
        string delimiter = cc.flag_set("d") ? e.opt_value("d") : "\n";
//        uint count = e.flag_set("n") ? str.toi(e.opt_value("n")) : 0;
//        uint origin = e.flag_set("O") ? str.toi(e.opt_value("O")) : 0;
        uint count = e.opt_value_int("n");
        uint origin = e.opt_value_int("O");//e.flag_set("O") ? str.toi(e.opt_value("O")) : 0;
        string[] params = cc.params();
        string array_name = params.empty() ? "MAPFILE" : params[params.length - 1];
//        string ofs = p.flag_set("t") ? " " : (delimiter + " ");
//        string ofs_2 = p.flag_set("t") ? "" : delimiter;
        uint16 page_index;
        if (e.flag_set("u")) {
            string sfd = e.opt_value("u");
            uint16 fd = str.toi(sfd);
            if (fd > 0)
                page_index = fd;
            else {
                e.perror("Invalid fd specified: " + sfd + ", using stdin");
            }
        }

        string input;
        s_of f = e.stdin();//p.fdopen(0, "r");
        if (!f.ferror()) {
//            input = f.gets_s(0);
//            string arr_val = vars.as_indexed_array(array_name, input, "\n");
//            e.environ[sh.ARRAYVAR].set_var(sattrs, arr_val);
        } else
            rc = EXIT_FAILURE;
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
    function _name() internal pure override returns (string) {
        return "mapfile";
    }
}
