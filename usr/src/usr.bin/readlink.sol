pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract readlink is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (uint16 wd, string[] params, , ) = p.get_env();
        Err[] errors;
        string out;
        if (wd >= sb.ROOT_DIR)
            (out, errors) = _readlink(p, params, wd, inodes, data);
        else {
            p.perror("Failed to resolve relative path for" + params[0]);
        }
        if (!errors.empty()) {
            for (Err e: errors)
                p.perror("Failed to read link: " + e.arg);
        } else
            p.puts(out);
    }

    function _readlink(s_proc p, string[] params, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        (bool canon_existing_dir, bool canon_existing, bool canon_missing, bool no_newline, bool print_errors, bool null_delimiter, , )
            = p.flag_values("femsqz");
        string line_delimiter = null_delimiter ? "\x00" : "\n";

        bool canon = canon_existing_dir || canon_existing || canon_missing;
        uint16 mode = canon_existing ? 3 : canon_existing_dir ? 2 : canon_missing ? 1 : 0;

        for (string param: params) {
            (, uint8 t, uint16 parent, ) = fs.resolve_relative_path(param, wd, inodes, data);
            string spath;
            bool exists;
            if (canon)
                (spath, exists) = _canonicalize(mode, param, parent, inodes, data);
            else if (t == ft.FT_SYMLINK) {
                Arg arg = _dereference(mode + path.EXPAND_SYMLINKS, param, wd, inodes, data);
                (spath, t, , , ) = arg.unpack();
                exists = t > ft.FT_UNKNOWN;
            } else
                continue;

            if (!exists) {
                if (print_errors)
                    errors.push(Err(0, er.ENOENT, param));
                continue;
            }
            out.append(spath);
//            out = str.aif(out, !no_newline, line_delimiter);
            out.aif(!no_newline, line_delimiter);
        }
    }

    function _canonicalize(uint16 mode, string param, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string res, bool valid) {
        uint16 canon_mode = mode & 0x03;
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
"readlink",
"[OPTION]... FILE...",
"print resolved symbolic links or canonical file names",
"Print value of a symbolic link or canonical file name. Canonicalize by following every symlink in every component of the given name recursively.",
"-f      all but the last component must exist\n\
-e      all components must exist\n\
-m      without requirements on components existence\n\
-n      do not output the trailing delimiter\n\
-q      quiet\n\
-s      suppress most error messages (on by default)\n\
-v      report error messages\n\
-z      end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
