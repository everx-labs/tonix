pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract hash is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool print_tabbed = arg.flag_set("t", flags);
        bool print_reusable = arg.flag_set("l", flags);
        bool no_args = params.empty();
        if (no_args) {
            if (pool.empty())
                out.append("hash: hash table empty\n");
            else {
                if (!print_reusable)
                    out.append("hits\tcommand\n");
                (string[] lines, ) = stdio.split(pool, "\n");
                for (string line: lines) {
                    (, string path, string contents) = vars.split_var_record(line);
                    (string[] bins, ) = stdio.split(stdio.trim_spaces(contents), " ");
                    for (string bin: bins) {
                        (string name, string value) = vars.item_value(bin);
                        out.append(print_reusable ?
                            "builtin hash -p " + path + "/" + name + " " + name + "\n" :
                            fmt.pad(value, 4, fmt.ALIGN_RIGHT) + "\t" + path + "/" + name + "\n");
                    }
                }
            }
        }
        for (string arg: params) {
            string path = vars.get_array_name(arg, pool);
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

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool forget_some = arg.flag_set("d", flags);
        bool forget_all = arg.flag_set("r", flags);
        string page = pool;
        if (forget_all)
            page = "";
        else if (forget_some) {
            for (string arg: params) {
                string path = vars.get_array_name(arg, pool);
                if (!path.empty())
                    page = stdio.translate(page, arg + " ", "");
                else {
                    ec = EXECUTE_FAILURE;
//                        out.append("-tosh: hash: " + arg + ": not found\n");
                }
            }
        }
        res = page;
    }

    function lookup(string args, string page, string pool) external pure returns (uint8 ec, string out, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
        string hashes = page;
        string commands = vars.get_map_value("command", pool);
        string bins = vars.get_map_value("/bin", hashes);
        string init_bins = bins;
        bool print_tabbed = arg.flag_set("t", flags);

        for (string arg: params) {
            string path_map = vars.get_pool_record(arg, page);
            if (path_map.empty()) {
                if (print_tabbed) {
                    ec = EXECUTE_FAILURE;
                    out.append("hash: " + arg + ": not found\n");
                } else {
                    if (stdio.strstr(commands, arg) > 0)
                        bins = vars.set_item_value(arg, "0", bins);
                    else
                        ec = EXECUTE_FAILURE;
                }
            } else {
                if (print_tabbed) {
                    (, string bin_path, ) = vars.split_var_record(path_map);
                    out.append(bin_path + "/" + arg);
                    string s_hit_count = vars.val(arg, path_map);
                    uint16 hc = stdio.atoi(s_hit_count);
                    string upd = vars.set_item_value(arg, stdio.itoa(hc + 1), path_map);
                    hashes = stdio.translate(hashes, path_map, upd);
                } else {
                    string upd = vars.set_item_value(arg, "0", path_map);
                    hashes = stdio.translate(hashes, path_map, upd);
                }
            }
        }
        hashes = stdio.translate(hashes, init_bins, bins);
        res = hashes;
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
