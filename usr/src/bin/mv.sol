pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract mv is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        Err[] errors;
        Ar[] ars;
        string out;
        (uint16 wd, , , ) = p.get_env();
        uint16 ic = sb.get_inode_count(inodes);
        s_dirent[] contents = p.p_args.ar_misc.pos_args;

        (bool verbose, bool preserve, bool request_backup, bool to_file_flag, bool to_dir_flag, bool newer_only, bool force, bool recurse)
            = p.flag_values("vnbTtufR");

        bool to_dir = to_dir_flag;
        uint nargs = contents.length;

        uint last;
        uint first;
        uint target_n;

        if (to_dir_flag) {
            first = 1;
            last = nargs;
            target_n = 0;
        } else {
            first = 0;
            last = nargs - 1;
            target_n = nargs - 1;
        }
        (uint16 t_ino, , string t_path) = contents[target_n].unpack();
        bool dest_exists = t_ino >= sb.ROOT_DIR;
        s_stat tst = fs.istat(inodes[t_ino]);

        if (dest_exists && libstat.is_dir(tst.st_mode))
            to_dir = true;

        bool collision = dest_exists && libstat.is_reg(tst.st_mode);
        bool overwrite_dest = collision && (!preserve || force);

//        if (!errors.empty() || collision && preserve)
//            return (out, ars, errors);

        string dirents;
        uint8 dirent_action_type;
        if (request_backup && overwrite_dest) {
            string t_backup_path = t_path + "~";
            out.aif(verbose, "(backup:" + t_backup_path.squote() + ")");

            ars.push(Ar(aio.WR_COPY, 0, t_backup_path, ""));
            dirents.append(udirent.dir_entry_line(t_ino, t_backup_path, libstat.FT_REG_FILE));
            dirent_action_type = aio.ADD_DIR_ENTRY;
            ic++;
        }

        uint8 aop = to_dir ? aio.HARDLINK : aio.WR_COPY;

        for (uint i = first; i < last; i++) {
            (uint16 sino, uint8 sft, string spath) = contents[i].unpack();
            uint16 sparent = wd;
            if (sino < sb.ROOT_DIR) { errors.push(Err(0, sino, spath)); break; }
            s_stat st = fs.istat(inodes[sino]);
            uint16 smode = st.st_mode;

            if (verbose) {out.append("renamed " + spath.squote() + "=> " + t_path.squote()); }

            if (libstat.is_dir(smode) && aop == aio.WR_COPY && !recurse)
                errors.push(Err(er.omitting_directory, 0, spath));
            else if (to_file_flag && to_dir && libstat.is_reg(smode))
                errors.push(Err(er.cant_overwrite_dir, 0, t_path.squote()));
            else if (collision && newer_only) {
                if (tst.st_mtim > st.st_mtim)
                    continue;
            } else {
                (, string file_name) = path.dir(to_dir ? spath : t_path);

                ars.push(Ar(aop, sino, file_name, ""));
                dirents.append(udirent.dir_entry_line(aop == aio.HARDLINK ? sino : ic++, file_name, sft));
                dirent_action_type = aio.ADD_DIR_ENTRY;

                ars.push(Ar(aio.UNLINK, sino, spath, ""));
                if (inodes[sino].n_links < 2) {
                    string victim_dirent_pattern = udirent.dir_entry_line(sino, spath, sft);
                    string dir_text = data[sparent];
                    dir_text.translate(victim_dirent_pattern, "");
                    ars.push(Ar(aio.UPDATE_DIR_ENTRY, sparent, spath, dir_text));
                }
            }
        }

        if (dirent_action_type > 0)
            ars.push(Ar(dirent_action_type, to_dir ? t_ino : wd, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(aio.UNLINK, t_ino, t_path, ""));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mv",
"[OPTION]... [-T] SOURCE DEST\t[OPTION]... SOURCE... DIRECTORY\t[OPTION]... -t DIRECTORY SOURCE...",
"move (rename) files",
"Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.",
"-b      make a backup of each existing destination file\n\
-f      do not prompt before overwriting\n\
-n      do not overwrite an existing file\n\
-t      move all SOURCE arguments into DIRECTORY\n\
-T      treat DEST as a normal file\n\
-u      move only when the SOURCE file is newer than the destination file or when the destination file is missing\n\
-v      explain what is being done",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
