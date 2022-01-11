pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract alias_ is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        string alias_page = _get_map_value("TOSH_ALIASES", e[IS_POOL]);

        if (_flag_set("p", flags) || params.empty()) {
            (string[] aliases, ) = _split(alias_page, " ");
            for (string al: aliases) {
                (string name, string value) = _item_value(al);
                out.append("alias " + name + "=" + _wrap(value, W_SQUOTE) + "\n");
            }
        } else {
            string initial_val = alias_page;
            for (string token: params) {
                if (_strchr(token, "=") > 0) {
                    (string name, string value) = _strsplit(token, "=");
                    string new_value = _wrap(name, W_SQUARE) + "=" + _wrap(value, W_DQUOTE);
                    string cur_val = _val(name, alias_page);
                    if (cur_val.empty())
                        alias_page.append(" " + new_value);
                    else
                        alias_page = _translate(alias_page, cur_val, new_value);
                } else {
                    string cur_val = _val(token, alias_page);
                    ec = EXECUTE_FAILURE;
                    out.append(cur_val.empty() ? "-tosh: alias: " + token + ": not found\n" : "alias " + token + "=" + _wrap(cur_val, W_SQUOTE) + "\n");
                }
            }
            if (initial_val != alias_page) {
                string nw = _translate(e[IS_POOL], initial_val, alias_page);
                wr.push(Write(IS_POOL, nw, O_WRONLY));
            }
        }
        wr.push(Write(IS_STDOUT, out, O_WRONLY + O_APPEND));
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
