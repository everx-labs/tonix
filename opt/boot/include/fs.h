pragma ton-solidity >= 0.67.0;

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

uint16 constant UID_ROOT    = 0;
uint16 constant GID_WHEEL   = 0;
uint16 constant S_IFMT  = 0xF000;// 0170000; // type of file mask
uint16 constant S_IFIFO = 0x1000;// 0010000; // named pipe (fifo)
uint16 constant S_IFCHR = 0x2000;// 0020000; // character special
uint16 constant S_IFDIR = 0x4000;// 0040000; // directory
uint16 constant S_IFBLK = 0x6000;// 0060000; // block special
uint16 constant S_IFREG = 0x8000;// 0100000; // regular
uint16 constant S_IFLNK = 0xA000;// 0120000; // symbolic link
uint16 constant S_IFSOCK = 0xC000;// 0140000; // socket
//uint16 constant S_ISVTX = 0x0200;// 0001000; // save swapped text even after use
uint16 constant S_IFWHT = 0xE000;// 0160000; // whiteout
uint8 constant BLK_SIZE = 127;
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
uint16 constant DEF_REG_FILE_MODE  = S_IFREG + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
uint16 constant DEF_DIR_MODE       = S_IFDIR + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;
uint16 constant DEF_SYMLINK_MODE   = S_IFLNK + S_IRWXU + S_IRWXG + S_IRWXO;
uint16 constant DEF_BLOCK_DEV_MODE = S_IFBLK + S_IRUSR + S_IWUSR;
uint16 constant DEF_CHAR_DEV_MODE  = S_IFCHR + S_IRUSR + S_IWUSR;
uint16 constant DEF_FIFO_MODE      = S_IFIFO + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
uint16 constant DEF_SOCK_MODE      = S_IFSOCK + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;

struct stat {
    uint16 st_dev;      // inode's device
    uint16 st_ino;      // inode's number
    uint16 st_nlink;    // number of hard links
    uint16 st_mode;     // inode protection mode
    uint16 st_uid;      // user ID of the file's owner
    uint16 st_gid;      // group ID of the file's group
    uint16 st_rdev;     // device type
    uint32 st_atim;     // time of last access
    uint32 st_mtim;     // time of last data modification
    uint32 st_ctim;     // time of last file status change
    uint32 st_birthtim; // time of file creation
    uint32 st_size;     // file size, in bytes
    uint16 st_blocks;   // blocks allocated for file
    uint16 st_blksize;  // optimal blocksize for I/O
    uint16 st_gen;      // file generation number
}
struct idirent {
    uint8 ft;
    uint16 inode;
    uint8 nl;
    bytes11 name;
}
struct dinode { // 4 x 4 + 6 x 2 + 3 = 31
    uint16 di_mode;  // IFMT, permissions; see below
    uint8 di_ino;    // Inode no
    uint8 di_nlink;  // File link count
    uint16 di_size;  // File byte count
    uint32 di_mtime; // Last modified time
    uint32 di_ctime; // Last inode change time
    uint32 di_atime; // Birth time
    uint16 di_db1;
    uint16 di_db2;
    uint16 di_flags; // Status flags (chflags)
    uint8 di_blocks; // Blocks actually held
    uint8 di_gen;    // Generation number
    uint16 di_uid;   // File owner
    uint16 di_gid;   // File group
    uint8 padding;   // padding to 31
}
struct file { // 1 x 2 + 5 = 7
    uint8 f_flag;   // see fcntl.h
    uint8 f_count;  // reference count
    uint8 f_data;   // file descriptor specific data
    uint8 f_vnode;  // NULL or applicable vnode
    uint8 f_type;   // descriptor type
    uint16 f_offset;// DFLAG_SEEKABLE specific fields
}
struct fdescenttbl {
    uint8 fdt_nfiles;   // number of open files allocated
    file[] fdt_ofiles;  // open files
}
struct filedesc {
    uint8 fd_files;     // open files table // fdescenttbl
    uint32 fd_map;      // bitmap of free fds
    uint8 fd_freefile;  // approx. next free file
}
struct pwd {
    dinode pwd_cdir;    // current directory
    dinode pwd_rdir;    // root directory
}

//function S_ISDIR(uint16 mode) returns (bool) {
//    return (mode & S_IFDIR) == S_IFDIR;
//}

library libfs {
    function S_ISDIR(uint16 mode) internal returns (bool) {
        return (mode & S_IFDIR) == S_IFDIR;
    }
}
