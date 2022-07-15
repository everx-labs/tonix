pragma ton-solidity >= 0.62.0;
import "filedesc_h.sol";
import "libstat.sol";
import "io.sol";
contract tfiledesc  {


    function print_fdt(s_of[] files) internal pure returns (string out) {
        //string[][] table = [["users", "uid", "ruid", "svuid", "ngroups", "rgid", "svgid", "loginclass", "flags", "groups"]];
        out.append("COMMAND\tPID\tPPID\tUSER\tFD\tTYPE\tDEVICE\tSIZE/OFF\tNODE\tNAME\n");
        for (s_of f: files) {
            (uint attr, uint16 flags, uint16 file, string path, , ) = f.unpack();
            (uint16 st_dev, uint16 st_ino, uint16 st_mode, /*uint16 st_nlink*/, uint16 st_uid, /*uint16 st_gid*/, , uint32 st_size,
                , , , ) = libstat.st_attrs(attr);
            string sm = (flags & io.SRD) > 0 ? "r" : (flags & io.SWR) > 0 ? "w" : (flags & io.SRW) > 0 ? "rw" : "?";
            uint32 sizoff = st_size;
            out.append(format("{}\t{}\t{}\t{}\t{}{}\t{}\t{},{}\t{}\t{}\t{}\n", "", 0, 0 , str.toa(st_uid), file, sm, libstat.ft_desc(st_mode),
                st_dev >> 8, st_dev & 0xFF, sizoff, st_ino, path));
        }
    }
}