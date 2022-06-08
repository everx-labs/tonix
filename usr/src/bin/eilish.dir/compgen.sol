pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract compgen is Shell {

    // Flag values that control parameter pattern substitution
    uint8 constant MATCH_ANY        = 0;
    uint8 constant MATCH_BEG        = 1;
    uint8 constant MATCH_END        = 2;
    uint8 constant MATCH_TYPEMASK   = 3;
    uint8 constant MATCH_GLOBREP    = 16;
    uint8 constant MATCH_QUOTED     = 32;

        function main(svm sv_in) external pure returns (svm sv) {
            sv = sv_in;
            s_proc p = sv.cur_proc;
            string[] params = p.params();
        (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fj) = p.flag_values("abcdefgj");
        (bool fk, bool fs, bool fu, bool fv, , , , ) = p.flag_values("ksuv");
        bool print_names = fa || fb || fe || fv;
        bool print_values = fc || fd || ff || fg || fj || fk || fs || fu;

        string[] vp = sv.vmem[1].vm_pages;
        string[] pages;
        uint8 indices;
        if (fa) pages.push(vp[0]);
        if (fb) pages.push(vp[5]);
        if (fc) pages.push(vp[11]);
//        if (fd) pages.push(vp[]);
//        if (fe) pages.push(vp[]);
//        if (ff) pages.push(vp[]);
        if (fg) pages.push(vp[7]);
//        if (fj) pages.push(vp[]);
        if (fk) pages.push(vp[10]);
//        if (fs) pages.push(vp[]);
        if (fu) pages.push(vp[6]);
        if (fv) pages.push(vp[8]);

//        string page = vmem.vmem_fetch_page(sv.vmem[1], 3);
        string param = params.empty() ? "" : params[0];
        for (string pool: pages) {
            uint p_len = param.byteLength();
            (string[] lines, ) = pool.split("\n");
            for (string line: lines) {
                (, string name, string value) = vars.split_var_record(line);
                if (name.byteLength() >= p_len && name.substr(0, p_len) == param)
                    p.puts(print_names ? name : print_values ? value : "");
            }
        }
        sv.cur_proc = p;
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
