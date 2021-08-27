pragma ton-solidity >= 0.49.0;

abstract contract IStat {

    uint16 constant S_IXOTH = 1 << 0; //   others have execute permission
    uint16 constant S_IWOTH = 1 << 1; //   others have write permission
    uint16 constant S_IROTH = 1 << 2; //   others have read permission
    uint16 constant S_IRWXO = S_IROTH + S_IWOTH + S_IXOTH; //   others  (not  in group) have read, write, and execute permission

    uint16 constant S_IXGRP = 1 << 3; //   group has execute permission
    uint16 constant S_IWGRP = 1 << 4; //   group has write permission
    uint16 constant S_IRGRP = 1 << 5; //   group has read permission
    uint16 constant S_IRWXG = S_IRGRP + S_IWGRP + S_IXGRP; //   group has read, write, and execute permission

    uint16 constant S_IXUSR = 1 << 6; //   owner has execute permission
    uint16 constant S_IWUSR = 1 << 7; //   owner has write permission
    uint16 constant S_IRUSR = 1 << 8; //   owner has read permission
    uint16 constant S_IRWXU = S_IRUSR + S_IWUSR + S_IXUSR; //   owner has read, write, and execute permission

    uint16 constant S_ISVTX = 1 << 9; //   sticky bit (see below)
    uint16 constant S_ISGID = 1 << 10; //   set-group-ID bit (see below)
    uint16 constant S_ISUID = 1 << 11; //   set-user-ID bit (see execve(2))

    uint16 constant S_IFIFO = 1 << 12; //   FIFO
    uint16 constant S_IFCHR = 1 << 13; //   character device
    uint16 constant S_IFDIR = 1 << 14; //   directory
    uint16 constant S_IFBLK = S_IFDIR + S_IFCHR; //   block device
    uint16 constant S_IFREG = 1 << 15; //   regular file
    uint16 constant S_IFLNK = S_IFREG + S_IFCHR; //   symbolic link
    uint16 constant S_IFSOCK = S_IFREG + S_IFDIR; //   socket
    uint16 constant S_IFMT  = 0xF000; //   bit mask for the file type bit field

    uint16 constant DEF_REG_FILE_MODE   = S_IFREG + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_DIR_MODE        = S_IFDIR + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;
    uint16 constant DEF_SYMLINK_MODE    = S_IFLNK + S_IRWXU + S_IRWXG + S_IRWXO;
    uint16 constant DEF_BLOCK_DEV_MODE  = S_IFBLK + S_IRUSR + S_IWUSR;
    uint16 constant DEF_CHAR_DEV_MODE   = S_IFCHR + S_IRUSR + S_IWUSR;
    uint16 constant DEF_FIFO_MODE       = S_IFIFO + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_SOCK_MODE       = S_IFSOCK + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;

    uint16 constant STATX_TYPE  = 1 << 0; /* Want/got stx_mode & S_IFMT */
    uint16 constant STATX_MODE  = 1 << 1; /* Want/got stx_mode & ~S_IFMT */
    uint16 constant STATX_NLINK = 1 << 2; /* Want/got stx_nlink */
    uint16 constant STATX_UID   = 1 << 3; /* Want/got stx_uid */
    uint16 constant STATX_GID   = 1 << 4; /* Want/got stx_gid */
    uint16 constant STATX_ATIME = 1 << 5; /* Want/got stx_atime */
    uint16 constant STATX_MTIME = 1 << 6; /* Want/got stx_mtime */
    uint16 constant STATX_CTIME = 1 << 7; /* Want/got stx_ctime */
    uint16 constant STATX_INO   = 1 << 8; /* Want/got stx_ino */
    uint16 constant STATX_SIZE  = 1 << 9; /* Want/got stx_size */
    uint16 constant STATX_BLOCKS = 1 << 10; /* Want/got stx_blocks */
    uint16 constant STATX_BASIC_STATS = 0x07FF; /* The stuff in the normal stat struct */

    // correspond to generic FS_IOC_FLAGS semantically.
    uint16 constant STATX_ATTR_COMPRESSED   = 1 << 2; /* [I] File is compressed by the fs */
    uint16 constant STATX_ATTR_IMMUTABLE    = 1 << 4;  /* [I] File is marked immutable */
    uint16 constant STATX_ATTR_APPEND       = 1 << 5; /* [I] File is append-only */
    uint16 constant STATX_ATTR_NODUMP       = 1 << 6;  /* [I] File is not to be dumped */
    uint16 constant STATX_ATTR_ENCRYPTED    = 1 << 11; /* [I] File requires key to decrypt in fs */
    uint16 constant STATX_ATTR_AUTOMOUNT    = 1 << 12; /* Dir: Automount trigger */

}
