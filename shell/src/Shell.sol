pragma ton-solidity >= 0.56.0;

import "../include/Internal.sol";
import "../lib/stdio.sol";
import "../lib/vars.sol";
import "../lib/arg.sol";

struct BuiltinHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string arguments;
    string exit_status;
}

struct CommandHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string notes;
    string author;
    string bugs;
    string see_also;
    string version;
}

abstract contract Shell is Internal {

//    uint8 constant EPERM   = 1;  // Operation not permitted
//    uint8 constant ENOENT  = 2;  // No such file or directory
    uint8 constant ESRCH   = 3;  // No such process
    uint8 constant EINTR   = 4;  // Interrupted system call
    uint8 constant EIO     = 5;  // I/O error
    uint8 constant ENXIO   = 6;  // No such device or address
    uint8 constant E2BIG   = 7;  // Argument list too long
    uint8 constant ENOEXEC = 8;  // Exec format error
//    uint8 constant EBADF   = 9;  // Bad file number
    uint8 constant ECHILD  = 10; // No child processes
    uint8 constant EAGAIN  = 11; // Try again
    uint8 constant ENOMEM  = 12; // Out of memory
//    uint8 constant EACCES  = 13; // Permission denied
//    uint8 constant EFAULT  = 14; // Bad address
    uint8 constant ENOTBLK = 15; // Block device required
//    uint8 constant EBUSY   = 16; // Device or resource busy
//    uint8 constant EEXIST  = 17; // File exists
    uint8 constant EXDEV   = 18; // Cross-device link
    uint8 constant ENODEV  = 19; // No such device
//    uint8 constant ENOTDIR = 20; // Not a directory
//    uint8 constant EISDIR  = 21; // Is a directory
//    uint8 constant EINVAL  = 22; // Invalid argument
    uint8 constant ENFILE  = 23; // File table overflow
    uint8 constant EMFILE  = 24; // Too many open files
    uint8 constant ENOTTY  = 25; // Not a typewriter
    uint8 constant ETXTBSY = 26; // Text file busy
    uint8 constant EFBIG   = 27; // File too large
    uint8 constant ENOSPC  = 28; // No space left on device
    uint8 constant ESPIPE  = 29; // Illegal seek
//    uint8 constant EROFS   = 30; // Read-only file system
    uint8 constant EMLINK  = 31; // Too many links
    uint8 constant EPIPE   = 32; // Broken pipe
    uint8 constant EDOM    = 33; // Math argument out of domain of func
    uint8 constant ERANGE  = 34; // Math result not representable

    uint16 constant TYPE_STRING          = 0;
    uint16 constant TYPE_INDEXED_ARRAY   = 1;
    uint16 constant TYPE_HASHMAP         = 2;
    uint16 constant TYPE_FUNCTION        = 3;

    uint16 constant O_RDONLY    = 0;
    uint16 constant O_WRONLY    = 1;
    uint16 constant O_RDWR      = 2;
    uint16 constant O_ACCMODE   = 3;
    uint16 constant O_LARGEFILE = 16;
    uint16 constant O_DIRECTORY = 32;   // must be a directory
    uint16 constant O_NOFOLLOW  = 64;   // don't follow links
    uint16 constant O_CLOEXEC   = 128;  // set close_on_exec
    uint16 constant O_CREAT     = 256;
    uint16 constant O_EXCL      = 512;
    uint16 constant O_NOCTTY    = 1024;
    uint16 constant O_TRUNC     = 2048;
    uint16 constant O_APPEND    = 4096;
    uint16 constant O_NONBLOCK  = 8192;
    uint16 constant O_DSYNC     = 16384;
    uint16 constant FASYNC      = 32768;

    int8 constant NO_PIPE = 1;
    int8 constant REDIRECT_BOTH = -2;

    int8 constant NO_VARIABLE = -1;

    // Special exit statuses used by the shell, internally and externally
    uint8 constant EX_BINARY_FILE   = 126;
    uint8 constant EX_NOEXEC        = 127;
    uint8 constant EX_NOINPUT       = 128;
    uint8 constant EX_NOTFOUND      = 129;
    uint8 constant EX_SHERRBASE     = 192;	//all special error values are > this
    uint8 constant EX_BADSYNTAX     = 193;	// shell syntax error
    uint8 constant EX_USAGE         = 194;	// syntax error in usage
    uint8 constant EX_REDIRFAIL     = 195;	// redirection failed
    uint8 constant EX_BADASSIGN     = 196;	// variable assignment error
    uint8 constant EX_EXPFAIL       = 197;	// word expansion failed

    string constant FLAG_ON = '-';
    string constant FLAG_OFF = '+';

    function builtin_help() external pure returns (BuiltinHelp bh) {
        return _builtin_help();
    }

    function _builtin_help() internal pure virtual returns (BuiltinHelp bh);
}
