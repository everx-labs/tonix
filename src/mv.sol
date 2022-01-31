pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract mv is Utility {

    function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            arg_list.push(Arg(s_arg, ft, index, parent, dir_index));
        }
        (out, ars, errors) = _mv(params, flags, wd, arg_list, sb.get_inode_count(inodes), inodes, data);
    }

    function _mv(string[] args, string flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Ar[] ars, Err[] errors) {
        (bool verbose, bool preserve, bool request_backup, bool to_file_flag, bool to_dir_flag, bool newer_only, bool force, bool recurse)
            = arg.flag_values("vnbTtufR", flags);

        bool to_dir = to_dir_flag;
        uint nargs = args.length;

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
        (string t_path, uint8 t_ft, uint16 t_ino, /*uint16 t_parent*/, uint16 t_idx) = arg_list[target_n].unpack();
        bool dest_exists = t_ino >= INODES;

        if (dest_exists && t_ft == FT_DIR)
            to_dir = true;

        bool collision = dest_exists && t_ft == FT_REG_FILE;
        bool overwrite_dest = collision && (!preserve || force);

        if (!errors.empty() || collision && preserve)
            return (out, ars, errors);

        string dirents;
        uint8 dirent_action_type;
        if (request_backup && overwrite_dest) {
            string t_backup_path = t_path + "~";
            out = str.aif(out, verbose, "(backup:" + str.quote(t_backup_path) + ")");

            ars.push(Ar(IO_WR_COPY, FT_REG_FILE, 0, t_ino, t_backup_path, ""));
            dirents.append(dirent.dir_entry_line(t_ino, t_backup_path, FT_REG_FILE));
            dirent_action_type = IO_ADD_DIR_ENTRY;
            ic++;
        }

        uint8 action_item_type = to_dir ? IO_HARDLINK : IO_WR_COPY;

        for (uint i = first; i < last; i++) {
            (string s_path, uint8 s_ft, uint16 s_ino, uint16 s_parent, uint16 s_dir_idx) = arg_list[i].unpack();

            if (s_ino < INODES) { errors.push(Err(0, s_ino, s_path)); break; }
            if (verbose) {out.append("renamed" + str.quote(s_path) + "=>" + str.quote(t_path)); }

            if (s_ft == FT_DIR && action_item_type == IO_WR_COPY && !recurse)
                errors.push(Err(er.omitting_directory, 0, s_path));
            else if (to_file_flag && to_dir && s_ft == FT_REG_FILE)
                errors.push(Err(er.cant_overwrite_dir, 0, str.quote(t_path)));
            else if (collision && newer_only) {
                if (inodes[t_ino].modified_at > inodes[s_ino].modified_at)
                    continue;
            } else {
                (, string file_name) = path.dir(to_dir ? s_path : t_path);

                ars.push(Ar(action_item_type, s_ft, s_ino, s_dir_idx, file_name, ""));
                dirents.append(dirent.dir_entry_line(action_item_type == IO_HARDLINK ? s_ino : ic++, file_name, s_ft));
                dirent_action_type = IO_ADD_DIR_ENTRY;

                ars.push(Ar(IO_UNLINK, s_ft, s_ino, s_dir_idx, s_path, ""));
                if (inodes[s_ino].n_links < 2) {
                    string victim_dirent_pattern = dirent.dir_entry_line(s_ino, s_path, s_ft);
                    string dir_text = data[s_parent];
                    string new_dir_contents = stdio.translate(dir_text, victim_dirent_pattern, "");
                    ars.push(Ar(IO_UPDATE_DIR_ENTRY, FT_DIR, s_parent, s_dir_idx, s_path, new_dir_contents));
                }
            }
        }

        if (dirent_action_type > 0)
            ars.push(Ar(dirent_action_type, FT_DIR, to_dir ? t_ino : wd, t_idx, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(IO_UNLINK, t_ft, t_ino, t_idx, t_path, ""));
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
