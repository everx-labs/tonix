pragma ton-solidity >= 0.67.0;
import "fs.h";

library libfattr {
    uint8 constant FT_UNK  = 0;
    uint8 constant FT_REG  = 1;
    uint8 constant FT_DIR  = 2;
    uint8 constant FT_CHR  = 3;
    uint8 constant FT_BLK  = 4;
    uint8 constant FT_FIFO = 5;
    uint8 constant FT_SOCK = 6;
    uint8 constant FT_LINK = 7;
    uint8 constant FT_INO  = 8;
    uint8 constant FT_WHT  = 9;
    uint8 constant FT_LAST = FT_WHT;
    string[10] constant FTS = ["unknown", "REG", "DIR", "CHR", "BLK", "FIFO", "unix", "a_inode", "WHT"];
    uint8[9] constant MTT = [FT_UNK, FT_CHR, FT_DIR, FT_BLK, FT_REG, FT_LINK, FT_SOCK, FT_INO, FT_WHT ];
    uint16 constant UID_ROOT	= 0;
    uint16 constant GID_WHEEL	= 0;
    uint16 constant S_IFMT	= 0xF000;// 0170000; // type of file mask
    uint16 constant S_IFIFO	= 0x1000;// 0010000; // named pipe (fifo)
    uint16 constant S_IFCHR	= 0x2000;// 0020000; // character special
    uint16 constant S_IFDIR	= 0x4000;// 0040000; // directory
    uint16 constant S_IFBLK	= 0x6000;// 0060000; // block special
    uint16 constant S_IFREG	= 0x8000;// 0100000; // regular
    uint16 constant S_IFLNK	= 0xA000;// 0120000; // symbolic link
    uint16 constant S_IFSOCK = 0xC000;// 0140000; // socket
    uint16 constant S_ISVTX	= 0x0200;// 0001000; // save swapped text even after use
    uint16 constant S_IFWHT = 0xE000;// 0160000; // whiteout
    uint8 constant BLK_SIZE = 127;
    string[10] constant FTL = ["?", "-", "d", "c", "b", "p", "s", "l", "i", "w"];
    function makedev(uint major, uint minor) internal returns (uint16) {
        return uint16((major << 8) + minor);
    }
    function print_mode(uint16 mode) internal returns (string out) {
        uint16 masked = (mode & S_IFMT) >> 12;
        uint8 fifo = uint8(masked) % 2;
        uint8 idx = uint8(masked >> 1);
        uint8 ft = MTT[idx];
        string s = FTS[ft];
        out.append(format("mode: {} masked: {} fifo: {} idx: {} ft: {} str: {}\n", mode, masked, fifo, idx, ft, s));
    }
    function print_idirent(idirent de) internal returns (string) {
        (uint8 ft, uint16 inode, , bytes11 name) = de.unpack();
        bytes bn = bytes(name);
//        string s = nl < 11 ? bn[ : nl] : bn;
//        s;
        return format("{}{}\t{}\n", FTL[ft], bn, inode);
    }
    function print_stat(stat s) internal returns (string) {
        (uint16 st_dev, uint16 st_ino, uint16 st_nlink, uint16 st_mode, uint16 st_uid, uint16 st_gid, uint16 st_rdev, uint32 st_atim, uint32 st_mtim, uint32 st_ctim, uint32 st_birthtim, uint32 st_size, uint16 st_blocks, uint16 st_blksize, uint16 st_gen) = s.unpack();
        return format("D {} I {} N {} M {} U {} G {} R {} A {} M {} C {} B {} S {} NB {} BS {} GN {}\n",
            st_dev, st_ino, st_nlink, st_mode, st_uid, st_gid, st_rdev, st_atim, st_mtim, st_ctim, st_birthtim, st_size, st_blocks, st_blksize, st_gen);
    }
    function set_time(stat st) internal {
        uint32 tnow = block.timestamp;
        st.st_atim = tnow;
        st.st_mtim = tnow;
        st.st_ctim = tnow;
        st.st_birthtim = tnow;
    }
    function update_size(stat st, uint sz) internal {
        uint32 tnow = block.timestamp;
        st.st_size = uint32(sz);
        st.st_blocks = uint16(sz / st.st_blksize) + 1;
        st.st_mtim = tnow;
        st.st_ctim = tnow;
        st.st_gen++;
    }
    function def_bdev_inode(uint16 dev_id, uint16 blk_size) internal returns (stat st) {
        uint32 tnow = block.timestamp;
        return stat(dev_id, 0, 1, S_IFBLK, UID_ROOT, GID_WHEEL, 0, tnow, tnow, tnow, tnow, 0, 1, blk_size, 0);
    }
    function def_dir_inode(stat stb) internal returns (stat st) {
        (, , , uint16 st_mode, uint16 st_uid, uint16 st_gid, uint16 st_rdev, , , , , , , uint16 st_blksize, ) = stb.unpack();
        uint32 tnow = block.timestamp;
        if ((st_mode & S_IFBLK) == S_IFBLK)
            return stat(st_rdev, 0, 2, S_IFDIR, st_uid, st_gid, 0, tnow, tnow, tnow, tnow, 0, 2, st_blksize, 0);
    }
}