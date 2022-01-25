pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract file is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        for (string s_arg: params) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_file(flags, s_arg, ft, inodes[index], data[index]) + "\n");
            else {
                err.append("Failed to resolve relative path for" + s_arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _file(string f, string name, uint8 ft, Inode ino, bytes node_data) private pure returns (string out) {
        bool brief_mode = arg.flag_set("b", f);
        bool dont_pad = arg.flag_set("N", f);
        bool add_null = arg.flag_set("0", f);
        bool follow_symlinks = arg.flag_set("L", f);
        if (arg.flag_set("v", f))
            return "version 2.0\n";

        (uint16 mode, , , , , uint16 device_id, uint32 file_size, , , ) = ino.unpack();

        if (!brief_mode)
            out = stdio.aif(name, add_null, "\x00") + stdio.aif(": ", !dont_pad, "\t");
        if (ft == FT_REG_FILE) {
            out = stdio.aif(out, file_size == 0, "empty");
            out = stdio.aif(out, file_size == 1, "very short file (no magic)");
            out = stdio.aif(out, file_size > 1, "ASCII text");
        } else
            out.append(inode.file_type_description(mode));
        if (ft == FT_CHRDEV || ft == FT_BLKDEV) {
            (string major, string minor) = inode.get_device_version(device_id);
            out.append(" (" + major + "/" + minor + ")");
        }
        if (ft == FT_SYMLINK && !follow_symlinks) {
            (, string target, ) = dirent.get_symlink_target(ino, node_data).unpack();
            out.append(" to " + target);
        }
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
