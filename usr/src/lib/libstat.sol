pragma ton-solidity >= 0.58.0;

import "libstatmode.sol";
import "utypes.sol";

library libstat {

    using libstatmode for uint16;

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;
    uint8 constant FT_LAST      = FT_SYMLINK;

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

    function att(s_stat st) internal returns (uint) {
        (uint16 st_dev, uint16 st_ino, uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, uint16 st_rdev, uint32 st_size, uint16 st_blksize,
            uint16 st_blocks, uint32 st_mtim, uint32 st_ctim) = st.unpack();
        return (uint(st_dev) << 224) + (uint(st_ino) << 208) + (uint(st_mode) << 192) + (uint(st_nlink) << 176) + (uint(st_uid) << 160) + (uint(st_gid) << 144) +
            (uint(st_rdev) << 128) + (uint(st_size) << 96) + (uint(st_blksize) << 80) + (uint(st_blocks) << 64) + (uint(st_mtim) << 32) + st_ctim;
    }

    function stt(s_stat st, uint val) internal {
        (uint16 st_dev, uint16 st_ino, uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, uint16 st_rdev, uint32 st_size, uint16 st_blksize,
            uint16 st_blocks, uint32 st_mtim, uint32 st_ctim) = (uint16(val >> 224 & 0xFFFF), uint16(val >> 208 & 0xFFFF), uint16(val >> 192 & 0xFFFF),
                uint16(val >> 176 & 0xFFFF), uint16(val >> 160 & 0xFFFF), uint16(val >> 144 & 0xFFFF), uint16(val >> 128 & 0xFFFF), uint32(val >> 96 & 0xFFFFFFFF),
                uint16(val >> 80 & 0xFFFF), uint16(val >> 64 & 0xFFFF), uint32(val >> 32 & 0xFFFFFFFF), uint32(val & 0xFFFFFFFF));
        st = s_stat(st_dev, st_ino, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_mtim, st_ctim);
    }

    function makedev(uint8 major, uint8 minor) internal returns (uint16) {
        return uint16(major << 8) + minor;
    }

    function major(uint16 dev) internal returns (uint8) {
        return uint8(dev >> 8);
    }

    function minor(uint16 dev) internal returns (uint8) {
        return uint8(dev & 0xFF);
    }

    function file_type(s_stat st) internal returns (uint8 ft) {
        return st.st_mode.mode_to_file_type();
//        (ft, , , , , ) = st.st_mode.mode();
    }

    function vnode_type(s_stat st) internal returns (vtype vt) {
        (, vt, , , , ) = st.st_mode.mode();
    }

    function sign(s_stat st) internal returns (byte c) {
        return st.st_mode.sign();
    }

    function is_block_dev(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFBLK;
    }

    function is_char_dev(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFCHR;
    }

    function is_reg(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFREG;
    }

    function is_dir(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFDIR;
    }

    function is_symlink(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFLNK;
    }

    function is_socket(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFSOCK;
    }

    function is_pipe(s_stat st) internal returns (bool) {
        return (st.st_mode & S_IFMT) == S_IFIFO;
    }

    function is_gid(s_stat st) internal returns (bool) {
        return (st.st_mode & S_ISGID) > 0;
    }

    function is_uid(s_stat st) internal returns (bool) {
        return (st.st_mode & S_ISUID) > 0;
    }

    function is_vtx(s_stat st) internal returns (bool) {
        return (st.st_mode & S_ISVTX) > 0;
    }

    function type_long(s_stat st) internal returns (string) {
        return st.st_mode.file_type_description();
        /*uint16 m = st.st_mode & S_IFMT;
        if (m == S_IFBLK) return "block special file";
        if (m == S_IFCHR) return "character special file";
        if (m == S_IFREG) return "regular file";
        if (m == S_IFDIR) return "directory";
        if (m == S_IFLNK) return "symbolic link";
        if (m == S_IFSOCK) return "socket";
        if (m == S_IFIFO) return "fifo";
        return "unknown";*/
    }

    function type_short(s_stat st) internal returns (string short) {
        return st.st_mode.ft_desc();
    }

    function set_def_mode(s_stat st) internal {
        uint16 m = st.st_mode & S_IFMT;
        if (m == S_IFREG) st.st_mode = DEF_REG_FILE_MODE;
        if (m == S_IFDIR) st.st_mode = DEF_DIR_MODE;
        if (m == S_IFLNK) st.st_mode = DEF_SYMLINK_MODE;
        if (m == S_IFBLK) st.st_mode = DEF_BLOCK_DEV_MODE;
        if (m == S_IFCHR) st.st_mode = DEF_CHAR_DEV_MODE;
        if (m == S_IFIFO) st.st_mode = DEF_FIFO_MODE;
        if (m == S_IFSOCK) st.st_mode = DEF_SOCK_MODE;
    }

}