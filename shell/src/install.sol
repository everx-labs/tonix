pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract install is Utility {

    function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            arg_list.push(Arg(s_arg, ft, index, parent, dir_index));
        }
        (out, file_action, ars, errors) = _install(params, flags, wd, arg_list, sb.get_inode_count(inodes), inodes, data);
    }

    function _install(string[] args, string flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
        (bool verbose, bool preserve, bool request_backup, bool to_file_flag, bool to_dir_flag, bool newer_only, bool force, bool recurse)
            = arg.flag_values("vnbTtufr", flags);

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
            return (out, action, ars, errors);

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

        uint8 action_type = IO_CREATE_FILES;
        uint8 action_item_type = IO_MKFILE;

        uint n = last - first;
        action = Action(action_type, uint16(n));

        for (uint i = first; i < last; i++) {
            (string s_path, uint8 s_ft, uint16 s_ino, , uint16 s_dir_idx) = arg_list[i].unpack();

            if (s_ino < INODES) { errors.push(Err(0, s_ino, s_path)); break; }
            if (verbose) { out.append(str.quote(s_path) + "=>" + str.quote(t_path)); }

            else if (to_file_flag && to_dir && s_ft == FT_REG_FILE)
                errors.push(Err(cant_overwrite_dir, 0, str.quote(t_path)));
            else if (collision && newer_only) {
                if (inodes[t_ino].modified_at > inodes[s_ino].modified_at)
                    continue;
            } else {
                (, string file_name) = path.dir(to_dir ? s_path : t_path);

                ars.push(Ar(action_item_type, s_ft, s_ino, s_dir_idx, file_name, ""));
                dirents.append(dirent.dir_entry_line(ic++, file_name, s_ft));
                dirent_action_type = IO_ADD_DIR_ENTRY;
            }
        }

        if (dirent_action_type > 0)
            ars.push(Ar(dirent_action_type, FT_DIR, to_dir ? t_ino : wd, t_idx, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(IO_UNLINK, t_ft, t_ino, t_idx, t_path, ""));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"install",
"[OPTION]... [-T] SOURCE DEST\n\tinstall [OPTION]... SOURCE... DIRECTORY\n\tinstall [OPTION]... -t DIRECTORY SOURCE...\n\tinstall [OPTION]... -d DIRECTORY...",
"copy files and set attributes",
"Copy files into destination locations you choose. In the first three forms, copy SOURCE to DEST or multiple SOURCE(s) to the existing DIRECTORY, while setting permission modes and owner/group.  In the 4th form, create all components of the given DIRECTORY(ies).",
"-b      make a backup of each existing destination file\n\
-c      (ignored)\n\
-C      compare each pair of source and destination files, and in some cases, do not modify the destination at all\n\
-d      treat all arguments as directory names; create all components of the specified directories\n\
-D      create all leading components of DEST except the last, or all components of --target-directory, then copy SOURCE to DEST\n\
-g      set group ownership, instead of process' current group\n\
-m      set permission mode (as in chmod), instead of rwxr-xr-x\n\
-o      set ownership (super-user only)\n\
-p      apply access/modification times of SOURCE files to corresponding destination files\n\
-s      strip symbol tables\n\
-S      override the usual backup suffix\n\
-t      copy all SOURCE arguments into DIRECTORY\n\
-T      treat DEST as a normal file\n\
-v      print the name of each directory as it is created",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
