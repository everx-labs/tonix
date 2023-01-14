pragma ton-solidity >= 0.63.0;

import "pbuiltin.sol";
import "libstat.sol";
import "libcompspec.sol";
import "vars.sol";
contract compgen is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] params = cc.params();
        uint8[] pages;

        bool do_print = !cc.flags_empty();
        (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fj) = cc.flag_values("abcdefgj");
        (bool fk, bool fs, bool fu, bool fv, , , , ) = cc.flag_values("ksuv");
        bool print_all = params.empty();
        bool print_reusable = fc;
        bool print_names = fa || fb || fe || fv || fg || fu || fk;
        bool print_values = fd || ff || fj || fs;
        if (fa) pages.push(sh.ALIAS);
        if (fb) pages.push(sh.BUILTIN);
        if (fc) pages.push(sh.COMMAND);
        if (fd) pages.push(sh.DIRECTORY);
        if (fe) pages.push(sh.EXPORT);
        if (ff) pages.push(sh.FILE);
        if (fg) pages.push(sh.GROUP);
        if (fk) pages.push(sh.KEYWORD);
        if (fu) pages.push(sh.USER);
        if (fv) pages.push(sh.VARIABLE);

//        e.puts("Params: " + libstring.join_fields(params, " "));
        if (do_print) {
            string param = print_all ? "" : params[0];
            uint p_len = param.byteLength();
            for (uint8 n: pages) {
                string[] page = e.environ[n];
                string[] res;
                if (print_all) {
                    res = vars.filter(page, "", "", false, false);
                } else {
                    res = vars.filter(page, "", param, true, true);
                }
                for (string line: res) {
                    (, string name, string value) = vars.split_var_record(line);
                        if (print_names)
                            e.puts(name);
                        else if (print_values)
                            e.puts(value);
                }
            }
        }
    }

    function _name() internal pure override returns (string) {
        return "compgen";
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
"[-abcdefgjksuv] [-o option] [-A action] [-G globpat] [-W wordlist]  [-F function] [-C command] [-X filterpat] [-P prefix] [-S suffix] [word]",
"Display possible completions depending on the options.",
"Intended to be used from within a shell function generating possible completions. If the optional WORD argument is supplied, generates matches against WORD",
"",
"",
"Returns success unless an invalid option is supplied or an error occurs.");
    }
}
