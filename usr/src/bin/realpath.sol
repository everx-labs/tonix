pragma ton-solidity >= 0.60.0;

import "../include/Utility.sol";

contract realpath is Utility {

    function main(string argv, s_of[] fds, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
//    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        (bool canon_existing, bool canon_missing, bool dont_expand_symlinks, bool no_errors, bool null_delimiter, /*bool logical*/, /*bool physical*/, )
            = arg.flag_values("emsqzLP", flags);
        bool canon_existing_dir = !canon_existing && !canon_missing;
        string line_delimiter = null_delimiter ? "\x00" : "\n";
        if (wd >= sb.ROOT_DIR) {
//            s_stat cwds = fds.stat(param);

            for (string param: params) {
                (string arg_dir, string arg_base) = path.dir(param);
                bool is_abs_path = param.substr(0, 1) == "/";
                string spath = is_abs_path ? param : fs.xpath(param, wd, inodes, data);
                uint16 cur_dir = is_abs_path ? fs.resolve_absolute_path(arg_dir, inodes, data) : wd;

                s_stat s;// = fds.ustat(param);
                uint16 st_mode = s.st_mode;

                if ((canon_existing_dir || canon_existing) && !dont_expand_symlinks) {
                    (uint16 index, uint8 t) = fs.lookup_dir(inodes[cur_dir], data[cur_dir], arg_base);
//                    if (t == ft.FT_SYMLINK)
                    if (st_mode.is_symlink())
                        (spath, t, , ,) = _dereference(path.EXPAND_SYMLINKS, param, wd, inodes, data).unpack();
                    if (!canon_missing && index < sb.ROOT_DIR) {
                        if (!no_errors)
                            err.append("realpath: missing " + param + ", index " + str.toa(index) + "\n");
                        continue;
                    }
                }
                out.append(spath + line_delimiter);
            }
        } else {
            err.append("Failed to resolve relative path for" + argv + "\n");
            ec = EXECUTE_FAILURE;
        }
    }

    /* Path utilities helpers */
    function _abs_path_walk_up(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string path) {
        uint16 cur_dir = dir;
        while (cur_dir > sb.ROOT_DIR) {
            Inode inode = inodes[cur_dir];
            path = inode.file_name + "/" + path;
            (DirEntry[] contents, int16 status) = udirent.read_dir(inode, data[cur_dir]);
            if (status > 1)
                cur_dir = contents[1].index;
        }
    }

    function _canonicalize(uint16 mode, string param, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string res, bool valid) {
        uint16 canon_mode = mode & 3;
        (string arg_dir, string arg_base) = path.dir(param);
        bool is_abs_path = param.substr(0, 1) == "/";
        valid = true;

        if (canon_mode >= path.CANON_DIRS) {
            uint16 dir_index = is_abs_path ? fs.resolve_absolute_path(arg_dir, inodes, data) : wd;
            (, uint8 t) = fs.lookup_dir(inodes[dir_index], data[dir_index], arg_base);
            if (t == ft.FT_UNKNOWN)
                valid = false;
        }

        res = canon_mode == path.CANON_NONE || (canon_mode == path.CANON_MISS || canon_mode == path.CANON_EXISTS) && is_abs_path ?
            param : canon_mode == path.CANON_DIRS ? fs.xpath(arg_dir, fs.resolve_absolute_path(arg_dir, inodes, data), inodes, data) + "/" + arg_base : fs.xpath(param, wd, inodes, data);
    }

    function _dereference(uint16 mode, string param, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (Arg) {
        bool expand_symlinks = (mode & path.EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 t, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(param, wd, inodes, data);
        Inode inode;
        if (ino > 0 && inodes.exists(ino))
            inode = inodes[ino];
        if (expand_symlinks && t == ft.FT_SYMLINK) {
            (t, param, ino) = udirent.get_symlink_target(inode, data[ino]).unpack();
        }
        return Arg(param, t, ino, parent, dir_index);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"realpath",
"[OPTION]... FILE...",
"print the resolved path",
"Print the resolved absolute file name; all but the last component must exist.",
"-e      all components of the path must exist\n\
-m      no path components need exist or be a directory\n\
-L      resolve '..' components before symlinks\n\
-P      resolve symlinks as encountered (default)\n\
-q      suppress most error messages\n\
-s      don't expand symlinks\n\
-z      end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
