pragma ton-solidity >= 0.63.0;

import "pbuiltin.sol";

contract builtin is pbuiltin {

    using vars for string;
    constructor(device_t pdev, device_t dev) udev (pdev, dev) public {
        tvm.accept();
    }

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] params = cc.params();
        uint n_params = params.length;
        if (n_params == 0)
            return (rc, e);
        string cmd = params[0];
        for (uint i = 0; i < n_params - 1; i++)
            params[i] = params[i + 1];
        params.pop();
        n_params--;
        if (cmd == "true")
            rc = EXIT_SUCCESS;
        else if (cmd == "false")
            rc = EXIT_FAILURE;
        else if (cmd == "echo") {
            e.puts(libstring.join_fields(cc.params(), " "));
            if (!cc.flag_set('n'))
                e.putchar('\n');
        } else if (cmd == "pwd") {
            uint16 wd = e.get_cwd();
            if (wd == 0) {
                e.perror("current directory cannot be read");
                rc = EXIT_FAILURE;
            } else
                e.puts(vars.val("PWD", e.environ[sh.VARIABLE]));
        } else if (cmd == "readonly" || cmd == "export" || cmd == "declare" || cmd == "alias") {
            uint8 n_page = cmd == "alias" ? sh.ALIAS : e.flag_set("f") ? sh.FUNCTION : sh.VARIABLE;
            string sattrs;
            bool no_flags = cc.flags_empty();
            bool no_params = params.empty();
            string prefix = "declare ";
            string suffix;
            string[] res;
            if (cmd == "readonly") sattrs = "-r";
            if (cmd == "export") sattrs = cc.flag_set("n") ? "+x" : "-x";
            if (cmd == "declare") {
                bytes battrs = "aAxirtnf";
                for (byte b: battrs)
                    if (e.flag_set(b))
                        sattrs.append(bytes(b));
            }
            if (cc.flag_set("f"))
                sattrs.append("f");
            byte ba;
            if (!sattrs.empty())
                ba = bytes(sattrs)[0];
            string[] page = e.environ[n_page];
            if (no_params) {
                res = vars.gen_records(page, ba, "");
                for (string line: res)
                    e.puts(_print_line(line, sattrs, prefix, suffix));
            }
            if (e.flag_set("p") || (no_flags && no_params)) {
//                string[] pages = e.environ[page];
                for (string param: params) {
                    res = vars.gen_records(page, ba, param);
                    string line = vars.get_pool_record(param, res);
                    if (!line.empty())
                        e.puts(_print_line(line, sattrs, prefix, suffix));
                    else
                        rc = EXIT_FAILURE;
                }
            } else {
                for (string param: cc.params()) {
                    e.environ[sh.ARRAYVAR][n_page].arrayvar_add(param);
                    e.environ[n_page].set_var("", param);
                }
            }
        } else if (cmd == "unalias") {
            string[] page;
            if (!cc.flag_set("a")) {
                page = e.environ[sh.ALIAS];
                for (string param: e.params()) {
                    page.unset_var(param);
                    e.environ[sh.ARRAYVAR][sh.ALIAS].arrayvar_remove(param);
                }
            }
            e.environ[sh.ALIAS] = page;
        } else if (cmd == "unset") {
            uint8[] pages;
            bool unset_vars = cc.flag_set("v");
            if (unset_vars)
                pages.push(sh.VARIABLE);
            bool unset_functions = cc.flag_set("f");
            if (unset_functions)
                pages.push(sh.FUNCTION);
            string sattrs = unset_functions ? "-f" : unset_vars ? "+f" : "--";
            for (uint8 n: pages) {
                string[] page = e.environ[n];
                for (string arg: cc.params()) {
                    string line = vars.get_pool_record(arg, page);
                    if (!line.empty()) {
                        (string attrs, ) = line.csplit(" ");
                        if (vars.match_attr_set(sattrs, attrs))
                            page.unset_var(arg);
                    }
                }
                e.environ[n] = page;
            }
        }
    }

    function _print_line(string line, string sattrs, string prefix, string suffix) internal pure returns (string) {
        (string attrs, string name, string value) = vars.split_var_record(line);
        if (vars.match_attr_set(sattrs, attrs)) {
            if (str.strchr(attrs, "f") > 0)
                return name + " ()\n{\n" + fmt.indent(value.translate(";", "\n"), 4, "\n") + "}\n";
            return prefix + line + suffix;
        }
    }
    function _name() internal pure override returns (string) {
        return "builtin";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"builtin",
"[shell-builtin [arg ...]]",
"Execute shell builtins.",
"Execute SHELL-BUILTIN with arguments ARGs without performing command lookup.",
"",
"",
"Returns the exit status of SHELL-BUILTIN, or false if SHELL-BUILTIN is not a shell builtin.");
    }

}
