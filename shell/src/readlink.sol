pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract readlink is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        Err[] errors;
        if (wd >= ROOT_DIR)
            (out, errors) = _readlink(flags, params, wd, inodes, data);
        else {
            err.append("Failed to resolve relative path for" + argv + "\n");
            ec = EXECUTE_FAILURE;
        }
        if (!errors.empty()) {
            ec = EXECUTE_FAILURE;
            for (Err e: errors)
                err.append("Failed to read link: " + e.arg + "\n");
        }
    }

    function _readlink(string flags, string[] s_args, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        (bool canon_existing_dir, bool canon_existing, bool canon_missing, bool no_newline, bool print_errors, bool null_delimiter, , )
            = arg.flag_values("femsqz", flags);
        string line_delimiter = null_delimiter ? "\x00" : "\n";

        bool canon = canon_existing_dir || canon_existing || canon_missing;
        uint16 mode = canon_existing ? 3 : canon_existing_dir ? 2 : canon_missing ? 1 : 0;

        for (string s_arg: s_args) {
            (, uint8 ft, uint16 parent, ) = _resolve_relative_path(s_arg, wd, inodes, data);
            string path;
            bool exists;
            if (canon)
                (path, exists) = _canonicalize(mode, s_arg, parent, inodes, data);
            else if (ft == FT_SYMLINK) {
                Arg arg = _dereference(mode + EXPAND_SYMLINKS, s_arg, wd, inodes, data);
                (path, ft, , , ) = arg.unpack();
                exists = ft > FT_UNKNOWN;
            } else
                continue;

            if (!exists) {
                if (print_errors)
                    errors.push(Err(0, ENOENT, s_arg));
                continue;
            }
            out.append(path);
            out = stdio.aif(out, !no_newline, line_delimiter);
        }
    }

    function _canonicalize(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string res, bool valid) {
        uint16 canon_mode = mode & 0x03;
        (string arg_dir, string arg_base) = path.dir(s_arg);
        bool is_abs_path = s_arg.substr(0, 1) == "/";
        valid = true;

        if (canon_mode >= CANON_DIRS) {
            uint16 dir_index = is_abs_path ? _resolve_absolute_path(arg_dir, inodes, data) : wd;
            (, uint8 ft) = _lookup_dir(inodes[dir_index], data[dir_index], arg_base);
            if (ft == FT_UNKNOWN)
                valid = false;
        }

        res = canon_mode == CANON_NONE || (canon_mode == CANON_MISS || canon_mode == CANON_EXISTS) && is_abs_path ?
            s_arg : canon_mode == CANON_DIRS ? _xpath(arg_dir, _resolve_absolute_path(arg_dir, inodes, data), inodes, data) + "/" + arg_base : _xpath(s_arg, wd, inodes, data);
    }

    function _dereference(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (Arg) {
        bool expand_symlinks = (mode & EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
        Inode inode;
        if (ino > 0 && inodes.exists(ino))
            inode = inodes[ino];
        if (expand_symlinks && ft == FT_SYMLINK) {
            (ft, s_arg, ino) = _get_symlink_target(inode, data[ino]).unpack();
        }
        return Arg(s_arg, ft, ino, parent, dir_index);
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
"0.01");
    }

}
