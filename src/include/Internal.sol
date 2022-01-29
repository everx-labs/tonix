pragma ton-solidity >= 0.56.0;

import "Base.sol";
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

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;
    uint8 constant FT_LAST      = FT_SYMLINK;

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
    uint8 constant ENAMETOOLONG = 14; // pathname is too long.*/
}
