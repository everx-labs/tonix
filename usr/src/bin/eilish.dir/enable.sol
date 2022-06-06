pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract enable is Shell {

    using sbuf for s_sbuf;

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string m = p.opt_value("f");
        string[] params = p.params();

        bool print_all = p.flag_set("a");
        string sattrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (p.flag_set(attr))
                sattrs.append(attr);

        sattrs = print_all ? "" : ("-" + (sattrs.empty() ? "-" : sattrs));

        if (!m.empty()) {
            uint idx = m == "alias" ? 1 : m == "opt_string" ? 2 : m == "index" ? 3 : m == "pool" ? 4 : m == "hash" ? 5 :
                m == "builtin" ? 6 : m == "user" ? 7 : m == "group" ? 8 : 0;
            if (idx > 0) {
                s_sbuf s;
                string page = sv.vmem[1].vm_pages[idx - 1];
                s.sbuf_new(page, page.byteLength(), 0);
                s.sbuf_finish();
                p.p_fd.fdt_ofiles.push(s_of(0, io.SRD, 0, m, 0, s));
                p.p_fd.fdt_nfiles++;
            } else {
                p.puts(m + " not found");
            }
        }
        string pool;
        if (sv.vmem.length > 1 && sv.vmem[1].vm_pages.length > 3)
            pool = sv.vmem[1].vm_pages[5];
        if (params.empty()) {
            (string[] lines, ) = pool.split("\n");
            for (string line: lines) {
                (string attrs, string name, ) = vars.split_var_record(line);
//                (string attrs, ) = str.split(line, " ");
                if (vars.match_attr_set(sattrs, attrs))
                    p.puts("enable " + name);
            }
        }
        for (string param: params) {
            (string name, ) = param.csplit("=");
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.csplit(" ");
                if (vars.match_attr_set(sattrs, cur_attrs))
                    p.puts("enable " + name);
            } else {
                p.puts("enable: " + name + " not found");
            }
        }
        sv.cur_proc = p;
    }

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        (, bool print_all, , , , , , ) = arg.flag_values("pas", flags);

        string sattrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                sattrs.append(attr);

        sattrs = print_all ? "" : ("-" + (sattrs.empty() ? "-" : sattrs));

        if (params.empty()) {
            (string[] lines, ) = pool.split("\n");
            for (string line: lines) {
                (string attrs, string name, ) = vars.split_var_record(line);
//                (string attrs, ) = str.split(line, " ");
                if (vars.match_attr_set(sattrs, attrs))
                    out.append("enable " + name + "\n");
            }
        }
        for (string p: params) {
            (string name, ) = p.csplit("=");
            string cur_record = vars.get_pool_record(name, pool);
            if (!cur_record.empty()) {
                (string cur_attrs, ) = cur_record.csplit(" ");
                if (vars.match_attr_set(sattrs, cur_attrs))
                    out.append("enable " + name + "\n");
            } else {
                ec = EXECUTE_FAILURE;
                out.append("enable: " + name + " not found\n");
            }
        }
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, string flags, ) = arg.get_args(args);
//        (bool load, bool disable, bool unload, bool posix_only, , , , ) = arg.flag_values("fnds", flags);

        string page = pool;
        string sattrs;
        string[] a_attrs = ["f", "n", "d", "s"];
        for (string attr: a_attrs)
            if (arg.flag_set(attr, flags))
                sattrs.append(attr);

        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);
        ec = EXECUTE_SUCCESS;

        for (string p: params)
            page = vars.set_var_attr(sattrs, p, page);
        res = page;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"enable",
"[-a] [-dnps] [-f filename] [name ...]",
"Enable and disable shell builtins.",
"Enables and disables builtin shell commands.  Disabling allows you to execute a disk command which has the same\n\
name as a shell builtin without using a full pathname.",
"-a        print a list of builtins showing whether or not each is enabled\n\
-n        disable each NAME or display a list of disabled builtins\n\
-p        print the list of builtins in a reusable format\n\
-s        print only the names of Posix `special' builtins\n\n\
Options controlling dynamic loading:\n\
-f        Load builtin NAME from shared object FILENAME\n\
-d        Remove a builtin loaded with -f\n\n\
Without options, each NAME is enabled.",
"To use the `test' found in $PATH instead of the shell builtin version, type `enable -n test'.",
"Returns success unless NAME is not a shell builtin or an error occurs.");
    }
}
