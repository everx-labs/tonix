pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract readlink is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        (out, errors) = _readlink(flags, args, session.wd, inodes, data);
    }

    /* Path resolution commands */
    function _readlink(uint flags, string[] s_args, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        bool canon_existing_dir = (flags & _f) > 0;
        bool canon_existing = (flags & _e) > 0;
        bool canon_missing = (flags & _m) > 0;
        bool no_newline = (flags & _n) > 0;
        bool print_errors = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        bool canon = (flags & _f + _e + _m) > 0;
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
            out = _if(out, !no_newline, line_delimiter);
        }
    }

    function _canonicalize(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string res, bool valid) {
        uint16 canon_mode = mode & 3;
        (string arg_dir, string arg_base) = _dir(s_arg);
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

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("readlink", "print resolved symbolic links or canonical file names", "[OPTION]... FILE...",
            "Print value of a symbolic link or canonical file name. Canonicalize by following every symlink in every component of the given name recursively.",
            "femnqsvz", 1, M, [
            "all but the last component must exist",
            "all components must exist",
            "without requirements on components existence",
            "do not output the trailing delimiter",
            "quiet",
            "suppress most error messages (on by default)",
            "report error messages",
            "end each output line with NUL, not newline"]);
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
