pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "vars.sol";
import "libcompspec.sol";

contract hash is pbuiltin_base {

    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = e_in;
        string[] comp_spec_page = e.environ[sh.PATHHASH];
        if (comp_spec_page.empty())
            return (sv, e);
        string[] params = p.params();
        bool no_flags = p.flags_empty();
        bool no_args = params.empty();
        (bool print_tabbed, bool print_reusable, bool forget_some, bool forget_all, bool use_pathname, , , ) = p.flag_values("tldrp");
        bool do_print = (no_flags && no_args) || print_tabbed || print_reusable;
        bool do_modify = forget_some || forget_all;
        bool print_names = use_pathname || (no_flags && !no_args);
        /*string path_val = p.opt_value("p");
        uint i = 0;
        for (string line: comp_spec_page) {
            i++;
            (, string path, string contents) = vars.split_var_record(line);
            if (use_pathname && str.strstr(path, path_val) == 0)
                continue;
            for (string a: args) {
                string item = vars.get_pool_record(a, comp_spec_page);
                if (!item.empty())
                    pages[uint8(i)].push(item);
            }
            if (no_args)
                pages[uint8(i)] = [line];
        }*/

        if (do_print) {
            string[] page_in = comp_spec_page;
            s_of res = e.ofiles[libfdt.STDOUT_FILENO];
            if (!print_reusable)
                res.fputs("hits\tcommand");
            if (print_names) {
                for (string param: params) {
                    string path = vars.get_array_name(param, page_in);
//                    string item = vars.get_pool_record(param, page_in);
                    if (!path.empty())
                        res.fputs(_display_item(path, param, print_reusable, print_tabbed));
                }
            }
            e.ofiles[libfdt.STDOUT_FILENO] = res;
        }

        if (do_modify) {
            if (forget_all)
                delete e.environ[sh.PATHHASH];
            else if (forget_some) {
                for (string arg: params) {
                    uint index = vars.get_pool_index(arg, e.environ[sh.PATHHASH]);
                    if (index > 0)
                        delete e.environ[sh.PATHHASH][index - 1];
                }
            }
        }
    }

    function _display_item(string path, string item, bool print_reusable, bool print_tabbed) internal pure returns (string) {
        (string name, string value) = vars.item_value_old(item);
        return print_reusable ? "builtin hash -p " + path + "/" + name + " " + name :
               print_tabbed ? name + "\t" + path + "/" + name :
               fmt.pad(value, 4, fmt.RIGHT) + "\t" + path + "/" + name;
    }
    /*function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;

        string[] params = p.params();

        bool print_tabbed = p.flag_set("t");
        bool print_reusable = p.flag_set("l");
        bool no_args = params.empty();
        string pool = vmem.vmem_fetch_page(sv.vmem[1], 4);

        if (no_args) {
            if (pool.empty())
                p.perror("hash table empty");
            else {
                if (!print_reusable)
                    p.puts("hits\tcommand");
                (string[] lines, ) = pool.split("\n");
                for (string line: lines) {
                    (, string path, string contents) = vars.split_var_record(line);
                    contents.trim_spaces();
                    (string[] bins, ) = contents.split(" ");
                    for (string bin: bins) {
                        (string name, string value) = vars.item_value(bin);
                        p.puts(print_reusable ?
                            "builtin hash -p " + path + "/" + name + " " + name :
                            fmt.pad(value, 4, fmt.RIGHT) + "\t" + path + "/" + name);
                    }
                }
            }
        }
        for (string arg: params) {
            string path = vars.get_array_name(arg, pool);
            if (!path.empty()) {
                p.puts(print_tabbed ?
                    arg + "\t" + path + "/" + arg :
                    "builtin hash -p " + path + "/" + arg + " " + arg);
            } else {
                if (print_tabbed)
                    p.puts("-tosh: hash: " + arg + ": not found");
            }
        }
        sv.cur_proc = p;
    }*/


    /*function modify(string args, string pool) external pure returns (uint8 ec, string res) {
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
                    page.translate(arg + " ", "");
            }
        }
        res = page;
    }*/

    /*function lookup(string args, string page, string pool) external pure returns (uint8 ec, string out, string res) {
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
                    if (commands.strstr(arg) > 0)
                        bins = vars.set_item_value(arg, "0", bins);
                    else
                        ec = EXECUTE_FAILURE;
                }
            } else {
                if (print_tabbed) {
                    (, string bin_path, ) = vars.split_var_record(path_map);
                    out.append(bin_path + "/" + arg);
                    string shit_count = vars.val(arg, path_map);
                    uint16 hc = shit_count.toi();
                    string upd = vars.set_item_value(arg, str.toa(hc + 1), path_map);
                    hashes.translate(path_map, upd);
                } else {
                    string upd = vars.set_item_value(arg, "0", path_map);
                    hashes.translate(path_map, upd);
                }
            }
        }
        hashes.translate(init_bins, bins);
        res = hashes;
    }*/

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
