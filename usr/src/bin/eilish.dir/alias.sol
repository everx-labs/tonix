pragma ton-solidity >= 0.61.1;

import "pbuiltin_special.sol";

contract alias_ is pbuiltin_special {

    function _retrieve_pages(shell_env e, s_proc p) internal pure override returns (mapping (uint8 => string) pages) {
        pages[0] = e.e_aliases;
    }

    function _update_shell_env(shell_env e_in, uint8, string page) internal pure override returns (shell_env e) {
        e = e_in;
        e.e_aliases = page;
    }

    function _print(s_proc p_in, string[] params, string page) internal pure override returns (s_proc p) {
        p = p_in;
        string token = params.empty() ? "" : params[0];

        if (params.empty()) {
            (string[] ali, ) = page.split("\n");
            for (string l: ali) {
                (, string name, string value) = vars.split_var_record(l);
                value.quote();
                p.puts("alias " + name + "=" + value);
            }
        } else {
            string alias_page = page;//p.read_file("alias");
            string cur_tval = vars.val(token, alias_page);
            (, , string args) = p.get_args();
            if (args.strchr("=") > 0) {
                (string name, ) = token.csplit("=");
                string value = args.val("=", "\n");
                string new_value = vars.var_record("", name, value);
                string cur_val = vars.val(name, alias_page);
                if (cur_val.empty())
                    alias_page.append(new_value + "\n");
                else
                    alias_page.translate(cur_val, new_value);
            } else {
                if (cur_tval.empty())
                    p.perror(token + ": not found");
                else {
                    cur_tval.quote();
                    p.puts("alias " + token + "=" + cur_tval);
                }
            }
            p.puts("Result: ");
            p.puts(alias_page);
        }
//        sv.cur_proc = p;
    }

    function _modify(s_proc p_in, string[] params, string page_in) internal pure override returns (s_proc p, string page) {
        p = p_in;
        string alias_page = page_in;
        page = alias_page;
        string token = params.empty() ? "" : params[0];
        string sargs = p.p_args.ar_misc.sargs;

        if (sargs.strchr("=") > 0) {
            (string name, ) = token.csplit("=");
            string value = sargs.val("=", "\n");
            string new_value = vars.var_record("", name, value);
            string cur_val = vars.val(name, alias_page);
            if (cur_val.empty())
                alias_page.append(new_value + "\n");
            else
                alias_page.translate(cur_val, new_value);
        }
        if (page_in != alias_page)
            page.translate(page_in, alias_page);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"alias",
"[-p] [name[=value] ... ]",
"Define or display aliases.",
"Without arguments, `alias' prints the list of aliases in the reusable form `alias NAME=VALUE' on standard output.\n\
Otherwise, an alias is defined for each NAME whose VALUE is given. A trailing space in VALUE causes the next word\n\
to be checked for alias substitution when the alias is expanded.",
"-p        print all defined aliases in a reusable format",
"",
"alias returns true unless a NAME is supplied for which no alias has been defined.");
    }
}
