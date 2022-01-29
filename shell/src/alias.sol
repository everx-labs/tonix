pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract alias_ is Shell {

    function modify(string args, string pool) external pure returns (uint8 ec, string res) {
        (string[] params, , string argv) = arg.get_args(args);
        string alias_page = pool;

        string initial_val = alias_page;
        string token = params[0];
        ec = EXECUTE_SUCCESS;
        if (str.chr(argv, "=") > 0) {
            (string name, ) = str.split(token, "=");
            string value = str.val(argv, "=", "\n");
            string new_value = vars.var_record("", name, value);
            string cur_val = vars.val(name, alias_page);
            if (cur_val.empty())
                alias_page.append(new_value + "\n");
            else
                alias_page = stdio.translate(alias_page, cur_val, new_value);
        }
        if (initial_val != alias_page)
            res = stdio.translate(pool, initial_val, alias_page);
    }

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        ec = EXECUTE_SUCCESS;
        out = "";
        (string[] params, , ) = arg.get_args(args);
        if (params.empty()) {
            (string[] aliases, ) = stdio.split_line(pool, "\n", "\n");
            for (string line: aliases) {
                (, string name, string value) = vars.split_var_record(line);
                out.append("alias " + name + "=" + vars.wrap(value, vars.W_SQUOTE) + "\n");
            }
        } else {
            string token = params[0];
            string cur_val = vars.val(token, pool);
            if (cur_val.empty()) {
                ec = EXECUTE_FAILURE;
                out.append("-tosh: alias: " + token + ": not found\n");
            } else
                out.append("alias " + token + "=" + vars.wrap(cur_val, vars.W_SQUOTE) + "\n");
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
