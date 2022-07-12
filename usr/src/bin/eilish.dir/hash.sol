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
        string[] params = e.params();
        bool no_flags = e.flags_empty();
        bool no_args = params.empty();
        (bool print_tabbed, bool print_reusable, bool forget_some, bool forget_all, bool use_pathname, , , ) = e.flag_values("tldrp");
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
        (string name, string value) = vars.item_value(item);
        return print_reusable ? "builtin hash -p " + path + "/" + name + " " + name :
               print_tabbed ? name + "\t" + path + "/" + name :
               fmt.pad(value, 4, fmt.RIGHT) + "\t" + path + "/" + name;
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
