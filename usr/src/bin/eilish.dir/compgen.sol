pragma ton-solidity >= 0.61.2;

import "pbuiltin_dict.sol";
import "../../lib/ft.sol";
import "../../lib/libstatmode.sol";
import "../../lib/libstat.sol";
contract compgen is pbuiltin_dict {

    using libstat for s_stat;
    function _modify(svm sv_in, string[] params, string page_in) internal pure override returns (svm, string) {}
    function _load(svm sv_in, shell_env e_in, string page_in) internal pure override returns (svm sv, shell_env e, string page) {
        sv = sv_in;
        e = e_in;
        page = page_in;
        s_proc p = sv.cur_proc;
        (bool ppid, bool fsize, , bool numuid) = (true, true, true, true);
        (mapping (uint16 => string) user, ) = p.get_users_groups();
        (, , , , , uint16 p_pid, uint16 p_oppid, string p_comm, , , , , , ) = p.unpack();
        p.puts("COMMAND\tPID\tPPID\tUSER\tFD\tTYPE\tDEVICE\tSIZE/OFF\tNODE\tNAME");
        s_of[] fds = e.ofiles;
        for (s_of f: fds) {
            (uint attr, uint16 flags, uint16 file, string path, uint32 offset, ) = f.unpack();
            s_stat st;
            st.stt(attr);
            (uint16 st_dev, uint16 st_ino, uint16 st_mode, , uint16 st_uid, , , uint32 st_size,
                , , , ) = st.unpack();
            string sm = (flags & io.SRD) > 0 ? "r" : (flags & io.SWR) > 0 ? "w" : (flags & io.SRW) > 0 ? "rw" : "?";
            uint32 sizoff = fsize ? st_size : offset;
            p.puts(format("{}\t{}\t{}\t{}\t{}{}\t{}\t{},{}\t{}\t{}\t{}", p_comm, p_pid, ppid ? str.toa(p_oppid) : "", numuid ? str.toa(st_uid) : user[st_uid], file, sm, ft.ft_desc(st_mode),
                st_dev >> 8, st_dev & 0xFF, sizoff, st_ino, path));
        }
        sv.cur_proc = p;
    }
    function _update_shell_env(shell_env e_in, svm sv, uint8 n, string page) internal pure override returns (shell_env) {}

    function _select(svm sv, shell_env e) internal pure override returns (mapping (uint8 => string) pages, bool do_print, bool do_modify, bool do_load, bool print_names, bool print_values) {
        s_proc p = sv.cur_proc;
        do_print = !p.flags_empty();
        (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fj) = p.flag_values("abcdefgj");
        (bool fk, bool fs, bool fu, bool fv, bool fz, , , ) = p.flag_values("ksuvz");
        do_modify = false;
        do_load = fz;
        print_names = fa || fb || fe || fv;
        print_values = fc || fd || ff || fg || fj || fk || fs || fu;

        string[] vp = sv.vmem[1].vm_pages;
        if (fa) pages[0] = e.aliases;
        if (fb) pages[5] = vp[5];
        if (fc) pages[11] = vp[11];
        if (fe) pages[13] = e.exports;
        if (fg) pages[7] = vp[7];
        if (fk) pages[10] = vp[10];
        if (fu) pages[6] = vp[6];
        if (fv) pages[8] = e.vars;
        if (fz) pages[14] = e.vars;
    }

//    function _print(svm sv_in, string[] params, string page, bool print_names, bool print_values) internal pure override returns (svm sv) {
    function _print(s_proc , s_of f, string[] params, string page, bool print_names, bool print_values) internal pure override returns (s_of res) {
        res = f;
//        sv = sv_in;
//        s_proc p = sv.cur_proc;

        string param = params.empty() ? "" : params[0];
        uint p_len = param.byteLength();
        (string[] lines, ) = page.split("\n");
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            if (name.byteLength() >= p_len && name.substr(0, p_len) == param)
                res.fputs(print_names ? name : print_values ? value : "");
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
