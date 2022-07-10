pragma ton-solidity >= 0.61.2;

import "libstatmode.sol";
import "utypes.sol";
import "libtable.sol";

library libstat {

    using libstatmode for uint16;
    using libstat for uint;

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

    uint16 constant S_ISVTX = 1 << 9;  // sticky bit
    uint16 constant S_ISGID = 1 << 10; // set-group-ID bit
    uint16 constant S_ISUID = 1 << 11; // set-user-ID bit

    uint16 constant S_IFIFO = 1 << 12;
    uint16 constant S_IFCHR = 1 << 13;
    uint16 constant S_IFDIR = 1 << 14;
    uint16 constant S_IFBLK = S_IFDIR + S_IFCHR;
    uint16 constant S_IFREG = 1 << 15;
    uint16 constant S_IFLNK = S_IFREG + S_IFCHR;
    uint16 constant S_IFSOCK = S_IFREG + S_IFDIR;
    uint16 constant S_IFMT  = 0xF000; //   bit mask for the file type bit field

    uint16 constant DEF_REG_FILE_MODE  = S_IFREG + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_DIR_MODE       = S_IFDIR + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;
    uint16 constant DEF_SYMLINK_MODE   = S_IFLNK + S_IRWXU + S_IRWXG + S_IRWXO;
    uint16 constant DEF_BLOCK_DEV_MODE = S_IFBLK + S_IRUSR + S_IWUSR;
    uint16 constant DEF_CHAR_DEV_MODE  = S_IFCHR + S_IRUSR + S_IWUSR;
    uint16 constant DEF_FIFO_MODE      = S_IFIFO + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_SOCK_MODE      = S_IFSOCK + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;

    uint constant INO_MASK = 0xFFFF << 224;
    uint constant MODE_MASK = 0xFFFF << 240;
    uint constant RDEV_MASK = 0xFFFF << 128;
    uint constant SIZE_MASK = 0xFFFFFFFF << 96;
    uint constant BLK_MASK = 0xFFFF << 64;
    uint constant TIME_MASK = (1 << 64) - 1;
//    uint constant INO_MASK = (1 << 224) - (1 << 208);
//    uint constant SIZE_MASK = (1 << 96) - (1 << 64);
//    uint constant TIME_MASK = (1 << 64) - 1;

    function att(s_stat st) internal returns (uint) {
        (uint st_dev, uint st_ino, uint st_mode, uint st_nlink, uint st_uid, uint st_gid, uint st_rdev, uint st_size, uint st_blksize,
            uint st_blocks, uint st_mtim, uint st_ctim) = st.unpack();
        return (st_dev << 224) + (st_ino << 208) + (st_mode << 192) + (st_nlink << 176) + (st_uid << 160) + (st_gid << 144) +
            (st_rdev << 128) + (st_size << 96) + (st_blksize << 80) + (st_blocks << 64) + (st_mtim << 32) + st_ctim;
    }

    function stt(s_stat st, uint val) internal {
        /*(uint16 st_dev, uint16 st_ino, uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, uint16 st_rdev, uint32 st_size, uint16 st_blksize,
            uint16 st_blocks, uint32 st_mtim, uint32 st_ctim) = (uint16(val >> 224 & 0xFFFF), uint16(val >> 208 & 0xFFFF), uint16(val >> 192 & 0xFFFF),
                uint16(val >> 176 & 0xFFFF), uint16(val >> 160 & 0xFFFF), uint16(val >> 144 & 0xFFFF), uint16(val >> 128 & 0xFFFF), uint32(val >> 96 & 0xFFFFFFFF),
                uint16(val >> 80 & 0xFFFF), uint16(val >> 64 & 0xFFFF), uint32(val >> 32 & 0xFFFFFFFF), uint32(val & 0xFFFFFFFF));
        st = s_stat(st_dev, st_ino, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_mtim, st_ctim);*/
        st = s_stat(uint16(val >> 224 & 0xFFFF), uint16(val >> 208 & 0xFFFF), uint16(val >> 192 & 0xFFFF), uint16(val >> 176 & 0xFFFF),
            uint16(val >> 160 & 0xFFFF), uint16(val >> 144 & 0xFFFF), uint16(val >> 128 & 0xFFFF), uint32(val >> 96 & 0xFFFFFFFF),
            uint16(val >> 80 & 0xFFFF), uint16(val >> 64 & 0xFFFF), uint32(val >> 32 & 0xFFFFFFFF), uint32(val & 0xFFFFFFFF));
    }

    function pack_attrs(uint st_dev, uint st_ino, uint st_mode, uint st_nlink, uint st_uid, uint st_gid, uint st_rdev, uint st_size, uint st_blksize,
        uint st_blocks, uint st_mtim, uint st_ctim) internal returns (uint) {
        return (st_dev << 224) + (st_ino << 208) + (st_mode << 192) + (st_nlink << 176) + (st_uid << 160) + (st_gid << 144) +
            (st_rdev << 128) + (st_size << 96) + (st_blksize << 80) + (st_blocks << 64) + (st_mtim << 32) + st_ctim;
    }

    function unpack_attrs(uint val) internal returns (uint st_dev, uint st_ino, uint st_mode, uint st_nlink, uint st_uid, uint st_gid, uint st_rdev, uint st_size, uint st_blksize,
        uint st_blocks, uint st_mtim, uint st_ctim) {
        (st_dev, st_ino, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_mtim, st_ctim) =
            (val >> 224 & 0xFFFF, val >> 208 & 0xFFFF, val >> 192 & 0xFFFF, val >> 176 & 0xFFFF, val >> 160 & 0xFFFF, val >> 144 & 0xFFFF,
            val >> 128 & 0xFFFF, val >> 96 & 0xFFFFFFFF, val >> 80 & 0xFFFF, val >> 64 & 0xFFFF, val >> 32 & 0xFFFFFFFF, val & 0xFFFFFFFF);
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

    function adjust(s_stat st, uint size) internal {
        st.st_size = uint32(size);
        st.st_blocks = uint16(size / st.st_blksize + 1);
        st.st_mtim = now;
        st.st_ctim = now;
    }

    function set_ino(uint st, uint val) internal {
//        uint prev = st >> 224 & 0xFFFF;
        st = (st & ~INO_MASK) | (val << 224 & INO_MASK);
    }

    function set_mode(uint st, uint t) internal {
//        uint prev = st >> 240 & 0xFFFF;
//        st = (prev & ~MODE_MASK) | (libstatmode.get_def_mode(t) << 240 & MODE_MASK);
        st = (st & ~MODE_MASK) | (libstatmode.get_def_mode(t) << 240 & MODE_MASK);
    }

    function set_rdev(uint st, uint val) internal {
//        uint prev = st >> 128 & 0xFFFF;
        st = st & ~RDEV_MASK;
        if (val > 0)
            st |= val << 128 & RDEV_MASK;
    }

    function set_size(uint st, uint val) internal {
//        uint prev = st >> 96 & 0xFFFFFFFF;
        st = (st & ~SIZE_MASK) | (val << 96 & SIZE_MASK);
    }

    function set_time(uint st, uint ts) internal {
        uint val = (ts << 32) + ts;
//        uint prev = st & TIME_MASK;
        st = (st & ~TIME_MASK) | (val & TIME_MASK);
    }

    function adjust_attrs(uint val, uint size) internal returns (uint) {
//        uint size_mask = 0xFFFFFFFF << 96;
//        uint val2 = (val & ~SIZE_MASK) | (size << 96 & SIZE_MASK);
        val.set_size(size);
//        st.st_size = uint32(size);
//        st.st_blocks = uint16(size / st.st_blksize + 1);
//        uint time_mask = 1 << 64 - 1;
//        uint new_time = now << 32 + now;
//        uint val3 = (val2 & ~TIME_MASK) | new_time;
        val.set_time(now);
//        return val3;
    }

    function as_row(uint st) internal returns (string[]) {
            (uint st_dev, uint st_ino, uint st_mode, uint st_nlink, uint st_uid, uint st_gid, uint st_rdev,
                 uint st_size, uint st_blksize, uint st_blocks, uint st_mtim, uint st_ctim) = unpack_attrs(st);
            return [str.toa(st_dev), str.toa(st_ino), str.toa(st_mode), str.toa(st_nlink), str.toa(st_uid), str.toa(st_gid),
                str.toa(st_rdev), str.toa(st_size), str.toa(st_blksize), str.toa(st_blocks), str.toa(st_mtim), str.toa(st_ctim)];
    }

    function format_index(uint[] index) internal returns (string) {
        string[][] table = [["Dev", "Ino", "Mode", "Ln", "UID", "GID", "rdev", "size", "blksz", "blk", "Modified", "Changed"]];
        for (uint attr: index)
            table.push(as_row(attr));
        /*for (uint attr: index) {
            (uint st_dev, uint st_ino, uint st_mode, uint st_nlink, uint st_uid, uint st_gid, uint st_rdev, uint st_size, uint st_blksize,
                uint st_blocks, uint st_mtim, uint st_ctim) = unpack_attrs(attr);
            table.push([str.toa(st_dev), str.toa(st_ino), str.toa(st_mode), str.toa(st_nlink), str.toa(st_uid), str.toa(st_gid), str.toa(st_rdev), str.toa(st_size), str.toa(st_blksize), str.toa(st_blocks), str.toa(st_mtim), str.toa(st_ctim)]);
        }*/
        return libtable.format_rows(table, [uint(4), 3, 5, 2, 5, 5, 4, 6, 5, 3, 8, 8], libtable.CENTER);
    }
}