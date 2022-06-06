pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract alias_ is Shell {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
//        bool f_terse = p.flag_set("t");
        string[] params = p.params();
        s_of f = p.fopen("alias", "r");
        string alias_page;
        string token = params.empty() ? "" : params[0];

        if (!f.ferror()) {
            alias_page = f.gets_s(0);
            if (params.empty()) {
                while (!f.feof()) {
                    string line = f.fgetln();
                    (, string name, string value) = vars.split_var_record(line);
                    value.quote();
                    p.puts("alias " + name + "=" + value);
                }
            } else {
                string cur_val = vars.val(token, alias_page);
                if (cur_val.empty()) {
                    p.puts("-tosh: alias: " + token + ": not found");
                } else {
                    cur_val.quote();
                    p.puts("alias " + token + "=" + cur_val);
                }
            }
        } else
            p.perror("Failed to read alias page from pool");
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

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        ec = EXECUTE_SUCCESS;
        out = "";
        (string[] params, , ) = arg.get_args(args);
        if (params.empty()) {
            (string[] aliases, ) = pool.split_line("\n", "\n");
            for (string line: aliases) {
                (, string name, string value) = vars.split_var_record(line);
                value.quote();
                out.append("alias " + name + "=" + value + "\n");
            }
        } else {
            string token = params[0];
            string cur_val = vars.val(token, pool);
            if (cur_val.empty()) {
                ec = EXECUTE_FAILURE;
                out.append("-tosh: alias: " + token + ": not found\n");
            } else {
                cur_val.quote();
                out.append("alias " + token + "=" + cur_val + "\n");
            }
        }
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
