pragma ton-solidity >= 0.61.0;

import "putil.sol";
//import "../lib/parg.sol";
import "../lib/libstat.sol";
import "../lib/ft.sol";

contract lsof is putil {

    using libstat for s_stat;
//    using parg for s_proc;

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;
        (bool ppid, bool fsize, bool foffset, bool numuid) = p.flags_set("Rsol");
        (mapping (uint16 => string) user, ) = p.get_users_groups();
        (, s_xfiledesc p_fd, , , , uint16 p_pid, uint16 p_oppid, string p_comm, , , , , , ) = p.unpack();
        string out;
        out.append("COMMAND\tPID\tPPID\tUSER\tFD\tTYPE\tDEVICE\tSIZE/OFF\tNODE\tNAME\n");
        s_of[] fds = p_fd.fdt_ofiles;
        for (s_of f: fds) {
            (uint attr, uint16 flags, uint16 file, string path, uint32 offset, ) = f.unpack();
            s_stat st;
            st.stt(attr);
            (uint16 st_dev, uint16 st_ino, uint16 st_mode, /*uint16 st_nlink*/, uint16 st_uid, /*uint16 st_gid*/, , uint32 st_size,
                , , , ) = st.unpack();
            string sm = (flags & io.SRD) > 0 ? "r" : (flags & io.SWR) > 0 ? "w" : (flags & io.SRW) > 0 ? "rw" : "?";
            uint32 sizoff = fsize ? st_size : foffset ? offset : st_size;
            out.append(format("{}\t{}\t{}\t{}\t{}{}\t{}\t{},{}\t{}\t{}\t{}\n", p_comm, p_pid, ppid ? str.toa(p_oppid) : "", numuid ? str.toa(st_uid) : user[st_uid], file, sm, ft.ft_desc(st_mode),
                st_dev >> 8, st_dev & 0xFF, sizoff, st_ino, path));
        }
        p.puts(out);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"lsof",
"[ -?abChlnNOPRtUvVX ] [ -A A ] [ -c c ] [ +c c ] [ +|-d d ] [ +|-D D ] [ +|-e s ] [ +|-E ] [ +|-f [cfgGn] ] [ -F [f] ] [ -g [s] ] [ -i [i] ] [ -k k ] [ -K k ] [ +|-L [l] ] [ +|-m m ] [ +|-M ] [ -o [o] ] [ -p s ] [ +|-r [t[m<fmt>]] ] [ -s [p:s] ] [ -S [t] ] [ -T [t] ] [ -u s ] [ +|-w ] [ -x [fl] ] [ -z [z] ] [ -Z [Z] ] [ -- ] [names]",
"list open files",
"Lists on its standard output file information about files opened by processes.\n\n\
An open file may be a regular file, a directory, a block special file, a character special file, an executing text reference, a library,\n\
a stream or a network file.  A specific file or all the files in a file system may be selected by path.",
"-R     list paRent PID\n\
-s      list file size\n\
-o      list file offset\n\
-l      list UID numbers",
"In the absence of any options, lsof lists all open files belonging to all active processes.",
"Written by Boris",
"attributes are not yet supported",
"",
"0.01");
    }

}
