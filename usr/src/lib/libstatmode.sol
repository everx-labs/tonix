pragma ton-solidity >= 0.58.0;

import "utypes.sol";

library libstatmode {
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

    function mode_to_file_type(uint16 imode) internal returns (uint8 t) {
        (t, , , , , ) = mode(imode);
    }

    function sign(uint16 imode) internal returns (byte c) {
        (, , c, , , ) = mode(imode);
    }

    function mode(uint16 imode) internal returns (uint8, vtype, byte, string, string, uint16) {
        uint16 m = imode & S_IFMT;
        if (m == S_IFBLK) return (FT_BLKDEV,   vtype.VBLK,  'b', "BLK", "block special", DEF_BLOCK_DEV_MODE);
        if (m == S_IFCHR) return (FT_CHRDEV,   vtype.VCHR,  'c', "CHR", "character special", DEF_CHAR_DEV_MODE);
        if (m == S_IFREG) return (FT_REG_FILE, vtype.VREG,  '-', "REG", "regular file", DEF_REG_FILE_MODE);
        if (m == S_IFDIR) return (FT_DIR,      vtype.VDIR,  'd', "DIR", "directory", DEF_DIR_MODE);
        if (m == S_IFLNK) return (FT_SYMLINK,  vtype.VLNK,  'l', "symbolic link", "symbolic link", DEF_SYMLINK_MODE);
        if (m == S_IFSOCK)return (FT_SOCK,     vtype.VSOCK, 's', "socket", "socket", DEF_SOCK_MODE);
        if (m == S_IFIFO) return (FT_FIFO,     vtype.VFIFO, 'p', "FIFO", "fifo", DEF_FIFO_MODE);
        return                   (FT_UNKNOWN,  vtype.VBAD,  '?', "", "", 0);
    }

    function is_block_dev(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFBLK;
    }

    function is_char_dev(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFCHR;
    }

    function is_reg(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFREG;
    }

    function is_dir(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFDIR;
    }

    function is_symlink(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFLNK;
    }

    function is_socket(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFSOCK;
    }

    function is_pipe(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFIFO;
    }

    function is_gid(uint16 imode) internal returns (bool) {
        return (imode & S_ISGID) > 0;
    }

    function is_uid(uint16 imode) internal returns (bool) {
        return (imode & S_ISUID) > 0;
    }

    function is_vtx(uint16 imode) internal returns (bool) {
        return (imode & S_ISVTX) > 0;
    }

    function file_type_description(uint16 imode) internal returns (string desc) {
        (, , , , desc, ) = mode(imode);
    }

    function ft_desc(uint16 imode) internal returns (string short) {
        (, , , short, , ) = mode(imode);
    }

    function def_mode(uint16 imode) internal returns (uint16 dm) {
        (, , , , , dm) = mode(imode);
    }

    function perm_string(uint16 p) internal returns (string) {
        return sign(p) + poctet(p >> 6 & 0x0007) + poctet(p >> 3 & 0x0007) + poctet(p & 0x0007);
    }

    function poctal(uint16 p) internal returns (string) {
        return format("{}{}{}", p >> 6 & 0x0007, p >> 3 & 0x0007, p & 0x0007);
    }

    function poctet(uint16 p) internal returns (string out) {
        out = (p & 4) > 0 ? "r" : "-";
        out.append((p & 2) > 0 ? "w" : "-");
        out.append((p & 1) > 0 ? "x" : "-");
    }

}