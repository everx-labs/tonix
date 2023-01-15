pragma ton-solidity >= 0.62.0;
import "filedesc_h.sol";
import "libstat.sol";
//import "io.sol";
import "Base.sol";
import "libshellenv.sol";
import "inode.sol";
contract tfiledesc is Base  {

    using libshellenv for shell_env;
    using libfdt for s_thread;
    function main(shell_env e_in, s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (shell_env e, s_proc p) {
        e = e_in;
        p = p_in;
        e.puts(inode.dumpfs(1 + 2 + 8 + 48, 2, inodes, data));
    }

    function populate_files(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (shell_env e) {
        e = e_in;
        for ((uint16 i, bytes b): data)
            if (!b.empty())
                e.environ[sh.FILE].push(vars.var_record("--", str.toa(i), b));
    }

    function populate_dirs(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (shell_env e) {
        e = e_in;
        for ((uint16 i, Inode ino): inodes)
            if (libstat.is_dir(ino.mode))
                e.environ[sh.DIRECTORY].push(vars.var_record("-d", str.toa(i), data[i]));
    }

    function print_fdt(s_of[] files) external pure returns (string out) {
        return _print_fdt(files);
    }
    function _print_fdt(s_of[] files) internal pure returns (string out) {
        //string[][] table = [["users", "uid", "ruid", "svuid", "ngroups", "rgid", "svgid", "loginclass", "flags", "groups"]];
        out.append("COMMAND\tPID\tPPID\tUSER\tFD\tTYPE\tDEVICE\tSIZE/OFF\tNODE\tNAME \n");
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