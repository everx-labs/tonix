pragma ton-solidity >= 0.62.0;

import "pbuiltin_special.sol";

contract alias_ is pbuiltin_special {

    function _retrieve_pages(s_proc) internal pure override returns (uint8[]) {
        return [sh.ALIAS];
    }

    function _print(s_proc p, s_of f, string[] page) internal pure override returns (s_of res) {
        res = f;

        if (p.params().empty()) {
            for (string l: page) {
                (, string name, string value) = vars.split_var_record(l);
                value.quote();
                res.fputs("alias " + name + "=" + value);
            }
        }

        for (string param: p.params()) {
            string rec = vars.get_pool_record(param, page);
            if (!rec.empty()) {
                (, string name, string value) = vars.split_var_record(rec);
                value.quote();
                res.fputs("alias " + name + "=" + value);
            }
        }
    }

    function _modify(s_proc p, string[] page_in) internal pure override returns (string[] page) {
        page = page_in;
        string sargs = p.p_args.ar_misc.sargs;
        if (sargs.strchr("=") > 0) {
            (string name, string value) = sargs.csplit("=");
            page = vars.set_var(name, value, page);
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
