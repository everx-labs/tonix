pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract mv is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _induce(session, input, inodes, data);
    }

    function induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _induce(session, input, inodes, data);
    }

    function _induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
//    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        (out, file_action, ars, errors) = _mv(args, flags, session.wd, arg_list, _get_inode_count(inodes), inodes, data);
    }

    function _mv(string[] args, uint flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
        bool verbose = (flags & _v) > 0;
        bool preserve = (flags & _n) > 0;
        bool request_backup = (flags & _b) > 0;
        bool to_file_flag = (flags & _T) > 0;
        bool to_dir_flag = (flags & _t) > 0;
        bool newer_only = (flags & _u) > 0;
        bool force = (flags & _f) > 0;
        bool recurse = (flags & _r + _R) > 0;

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
            out = _if(out, verbose, "(backup:" + _quote(t_backup_path) + ")");

            ars.push(Ar(IO_WR_COPY, FT_REG_FILE, 0, t_ino, t_backup_path, ""));
            dirents.append(_dir_entry_line(t_ino, t_backup_path, FT_REG_FILE));
            dirent_action_type = IO_ADD_DIR_ENTRY;
            ic++;
        }

        uint8 action_type;
        uint8 action_item_type;

        if (!to_dir) {
            action_type = IO_COPY_FILES;
            action_item_type = IO_WR_COPY;
        } else {
            action_type = IO_HARDLINK_FILES;
            action_item_type = IO_HARDLINK;
        }

        uint n = last - first;
        action = Action(action_type, uint16(n));

        for (uint i = first; i < last; i++) {
            (string s_path, uint8 s_ft, uint16 s_ino, uint16 s_parent, uint16 s_dir_idx) = arg_list[i].unpack();

            if (s_ino < INODES) { errors.push(Err(0, s_ino, s_path)); break; }
            if (verbose) {out.append("renamed" + _quote(s_path) + "=>" + _quote(t_path)); }

            if (s_ft == FT_DIR && action_type == IO_HARDLINK_FILES)
                errors.push(Err(no_hardlink_on_dir, 0, s_path));
            if (s_ft == FT_DIR && action_type == IO_COPY_FILES && !recurse)
                errors.push(Err(omitting_directory, 0, s_path));
            else if (to_file_flag && to_dir && s_ft == FT_REG_FILE)
                errors.push(Err(cant_overwrite_dir, 0, _quote(t_path)));
            else if (collision && newer_only) {
                if (inodes[t_ino].modified_at > inodes[s_ino].modified_at)
                    continue;
            } else {
                (, string file_name) = _dir(to_dir ? s_path : t_path);

                ars.push(Ar(action_item_type, s_ft, s_ino, s_dir_idx, file_name, ""));
                dirents.append(_dir_entry_line(action_type == IO_HARDLINK_FILES ? s_ino : ic++, file_name, s_ft));
                dirent_action_type = IO_ADD_DIR_ENTRY;

                    ars.push(Ar(IO_UNLINK, s_ft, s_ino, s_dir_idx, s_path, ""));
                    if (inodes[s_ino].n_links < 2) {
                        string victim_dirent_pattern = _dir_entry_line(s_ino, s_path, s_ft);
                        string dir_text = data[s_parent];
                        string new_dir_contents = _translate(dir_text, victim_dirent_pattern, "");
                        ars.push(Ar(IO_UPDATE_DIR_ENTRY, FT_DIR, s_parent, s_dir_idx, s_path, new_dir_contents));
                }
            }
        }

        if (dirent_action_type > 0)
            ars.push(Ar(dirent_action_type, FT_DIR, to_dir ? t_ino : wd, t_idx, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(IO_UNLINK, t_ft, t_ino, t_idx, t_path, ""));
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("mv", "move (rename) files", "[OPTION]... [-T] SOURCE DEST\t[OPTION]... SOURCE... DIRECTORY\t[OPTION]... -t DIRECTORY SOURCE...",
            "Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.",
            "bfntTuv", 2, M, [
            "make a backup of each existing destination file",
            "do not prompt before overwriting",
            "do not overwrite an existing file",
            "move all SOURCE arguments into DIRECTORY",
            "treat DEST as a normal file",
            "move only when the SOURCE file is newer than the destination file or when the destination file is missing",
            "explain what is being done"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
