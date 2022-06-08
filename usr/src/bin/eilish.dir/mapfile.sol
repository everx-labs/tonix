pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract mapfile is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();
        sv.cur_proc = p;
        string pool = vmem.vmem_fetch_page(sv.vmem[1], 3);

        string sattrs = "-a";
        string delimiter = p.flag_set("d") ? p.opt_value("d") : "\n";
        uint count = p.flag_set("n") ? str.toi(p.opt_value("n")) : 0;
        uint origin = p.flag_set("O") ? str.toi(p.opt_value("O")) : 0;
        string array_name = params.empty() ? "MAPFILE" : params[params.length - 1];
//        string ofs = p.flag_set("t") ? " " : (delimiter + " ");
//        string ofs_2 = p.flag_set("t") ? "" : delimiter;
        uint16 page_index;
        if (p.flag_set("u")) {
            string sfd = p.opt_value("u");
            uint16 fd = str.toi(sfd);
            if (fd > 0)
                page_index = fd;
            else
                p.perror("Invalid fd specified: " + sfd + ", using stdin");
        }

        string input;
        s_of f = p.fdopen(0, "r");
        if (!f.ferror())
            input = f.gets_s(0);

        string arr_val = vars.as_indexed_array(array_name, input, "\n");
        sv.vmem[1].vm_pages[3] = vars.set_var(sattrs, arr_val, pool);
        sv.cur_proc = p;
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
