pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract alias_ is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();
        s_of f = p.fopen("alias", "r");
        string token = params.empty() ? "" : params[0];

        if (params.empty()) {
            string[] ali = p.map_file("alias");
            for (string l: ali) {
                (, string name, string value) = vars.split_var_record(l);
                value.quote();
                p.puts("alias " + name + "=" + value);
            }
        } else {
            string alias_page = p.read_file("alias");
            string cur_tval = vars.val(token, alias_page);
            (, , string argv) = p.get_args();
            if (argv.strchr("=") > 0) {
                (string name, ) = token.csplit("=");
                string value = argv.val("=", "\n");
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
        sv.cur_proc = p;
    }

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, , string argv) = arg.get_args(args);
        string alias_page = pool;

        string initial_val = alias_page;
        string token = params.empty() ? "" : params[0];
        ec = EXECUTE_SUCCESS;
        if (argv.strchr("=") > 0) {
            (string name, ) = token.csplit("=");
            string value = argv.val("=", "\n");
            string new_value = vars.var_record("", name, value);
            string cur_val = vars.val(name, alias_page);
            if (cur_val.empty())
                alias_page.append(new_value + "\n");
            else
                alias_page.translate(cur_val, new_value);
        }
        if (initial_val != alias_page)
            res = libstring.translate(pool, initial_val, alias_page);
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
