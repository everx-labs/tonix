pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract hash is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);

        bool print_tabbed = _flag_set("t", flags);
        bool print_reusable = _flag_set("l", flags);
//        bool no_args = flags.empty() && args.empty();
        bool no_args = args.empty();
        bool print = print_tabbed || print_reusable || no_args;
//        bool use_pathname = _get_option_value(short_options, "p");
        bool forget_some = _flag_set("d", flags);
        bool forget_all = _flag_set("r", flags);
        bool drop = forget_some || forget_all;
        bool add = !print && !drop;

        uint16 page_index = IS_BINPATH;
        string page = e[page_index];
        string hashes = page;
        string commands = _get_map_value("command", e[IS_INDEX]);

        if (print) {
            if (no_args) {
                if (hashes.empty())
                    out.append("hash: hash table empty\n");
                else {
                    out.append("hits\tcommand\n");
                    (string[] dir_arrays, ) = _split(hashes, "\n");
                    for (string dir: dir_arrays) {
                        (string path, string contents) = _item_value(dir);
                        (string[] bins, ) = _split(_trim_spaces(contents), " ");
                        for (string bin: bins)
                            out.append(print_reusable ?
                                "builtin hash -p " + path + "/" + bin + " " + bin + "\n" :
                                "1\t" + path + "/" + bin + "\n");
                    }
                }
            }
            for (string arg: args) {
                string path = _get_array_name(arg, hashes);
                if (!path.empty()) {
                    out.append(print_tabbed ?
                        arg + "\t" + path + "/" + arg + "\n" :
                        "builtin hash -p " + path + "/" + arg + " " + arg + "\n");
                } else {
                    ec = EXECUTE_FAILURE;
                    if (print_tabbed)
                        out.append("-tosh: hash: " + arg + ": not found\n");
                }
            }
        } else if (add) {
            for (string arg: args) {
                string bins = _get_map_value("/bin", hashes);
                if (_strstr(commands, arg) > 0)
                    bins = _set_add(arg, bins);
                else {
                    ec = EXECUTE_FAILURE;
                    out.append("-tosh: hash: " + arg + ": not found\n");
                }
                e[page_index] = _translate(hashes, _get_map_value("/bin", hashes), bins);
            }
        } else if (drop) {
            if (forget_all)
                delete e[page_index];
            else {
                for (string arg: args) {
                    string path = _get_array_name(arg, hashes);
                    if (!path.empty())
                        hashes = _translate(hashes, arg + " ", "");
                    else {
                        ec = EXECUTE_FAILURE;
                        out.append("-tosh: hash: " + arg + ": not found\n");
                    }
                }
                e[page_index] = hashes;
            }
        }
        if (page != e[page_index])
            wr.push(Write(page_index, e[page_index], O_WRONLY));
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"hash",
"[-lr] [-p pathname] [-dt] [name ...]",
"Remember or display program locations.",
"Determine and remember the full pathname of each command NAME.  If no arguments are given, information about remembered commands is displayed.",
"-d        forget the remembered location of each NAME\n\
-l        display in a format that may be reused as input\n\
-p pathname       use PATHNAME as the full pathname of NAME\n\
-r        forget all remembered locations\n\
-t        print the remembered location of each NAME, preceding each location with the corresponding NAME if multiple NAMEs are given",
"NAME      Each NAME is searched for in $PATH and added to the list of remembered commands.",
"Returns success unless NAME is not found or an invalid option is given.");
    }
}
