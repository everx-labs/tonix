pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract cp is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        Err[] errors;
        Ar[] ars;
        string out;
        (uint16 wd, , , ) = p.get_env();
        uint16 ic = sb.get_inode_count(inodes);
        s_dirent[] contents = p.p_args.ar_misc.pos_args;

        (bool verbose, bool preserve, bool request_backup, bool to_file_flag, bool to_dir_flag, bool newer_only, bool force, bool recurse)
            = p.flag_values("vnbTtufr");
        bool hardlink = p.flag_set("l");
        bool symlink = p.flag_set("s");

        if (hardlink && symlink)
            errors.push(Err(er.hard_or_symlink, 0, ""));

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
        if (request_backup && overwrite_dest) {
            string t_backup_path = t_path + "~";
            out.aif(verbose, "(backup:" + t_backup_path.squote() + ")");
            ars.push(Ar(aio.WR_COPY, 0, t_backup_path, ""));
            dirents.append(udirent.dir_entry_line(t_ino, t_backup_path, libstat.FT_REG_FILE));
            ic++;
        }

        uint8 aop = symlink ? aio.SYMLINK : hardlink ? aio.HARDLINK : aio.WR_COPY;

        for (uint i = first; i < last; i++) {
            (uint16 sino, uint8 sft, string spath) = contents[i].unpack();
            if (sino < sb.ROOT_DIR) { errors.push(Err(0, sino, spath)); break; }
            s_stat st = fs.istat(inodes[sino]);
            if (verbose) { out.append(spath.squote() + "=>" + t_path.squote()); }
            uint16 smode = st.st_mode;
            if (libstat.is_dir(smode) && aop == aio.HARDLINK)
                errors.push(Err(er.no_hardlink_on_dir, 0, spath));
            if (libstat.is_dir(smode) && aop == aio.WR_COPY && !recurse)
                errors.push(Err(er.omitting_directory, 0, spath));
            else if (to_file_flag && to_dir && libstat.is_reg(smode))
                errors.push(Err(er.cant_overwrite_dir, 0, t_path.squote()));
            else if (collision && newer_only) {
//                if (inodes[t_ino].modified_at > inodes[sino].modified_at)
                if (tst.st_mtim > st.st_mtim)
                    continue;
            } else {
                (, string file_name) = path.dir(to_dir ? spath : t_path);
                ars.push(Ar(aop, sino, file_name, ""));
                dirents.append(udirent.dir_entry_line(aop == aio.HARDLINK ? sino : ic++, file_name, sft));
            }
        }

        if (!dirents.empty())
            ars.push(Ar(aio.ADD_DIR_ENTRY, to_dir ? t_ino : wd, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(aio.UNLINK, t_ino, t_path, ""));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"cp",
"[OPTION]... [-T] SOURCE DEST\n\tcp [OPTION]... SOURCE... DIRECTORY\n\tcp [OPTION]... -t DIRECTORY SOURCE...",
"copy files and directories",
"Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.",
"-a      same as -dR -p\n\
-b      make a backup of each existing destination file\n\
-d      same as -P, preserve links\n\
-f      if an existing destination file cannot be opened, remove it and try again\n\
-H      follow command-line symbolic links in SOURCE\n\
-l      hard link files instead of copying\n\
-L      always follow symbolic links in SOURCE\n\
-n      do not overwrite an existing file\n\
-P      never follow symbolic links in SOURCE\n\
-p      preserve mode, ownership, timestamps\n\
-r      \n\
-R      copy directories recursively\n\
-s      make symbolic links instead of copying\n\
-t      copy all SOURCE arguments into DIRECTORY\n\
-T      treat DEST as a normal file\n\
-u      copy only when the SOURCE file is newer than the destination file or when the destination file is missing\n\
-v      explain what is being done\n\
-x      stay on this file system",
"The backup suffix is '~'. As a special case, cp makes a backup of SOURCE when the force and backup options are given\n\
and SOURCE and DEST are the same name for an existing, regular file.",
"Written by Boris",
"",
"",
"0.01");
    }

}
