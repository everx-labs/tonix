pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract file is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (bool brief_mode, bool dont_pad, bool add_null, bool follow_symlinks, bool print_version, , , ) = p.flag_values("bN0Lv");
        string out;
        if (print_version)
            out = "version 2.0\n";
        for (string param: p.params()) {
            s_of f = p.fopen(param, "r");
            if (f.file > 0) {
                s_stat st;
                st.stt(f.attr);
                (, uint16 st_ino, , , , , uint16 st_rdev, uint32 st_size, , , , ) = st.unpack();
                if (!brief_mode)
                    out.append(str.oaif(param, add_null, "\x00") + str.oaif(": ", !dont_pad, "\t"));
                if (st.is_reg())
                    out.append(st_size == 0 ? "empty" : st_size == 1 ? "very short file (no magic)" : "ASCII text");
                else
                    out.append(st.type_long());
                if (st.is_char_dev() || st.is_block_dev())
                        out.append(format(" ({}/{})", libstat.major(st_rdev), libstat.minor(st_rdev)));
                if (st.is_symlink() && !follow_symlinks) {
                    (, string target, ) = udirent.get_symlink_target(inodes[st_ino], data[st_ino]).unpack();
                    out.append(" to " + target);
                }
                out.append("\n");
            } else
                p.perror(param + ": cannot open");
        }
        p.puts(out);
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
"0.02");
    }

}
