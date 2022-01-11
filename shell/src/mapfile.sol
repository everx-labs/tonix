pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract mapfile is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        ec = 0;
        string arg = e[IS_ARGS];
        string dbg;
        (string[] params, string flags, ) = _get_args(arg);

        string delimiter = _flag_set("d", flags) ? _opt_arg_value("d", arg) : "\n";
        uint count = _flag_set("n", flags) ? _atoi(_opt_arg_value("n", arg)) : 0;
        uint origin = _flag_set("O", flags) ? _atoi(_opt_arg_value("O", arg)) : 0;
        string array_name = params.empty() ? "MAPFILE" : params[params.length - 1];
        string ofs = _flag_set("t", flags) ? " " : (delimiter + " ");
        string ofs_2 = _flag_set("t", flags) ? "" : delimiter;
        uint16 page_index = IS_STDIN;
        if (_flag_set("u", flags)) {
            string s_fd = _opt_arg_value("u", arg);
            uint16 fd = _atoi(s_fd);
            if (fd > 0)
                page_index = fd;
            else
                dbg.append(format("Invalid fd specified: {}, using stdin\n", s_fd));
        }

        dbg.append(format("delim {} arr_name {} page_index {}\n", delimiter, array_name, page_index));
        string page = e[page_index];
        dbg.append(page);
        (string[] fields, uint n_lines) = _split(page, "\n");
        string[][2] entries;
        uint cap = count > 0 ? math.min(count, n_lines) : n_lines;
        for (uint i = origin; i < origin + cap; i++) {
            entries.push([format("{}", i), fields[i] + ofs_2]);
            out.append(format("[{}]={}{}", i, fields[i], ofs));
        }
        out = _wrap(array_name, W_SQUARE) + "=" + _as_map(out);
        out.append("======\n");
        out.append(_wrap(array_name, W_SQUARE) + "=" + _encode_items(entries));
//        dbg.append(format("{}=( {} )\n", array_name, _join_fields(fields, ";")));

        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
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
