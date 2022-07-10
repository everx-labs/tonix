pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";
import "ft.sol";
import "libstat.sol";
import "libcompspec.sol";
import "vars.sol";
contract compgen is pbuiltin_base {

    function main(svm sv_in, shell_env e_in) external pure returns (svm sv, shell_env e) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        e = e_in;
        string[] params = p.params();
        uint8[] pages;

        bool do_print = !p.flags_empty();
        (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fj) = p.flag_values("abcdefgj");
        (bool fk, bool fs, bool fu, bool fv, , , , ) = p.flag_values("ksuv");
        bool print_all = params.empty();
        bool print_reusable = fc;
        bool print_names = fa || fb || fe || fv;
        bool print_values = fd || ff || fg || fj || fk || fs || fu;
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

        if (do_print) {
            s_of res = e.ofiles[libfdt.STDOUT_FILENO];
            for (uint8 n: pages)
                res = _print(res, params, e.environ[n], print_all, print_reusable, print_names, print_values);
            e.ofiles[libfdt.STDOUT_FILENO] = res;
        }
    }

    function _print(s_of f, string[] params, string[] page, bool print_all, bool print_reusable, bool print_names, bool print_values) internal pure returns (s_of res) {
        res = f;
        string param = print_all ? "" : params[0];
        uint p_len = param.byteLength();
        for (string line: page) {
            (, string name, string value) = vars.split_var_record(line);
            if (name.byteLength() >= p_len && name.substr(0, p_len) == param) {
                if (print_names)
                    res.fputs(name);
                else if (print_values)
                    res.fputs(value);
                else if (print_reusable) {
                    (string[] keys, ) = vars.unmap(value);
                    for (string k: keys)
                        res.fputs(k);
                }
            }
        }
    }
    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"compgen",
"[-abcdefgjksuv] [-o option] [-A action] [-G globpat] [-W wordlist]  [-F function] [-C command] [-X filterpat] [-P prefix] [-S suffix] [word]",
"Display possible completions depending on the options.",
"Intended to be used from within a shell function generating possible completions. If the optional WORD argument is supplied, matches against WORD are generated.",
"",
"",
"Returns success unless an invalid option is supplied or an error occurs.");
    }
}
