pragma ton-solidity >= 0.61.0;

import "../include/Utility.sol";

contract rmdir is Utility {

    function _remove_dir_entries(string dir_list, string[] victims) internal pure returns (string contents) {
        contents = dir_list;
        for (string s: victims)
            contents.translate(s, "");
    }

//    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        Ar[] ars;
        (uint16 wd, string[] params, , ) = p.get_env();
        bool verbose = p.flag_set("v");
        bool force_removal = p.flag_set("f");
        uint8 ec;
        mapping (uint16 => string[]) victims;
        string sout;

        for (string param: params) {
            s_of f = p.fopen(param, "r");

            string s = param;
            s_stat st;
            st.stt(f.attr);
            uint16 iop = st.st_ino;
            uint16 parent = wd;
            sout.aif(verbose, "rmdir: removing directory, " + s.squote() + "\n");
            if (iop >= sb.ROOT_DIR) {
//                if (t == ft.FT_DIR) {
                if (ft.is_dir(st.st_mode)) {
//                    if (inodes[iop].n_links < 3) {
                    if (st.st_nlink < 3) {
                        ars.push(Ar(aio.UNLINK, iop, s, ""));
                        victims[parent].push(udirent.dir_entry_line(iop, s, ft.FT_DIR));
                    } else
//                        errors.push(Err(0, er.ENOTEMPTY, s));
                        ec = er.ENOTEMPTY;
                } else
//                    errors.push(Err(0, er.ENOTDIR, s));
//                    fds_out.perror(fds, er.ENOTDIR, "rmdir: " + s);
                    ec = er.ENOTDIR;
            } else if (!force_removal)
                ec = uint8(iop);
//                errors.push(Err(0, iop, s));
//                fds_out.perror(fds, iop, "rmdir: " + s);
            if (ec > er.ESUCCESS)
                p.perror("failed to remove");
        }
        p.puts(sout);
        /*for (Err e: errors) {
            fds_out.perror(fds, uint8(e.explanation), "rmdir: " + e.arg);
            ec = uint8(e.explanation);
        }*/
//        for ((uint16 dir_i, string[] victim_dirents): victims)
//            if (!victim_dirents.empty())
//                ars.push(Ar(aio.UPDATE_DIR_ENTRY, dir_i, "", _remove_dir_entries(data[dir_i], victim_dirents)));
//                ars.push(Ar(aio.UPDATE_DIR_ENTRY, dir_i, "", _remove_dir_entries(fds[dir_i].buf, victim_dirents)));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"rmdir",
"[OPTION]... DIRECTORY...",
"remove empty directories",
"Remove the DIRECTORY(ies), if they are empty.",
"-p      remove DIRECTORY and its ancestors; e.g., 'rmdir -p a/b/c' is similar to 'rmdir a/b/c a/b a'\n\
-v      output a diagnostic for every directory processed",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
