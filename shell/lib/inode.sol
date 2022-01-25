pragma ton-solidity >= 0.56.0;

import "../include/fs_types.sol";
import "fmt.sol";
import "dirent.sol";

library inode {

    uint16 constant S_IXOTH = 1 << 0;
    uint16 constant S_IWOTH = 1 << 1;
    uint16 constant S_IROTH = 1 << 2;
    uint16 constant S_IRWXO = S_IROTH + S_IWOTH + S_IXOTH;

    uint16 constant S_IXGRP = 1 << 3;
    uint16 constant S_IWGRP = 1 << 4;
    uint16 constant S_IRGRP = 1 << 5;
    uint16 constant S_IRWXG = S_IRGRP + S_IWGRP + S_IXGRP;

    uint16 constant S_IXUSR = 1 << 6;
    uint16 constant S_IWUSR = 1 << 7;
    uint16 constant S_IRUSR = 1 << 8;
    uint16 constant S_IRWXU = S_IRUSR + S_IWUSR + S_IXUSR;

    uint16 constant S_ISVTX = 1 << 9;  //   sticky bit
    uint16 constant S_ISGID = 1 << 10; //   set-group-ID bit
    uint16 constant S_ISUID = 1 << 11; //   set-user-ID bit

    uint16 constant S_IFIFO = 1 << 12;
    uint16 constant S_IFCHR = 1 << 13;
    uint16 constant S_IFDIR = 1 << 14;
    uint16 constant S_IFBLK = S_IFDIR + S_IFCHR;
    uint16 constant S_IFREG = 1 << 15;
    uint16 constant S_IFLNK = S_IFREG + S_IFCHR;
    uint16 constant S_IFSOCK = S_IFREG + S_IFDIR;
    uint16 constant S_IFMT  = 0xF000; //   bit mask for the file type bit field

    uint16 constant DEF_REG_FILE_MODE   = S_IFREG + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_DIR_MODE        = S_IFDIR + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;
    uint16 constant DEF_SYMLINK_MODE    = S_IFLNK + S_IRWXU + S_IRWXG + S_IRWXO;
    uint16 constant DEF_BLOCK_DEV_MODE  = S_IFBLK + S_IRUSR + S_IWUSR;
    uint16 constant DEF_CHAR_DEV_MODE   = S_IFCHR + S_IRUSR + S_IWUSR;
    uint16 constant DEF_FIFO_MODE       = S_IFIFO + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_SOCK_MODE       = S_IFSOCK + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;
    uint8 constant FT_LAST      = FT_SYMLINK;

    /* Index node, file and directory entry types helpers */
    function get_device_version(uint16 device_id) internal returns (string major, string minor) {
        return (format("{}", device_id >> 8), format("{}", device_id & 0xFF));
    }

    function permissions(uint16 p) internal returns (string) {
        return inode_mode_sign(p) + permissions_octet(p >> 6 & 0x0007) + permissions_octet(p >> 3 & 0x0007) + permissions_octet(p & 0x0007);
    }

    function permissions_octal(uint16 p) internal returns (string) {
        return format("{}{}{}", p >> 6 & 0x0007, p >> 3 & 0x0007, p & 0x0007);
    }

    function mode(string s) internal returns (uint16 imode) {
        imode = get_def_mode(dirent.file_type(s.substr(0, 1)));
        imode += string_to_octet(s.substr(1, 3)) << 6;
        imode += string_to_octet(s.substr(4, 3)) << 3;
        imode += string_to_octet(s.substr(7, 3));
    }

    function string_to_octet(string s) internal returns (uint16 p) {
        if (s.substr(0, 1) == "r")
            p += 4;
        if (s.substr(1, 1) == "w")
            p += 2;
        if (s.substr(2, 1) == "x")
            p++;
    }

    function permissions_octet(uint16 p) internal returns (string out) {
        out = ((p & 4) > 0) ? "r" : "-";
        out.append(((p & 2) > 0) ? "w" : "-");
        out.append(((p & 1) > 0) ? "x" : "-");
    }

    function inode_mode_sign(uint16 imode) internal returns (string) {
        if ((imode & S_IFMT) == S_IFBLK)  return "b";
        if ((imode & S_IFMT) == S_IFCHR)  return "c";
        if ((imode & S_IFMT) == S_IFREG)  return "-";
        if ((imode & S_IFMT) == S_IFDIR)  return "d";
        if ((imode & S_IFMT) == S_IFLNK)  return "l";
        if ((imode & S_IFMT) == S_IFSOCK) return "s";
        if ((imode & S_IFMT) == S_IFIFO)  return "p";
    }

    function mode_to_file_type(uint16 imode) internal returns (uint8) {
        if ((imode & S_IFMT) == S_IFBLK)  return FT_BLKDEV;
        if ((imode & S_IFMT) == S_IFCHR)  return FT_CHRDEV;
        if ((imode & S_IFMT) == S_IFREG)  return FT_REG_FILE;
        if ((imode & S_IFMT) == S_IFDIR)  return FT_DIR;
        if ((imode & S_IFMT) == S_IFLNK)  return FT_SYMLINK;
        if ((imode & S_IFMT) == S_IFSOCK) return FT_SOCK;
        if ((imode & S_IFMT) == S_IFIFO)  return FT_FIFO;
        return FT_UNKNOWN;
    }

    function file_type_description(uint16 imode) internal returns (string) {
        if ((imode & S_IFMT) == S_IFBLK)  return "block special";
        if ((imode & S_IFMT) == S_IFCHR)  return "character special";
        if ((imode & S_IFMT) == S_IFREG)  return "regular";
        if ((imode & S_IFMT) == S_IFDIR)  return "directory";
        if ((imode & S_IFMT) == S_IFLNK)  return "symbolic link";
        if ((imode & S_IFMT) == S_IFSOCK) return "socket";
        if ((imode & S_IFMT) == S_IFIFO)  return "fifo";
        return "unknown";
    }

    function get_def_mode(uint8 file_type) internal returns (uint16) {
        if (file_type == FT_REG_FILE) return DEF_REG_FILE_MODE;
        if (file_type == FT_DIR) return DEF_DIR_MODE;
        if (file_type == FT_SYMLINK) return DEF_SYMLINK_MODE;
        if (file_type == FT_BLKDEV) return DEF_BLOCK_DEV_MODE;
        if (file_type == FT_CHRDEV) return DEF_CHAR_DEV_MODE;
        if (file_type == FT_FIFO) return DEF_FIFO_MODE;
        if (file_type == FT_SOCK) return DEF_SOCK_MODE;
    }

    function get_any_node(uint8 ft, uint16 owner, uint16 group, uint16 device_id, uint16 n_blocks, string file_name, string text) internal returns (Inode, bytes) {
        if (ft > FT_UNKNOWN && ft <= FT_LAST)
            return (Inode(get_def_mode(ft), owner, group, ft == FT_DIR ? 2 : 1, device_id, n_blocks, uint32(text.byteLength()),  now, now, file_name), text);
    }

    /* Getting an index node of a particular type */
    function get_dots(uint16 this_dir, uint16 parent_dir) internal returns (string) {
        return format("d.\t{}\nd..\t{}\n", this_dir, parent_dir);
    }

    function get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, uint16 device_id, string dir_name) internal returns (Inode, bytes) {
        return get_any_node(FT_DIR, owner, group, device_id, 1, dir_name, get_dots(this_dir, parent_dir));
    }
}
