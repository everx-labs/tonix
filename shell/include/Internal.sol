pragma ton-solidity >= 0.55.0;

import "Base.sol";
//import "fs_types.sol";
import "../lib/fmt.sol";
import "../lib/dirent.sol";
import "../lib/sb.sol";
import "../lib/inode.sol";
import "../lib/fs.sol";

/* Base contract to work with index nodes */
abstract contract Internal is Base {

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

    uint8 constant TF_REG_FILE  = 0;
    uint8 constant TF_HARDLINK  = 1;
    uint8 constant TF_SYMLINK   = 2;
    uint8 constant TF_CHRDEV    = 3;
    uint8 constant TF_BLKDEV    = 4;
    uint8 constant TF_DIR       = 5;
    uint8 constant TF_FIFO      = 6;
    uint8 constant TF_SOCK      = 7;

    uint16 constant MOUNT_NONE          = 0;
    uint16 constant MOUNT_DIR           = 1;
    uint16 constant MOUNT_OVERLAY       = 4;
    uint16 constant QUERY_FS_CACHE      = 5;

    uint16 constant UAO_SYSTEM              = 16;
    uint16 constant UAO_CREATE_HOME_DIR     = 32;
    uint16 constant UAO_CREATE_USER_GROUP   = 64;
    uint16 constant UAO_ADD_SUPP_GROUPS     = 128;
    uint16 constant UAO_REMOVE_HOME_DIR     = 1024;
    uint16 constant UAO_REMOVE_EMPTY_GROUPS = 2048;

    uint8 constant AE_LOGIN         = 1;
    uint8 constant AE_LOGOUT        = 2;
    uint8 constant AE_SHUTDOWN      = 3;

    uint16 constant DEF_BLOCK_SIZE = 100;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 60;
    uint16 constant MAX_BLOCKS = 4000;
    uint16 constant MAX_INODES = 600;

    uint16 constant CANON_NONE  = 0;
    uint16 constant CANON_MISS  = 1;
    uint16 constant CANON_DIRS  = 2;
    uint16 constant CANON_EXISTS = 3;
    uint16 constant EXPAND_SYMLINKS = 8;

    uint8 constant ENOENT       = 1; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST       = 2; // "File exists"
    uint8 constant ENOTDIR      = 3; //  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR       = 4; //"Is a directory"
    uint8 constant EACCES       = 5; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)
    uint8 constant ENOTEMPTY    = 6; // "Directory not empty"
    uint8 constant EPERM        = 7; // "Not owner"
    uint8 constant EINVAL       = 8; //"Invalid argument"
    uint8 constant EROFS        = 9; //"Read-only file system"
    uint8 constant EFAULT       = 10; //Bad address.
    uint8 constant EBADF        = 11; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY        = 12; // "Device busy"
    uint8 constant ENOSYS       = 13; // "Operation not applicable"
    uint8 constant ENAMETOOLONG = 14; // pathname is too long.

    uint8 constant ERR_MSG              = 0;
    uint8 constant invalid_option       = 7;
    uint8 constant extra_operand        = 8;
    uint8 constant missing_file_operand = 11;
    uint8 constant invalid_mode         = 15;
    uint8 constant invalid_owner        = 16;
    uint8 constant try_help_for_info    = 21;
    uint8 constant omitting_directory   = 23;
    uint8 constant cant_overwrite_dir   = 24;
    uint8 constant command_not_found    = 25;
    uint8 constant options_l_s_incompat = 26;
    uint8 constant ln_target            = 27;
    uint8 constant failed_symlink       = 28;
    uint8 constant failed_hardlink      = 29;
    uint8 constant hard_or_symlink      = 30;
    uint8 constant no_hardlink_on_dir   = 31;
    uint8 constant mutually_exclusive_options = 32;
    uint8 constant login_data_not_found = 33;
    uint8 constant not_a_block_device   = 34;

    uint constant _0 = 1 << 48;
    uint constant _1 = 1 << 49;
    uint constant _2 = 1 << 50;
    uint constant _3 = 1 << 51;
    uint constant _4 = 1 << 52;
    uint constant _5 = 1 << 53;
    uint constant _6 = 1 << 54;
    uint constant _7 = 1 << 55;
    uint constant _8 = 1 << 56;
    uint constant _9 = 1 << 57;

    uint constant _A = 1 << 65;
    uint constant _B = 1 << 66;
    uint constant _C = 1 << 67;
    uint constant _D = 1 << 68;
    uint constant _E = 1 << 69;
    uint constant _F = 1 << 70;
    uint constant _G = 1 << 71;
    uint constant _H = 1 << 72;
    uint constant _I = 1 << 73;
    uint constant _J = 1 << 74;
    uint constant _K = 1 << 75;
    uint constant _L = 1 << 76;
    uint constant _M = 1 << 77;
    uint constant _N = 1 << 78;
    uint constant _O = 1 << 79;
    uint constant _P = 1 << 80;
    uint constant _Q = 1 << 81;
    uint constant _R = 1 << 82;
    uint constant _S = 1 << 83;
    uint constant _T = 1 << 84;
    uint constant _U = 1 << 85;
    uint constant _V = 1 << 86;
    uint constant _W = 1 << 87;
    uint constant _X = 1 << 88;
    uint constant _Y = 1 << 89;
    uint constant _Z = 1 << 90;

    uint constant _a = 1 << 97;
    uint constant _b = 1 << 98;
    uint constant _c = 1 << 99;
    uint constant _d = 1 << 100;
    uint constant _e = 1 << 101;
    uint constant _f = 1 << 102;
    uint constant _g = 1 << 103;
    uint constant _h = 1 << 104;
    uint constant _i = 1 << 105;
    uint constant _j = 1 << 106;
    uint constant _k = 1 << 107;
    uint constant _l = 1 << 108;
    uint constant _m = 1 << 109;
    uint constant _n = 1 << 110;
    uint constant _o = 1 << 111;
    uint constant _p = 1 << 112;
    uint constant _q = 1 << 113;
    uint constant _r = 1 << 114;
    uint constant _s = 1 << 115;
    uint constant _t = 1 << 116;
    uint constant _u = 1 << 117;
    uint constant _v = 1 << 118;
    uint constant _w = 1 << 119;
    uint constant _x = 1 << 120;
    uint constant _y = 1 << 121;
    uint constant _z = 1 << 122;

}
