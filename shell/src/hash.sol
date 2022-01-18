pragma ton-solidity >= 0.54.0;

import "Shell.sol";

contract hash is Shell {

//    function print(string args, string hashes, string index, string pool) external pure returns (uint8 ec, string out) {
    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = _get_args(args);
        bool print_tabbed = _flag_set("t", flags);
        bool print_reusable = _flag_set("l", flags);
        bool no_args = params.empty();
        if (no_args) {
            if (pool.empty())
                out.append("hash: hash table empty\n");
            else {
                out.append("hits\tcommand\n");
                (string[] lines, ) = _split(pool, "\n");
                for (string line: lines) {
                    (, string path, string contents) = _split_var_record(line);
                    (string[] bins, ) = _split(_trim_spaces(contents), " ");
                    for (string bin: bins)
                        out.append(print_reusable ?
                        "builtin hash -p " + path + "/" + bin + " " + bin + "\n" :
                        "1\t" + path + "/" + bin + "\n");
                }
            }
        }
        for (string arg: params) {
            string path = _get_array_name(arg, pool);
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
    }

//    function modify(string args, string hashes, string index) external pure returns (uint8 ec, string res) {
    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = _get_args(args);
        bool forget_some = _flag_set("d", flags);
        bool forget_all = _flag_set("r", flags);
        bool drop = forget_some || forget_all;
        bool add = !drop;
//        string commands = _get_map_value("command", index);
        string page = pool;
        if (add) {
            for (string arg: params) {
                string bins = _get_map_value("/bin", pool);
                bins = _set_add(arg, bins);
                /*if (_strstr(commands, arg) > 0)
                    bins = _set_add(arg, bins);
                else {
                    ec = EXECUTE_FAILURE;
//                    out.append("-tosh: hash: " + arg + ": not found\n");
                }*/
                page = _translate(page, _get_map_value("/bin", pool), bins);
            }
        } else if (drop) {
            if (forget_all)
                page = "";
            else {
                for (string arg: params) {
                    string path = _get_array_name(arg, pool);
                    if (!path.empty())
                        page = _translate(page, arg + " ", "");
                    else {
                        ec = EXECUTE_FAILURE;
//                        out.append("-tosh: hash: " + arg + ": not found\n");
                    }
                }
            }
        }
        res = page;
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
