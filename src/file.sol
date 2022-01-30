pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract file is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string /*err*/, Err[] errors) {
        (, , string flags, string pi) = arg.get_env(argv);
        (bool brief_mode, bool dont_pad, bool add_null, bool follow_symlinks, bool print_version, , , ) = arg.flag_values("bN0Lv", flags);
        if (print_version)
            out = "version 2.0\n";

        DirEntry[] contents = dirent.parse_param_index(pi);
        for (DirEntry de: contents) {
            (uint8 ft, string name, uint16 index) = de.unpack();
            if (ft != FT_UNKNOWN) {
                (uint16 mode, , , , , uint16 device_id, uint32 file_size, , , ) = inodes[index].unpack();

                if (!brief_mode)
                    out.append(str.aif(name, add_null, "\x00") + str.aif(": ", !dont_pad, "\t"));
                if (ft == FT_REG_FILE) {
                    out = str.aif(out, file_size == 0, "empty");
                    out = str.aif(out, file_size == 1, "very short file (no magic)");
                    out = str.aif(out, file_size > 1, "ASCII text");
                } else
                    out.append(inode.file_type_description(mode));
                if (ft == FT_CHRDEV || ft == FT_BLKDEV) {
                    (string major, string minor) = inode.get_device_version(device_id);
                    out.append(" (" + major + "/" + minor + ")");
                }
                if (ft == FT_SYMLINK && !follow_symlinks) {
                    (, string target, ) = dirent.get_symlink_target(inodes[index], data[index]).unpack();
                    out.append(" to " + target);
                }
                out.append("\n");
            } else
                errors.push(Err(0, er.ENOENT, name));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
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
