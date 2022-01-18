pragma ton-solidity >= 0.54.0;

import "Utility.sol";

contract file is Utility {

    function exec(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (string[] params, string flags, ) = _get_args(args);
        for (string arg: params) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_file(flags, arg, ft, inodes[index], data[index]) + "\n");
            else {
                err.append("Failed to resolve relative path for" + arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _file(string f, string name, uint8 ft, Inode inode, bytes node_data) private pure returns (string out) {
        bool brief_mode = _flag_set("b", f);
        bool dont_pad = _flag_set("N", f);
        bool add_null = _flag_set("0", f);
        bool follow_symlinks = _flag_set("L", f);
        if (_flag_set("v", f))
            return "version 2.0\n";

        (uint16 mode, , , , , uint16 device_id, uint32 file_size, , , ) = inode.unpack();

        if (!brief_mode)
            out = _if(name, add_null, "\x00") + _if(": ", !dont_pad, "\t");
        if (ft == FT_REG_FILE) {
            out = _if(out, file_size == 0, "empty");
            out = _if(out, file_size == 1, "very short file (no magic)");
            out = _if(out, file_size > 1, "ASCII text");
        } else
            out.append(_file_type_description(mode));
        if (ft == FT_CHRDEV || ft == FT_BLKDEV) {
            (string major, string minor) = _get_device_version(device_id);
            out.append(" (" + major + "/" + minor + ")");
        }
        if (ft == FT_SYMLINK && !follow_symlinks) {
            (, string target, ) = _get_symlink_target(inode, node_data).unpack();
            out.append(" to " + target);
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("file", "determine file type", "[OPTION...] [FILE...]",
            "Determine type of FILE.",
            "bELhNv0", 1, M, [
            "do not prepend filenames to output lines",
            "on filesystem errors, issue an error message and exit",
            "follow symlinks (default if POSIXLY_CORRECT is set)",
            "don't follow symlinks (default if POSIXLY_CORRECT is not set) (default)",
            "do not pad output",
            "print the version of the program and exit",
            "terminate filenames with ASCII NUL"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"file",
"[OPTION...] [FILE...]",
"determine file type",
"Determine type of FILE.",
"-b      do not prepend filenames to output lines\n\
-E      on filesystem errors, issue an error message and exit\n\
-L      follow symlinks (default if POSIXLY_CORRECT is set)\n\
-h      don't follow symlinks (default if POSIXLY_CORRECT is not set) (default)\n\
-N      do not pad output\n\
-v      print the version of the program and exit\n\
-0      terminate filenames with ASCII NUL",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
