pragma ton-solidity >= 0.61.0;

import "../include/Utility.sol";

contract ln is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        Err[] errors;
        Ar[] ars;
        string out;
        (uint16 wd, , , ) = p.get_env();
        uint16 ic = sb.get_inode_count(inodes);
//        s_dirent[] contents = p.p_args.ar_misc.pos_args;

        Arg[] arg_list;
        for (string param: p.params()) {
            (uint16 index, uint8 t, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(param, wd, inodes, data);
            arg_list.push(Arg(param, t, index, parent, dir_index));
        }
        (bool verbose, bool preserve, bool request_backup, bool to_file_flag, bool to_dir_flag, bool newer_only, bool force, bool symlink)
            = p.flag_values("vnbTtufs");

        bool to_dir = to_dir_flag;
        uint nargs = arg_list.length;
        bool multiple_sources = nargs > 2;

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
        (string t_path, uint8 t_ft, uint16 t_ino, , ) = arg_list[target_n].unpack();
        bool dest_exists = t_ino >= sb.ROOT_DIR;

        if (dest_exists && t_ft != ft.FT_DIR) {
            if (multiple_sources)
                errors.push(Err(er.ln_target, er.ENOTDIR, t_path));
            else if (!force)
                errors.push(Err(symlink ? er.failed_symlink : er.failed_hardlink, er.EEXIST, t_path));
        }

        if (dest_exists && t_ft == ft.FT_DIR)
            to_dir = true;

        bool collision = dest_exists && t_ft == ft.FT_REG_FILE;
        bool overwrite_dest = collision && (!preserve || force);

//        if (!errors.empty() || collision && preserve)
//            return (out, ars, errors);

        string dirents;
        uint8 dirent_action_type;
        if (request_backup && overwrite_dest) {
            string t_backup_path = t_path + "~";
            out.aif(verbose, "(backup:" + t_backup_path.squote() + ")");

            ars.push(Ar(aio.WR_COPY, 0, t_backup_path, ""));
            dirents.append(udirent.dir_entry_line(t_ino, t_backup_path, ft.FT_REG_FILE));
            dirent_action_type = aio.ADD_DIR_ENTRY;
            ic++;
        }

        uint8 aop = symlink ? aio.SYMLINK : aio.HARDLINK;

        for (uint i = first; i < last; i++) {
            (string spath, uint8 sft, uint16 sino, , ) = arg_list[i].unpack();

            if (sino < sb.ROOT_DIR) { errors.push(Err(0, sino, spath)); break; }
            if (verbose) { out.append(spath.squote() + "->" + t_path.squote()); }

            if (sft == ft.FT_DIR && aop == aio.HARDLINK)
                errors.push(Err(er.no_hardlink_on_dir, 0, spath));
            else if (to_file_flag && to_dir && sft == ft.FT_REG_FILE)
                errors.push(Err(er.cant_overwrite_dir, 0, t_path.squote()));
            else if (collision && newer_only) {
                if (inodes[t_ino].modified_at > inodes[sino].modified_at)
                    continue;
            } else {
                (, string file_name) = path.dir(to_dir ? spath : t_path);

                ars.push(Ar(aop, sino, file_name, ""));
                dirents.append(udirent.dir_entry_line(aop == aio.HARDLINK ? sino : ic++, file_name, sft));
                dirent_action_type = aio.ADD_DIR_ENTRY;
            }
        }

        if (dirent_action_type > 0)
            ars.push(Ar(dirent_action_type, to_dir ? t_ino : wd, "", dirents));

        if (overwrite_dest && errors.empty())
            ars.push(Ar(aio.UNLINK, t_ino, t_path, ""));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"ln",
"[OPTION]... [-T] TARGET LINK_NAME\n\tln [OPTION]... TARGET\n\tln [OPTION]... TARGET... DIRECTORY\n\tln [OPTION]... -t DIRECTORY TARGET...",
"make links between files",
"In the 1st form, create a link to TARGET with the name LINK_NAME.\n\tIn the 2nd form, create a link to TARGET in the current directory.\n\tIn the 3rd and 4th forms, create links to each TARGET in DIRECTORY. Create hard links by default, symbolic links with -s. By default, each destination (name of new link) should not already exist. When creating hard links, each TARGET must exist. Symbolic links can hold arbitrary text; if later resolved, a relative link is interpreted in relation to its parent directory.",
"-b      make a backup of each existing destination file\n\
-f      remove existing destination files\n\
-L      dereference TARGETs that are symbolic links\n\
-n      treat LINK_NAME as a normal file if it is a symbolic link to a directory\n\
-P      make hard links directly to symbolic links\n\
-r      create symbolic links relative to link location\n\
-s      make symbolic links instead of hard links\n\
-t      specify the DIRECTORY in which to create the links\n\
-T      treat LINK_NAME as a normal file always\n\
-v      print name of each linked file",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
