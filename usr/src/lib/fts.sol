pragma ton-solidity >= 0.58.0;

import "xio.sol";

struct s_fts {
    s_ftsent fts_cur;       // current node
    s_ftsent fts_child;     // linked list of children
    s_ftsent[] fts_array;   // sort array
    uint16 fts_dev;         // starting device #
    string fts_path;        // path for this descent
    uint16 fts_rfd;         // fd for root
    uint16 fts_pathlen;     // sizeof(path)
    uint16 fts_nitems;      // elements in the sort array
    uint16 fts_options;     // fts_open options, global flags
}

struct s_ftsent {
    uint fts_number;        // local numeric value
    bytes fts_pointer;      // local address value
    string fts_accpath;     // access path
    string fts_path;        // root path
    uint16 fts_errno;       // errno for this node
    uint16 fts_symfd;       // fd for symlink
    uint16 fts_pathlen;     // strlen(fts_path)
    uint16 fts_namelen;     // strlen(fts_name)
    uint16 fts_ino;         // inode
    uint16 fts_dev;         // device
    uint16 fts_nlink;       // link count
    int8 fts_level;         // depth (-1 to N)
    uint8 fts_info;         // user flags for FTSENT structure
    uint8 fts_flags;        // private flags for FTSENT structure
    uint16 fts_instr;       // fts_set() instructions
    s_stat fts_statp;       // stat(2) information
    string fts_name;        // file name
}

// Structure used for fourth argument to callback function for `nftw'.
struct s_ftw {
    int base;
    int level;
}

library fts {

    uint16 constant FTS_COMFOLLOW   = 0x0001; // follow command line symlinks
    uint16 constant FTS_LOGICAL     = 0x0002; // logical walk
    uint16 constant FTS_NOCHDIR     = 0x0004; // don't change directories
    uint16 constant FTS_NOSTAT      = 0x0008; // don't get stat info
    uint16 constant FTS_PHYSICAL    = 0x0010; // physical walk
    uint16 constant FTS_SEEDOT      = 0x0020; // return dot and dot-dot
    uint16 constant FTS_XDEV        = 0x0040; // don't cross devices
    uint16 constant FTS_WHITEOUT    = 0x0080; // return whiteout information
    uint16 constant FTS_OPTIONMASK  = 0x00ff; // user option mask

    uint16 constant FTS_NAMEONLY    = 0x0100; // (private) child names only
    uint16 constant FTS_STOP        = 0x0200; // (private) unrecoverable error

    int8 constant FTS_ROOTPARENTLEVEL   = -1;
    int8 constant FTS_ROOTLEVEL         = 0;

    uint8 constant FTS_D        = 1;   // preorder directory
    uint8 constant FTS_DC       = 2;   // directory that causes cycles
    uint8 constant FTS_DEFAULT  = 3;   // none of the above
    uint8 constant FTS_DNR      = 4;   // unreadable directory
    uint8 constant FTS_DOT      = 5;   // dot or dot-dot
    uint8 constant FTS_DP       = 6;   // postorder directory
    uint8 constant FTS_ERR      = 7;   // error; errno is set
    uint8 constant FTS_F        = 8;   // regular file
    uint8 constant FTS_INIT     = 9;   // initialized only
    uint8 constant FTS_NS       = 10;  // stat(2) failed
    uint8 constant FTS_NSOK     = 11;  // no stat(2) requested
    uint8 constant FTS_SL       = 12;  // symbolic link
    uint8 constant FTS_SLNONE   = 13;  // symbolic link without target
    uint8 constant FTS_W        = 14;  // whiteout object

    uint8 constant FTS_DONTCHDIR = 0x01; // don't chdir .. to the parent
    uint8 constant FTS_SYMFOLLOW = 0x02; // followed a symlink to get here

    uint8 constant FTS_AGAIN    = 1; // read node again
    uint8 constant FTS_FOLLOW   = 2; // follow symbolic link
    uint8 constant FTS_NOINSTR  = 3; // no instructions
    uint8 constant FTS_SKIP     = 4; // discard node

    // Values for the FLAG argument to the user function passed to `ftw' and 'nftw'
    uint8 constant FTW_F    = 0; // Regular file
    uint8 constant FTW_D    = 1; // Directory
    uint8 constant FTW_DNR  = 2; // Unreadable directory
    uint8 constant FTW_NS   = 3; // Unstatable file
    uint8 constant FTW_SL   = 4; // Symbolic link
    // flags are only passed from the `nftw' function
    uint8 constant FTW_DP   = 5; // Directory, all subdirs have been visite
    uint8 constant FTW_SLN  = 6; // Symbolic link naming non-existing file

    // Flags for fourth argument of `nftw'
    uint8 constant FTW_PHYS         = 1;  // Perform physical walk, ignore symlinks
    uint8 constant FTW_MOUNT        = 2;  // Report only files on same file system as the argument
    uint8 constant FTW_CHDIR        = 4;  // Change to current directory while processing it
    uint8 constant FTW_DEPTH        = 8;  // Report files in directory before directory itself
    uint8 constant FTW_ACTIONRETVAL = 16; // Assume callback to return FTW_* values instead of zero to continue and non-zero to terminate

    // Return values from callback functions
    uint8 constant FTW_CONTINUE     = 0; // Continue with next sibling or for FTW_D with the first child
    uint8 constant FTW_STOP         = 1; // Return from `ftw' or `nftw' with FTW_STOP as return value
    uint8 constant FTW_SKIP_SUBTREE = 2; // Only meaningful for FTW_D: Don't walk through the subtree, instead just continue with its next sibling
    uint8 constant FTW_SKIP_SIBLINGS= 3; // Continue with FTW_DP callback for current directory (if FTW_DEPTH) and then its siblings

    // Convenient types for callback functions
    //    typedef int (*__ftw_func_t) (string __filename, s_stat __status, int __flag);
    //    typedef int (*__nftw_func_t) (string __filename, s_stat __status, int __flag, s_ftw __info);
    // Call a function on every element in a directory tree
//    function ftw(string __dir, __ftw_func_t __func, int __descriptors)  internal returns (uint8) {}
//    function nftw(string __dir, __nftw_func_t __func, int __descriptors, int __flag) internal returns (uint8) {}

    function compar(s_ftsent first, s_ftsent second) internal returns (uint8) {

    }

    function fts_open(string /*path_argv*/, uint16 /*options*/, uint8 /*compar_index*/) internal returns (s_fts) {
        s_ftsent fts_cur;       // current node
        s_ftsent fts_child;     // linked list of children
        s_ftsent[] fts_array;   // sort array
        uint16 fts_dev;         // starting device #
        string fts_path;        // path for this descent
        uint16 fts_rfd;         // fd for root
        uint16 fts_pathlen;     // sizeof(path)
        uint16 fts_nitems;      // elements in the sort array
        uint16 fts_options;     // fts_open options, global flags
        return s_fts(fts_cur, fts_child, fts_array, fts_dev, fts_path, fts_rfd, fts_pathlen, fts_nitems, fts_options);
    }

    function fts_read(s_fts ftsp) internal returns (s_ftsent[] ents) {
        (, , s_ftsent[] fts_array, uint16 fts_dev, string fts_path, , uint16 fts_pathlen,
            , ) = ftsp.unpack();

        for (s_ftsent fe: fts_array)
            ents.push(fe);

        uint fts_number;        // local numeric value
        bytes fts_pointer;       // local address value
        string fts_accpath;     // access path
        uint16 fts_errno;       // errno for this node
        uint16 fts_symfd;       // fd for symlink
        uint16 fts_namelen;     // strlen(fts_name)
        uint16 fts_ino;         // inode
        uint16 fts_nlink;       // link count
        int8 fts_level;         // depth (-1 to N)
        uint8 fts_info;         // user flags for FTSENT structure
        uint8 fts_flags;        // private flags for FTSENT structure
        uint16 fts_instr;       // fts_set() instructions
        s_stat fts_statp;       // stat(2) information
        string fts_name;        // file name

        ents.push(s_ftsent(fts_number, fts_pointer, fts_accpath, fts_path, fts_errno, fts_symfd, fts_pathlen,
            fts_namelen, fts_ino, fts_dev, fts_nlink, fts_level, fts_info, fts_flags, fts_instr, fts_statp, fts_name));
    }

    function fts_children(s_fts ftsp, int options) internal returns (s_ftsent[]) {
//        return ftsp.
    }

    function fts_set(s_fts ftsp, s_ftsent f, int options) internal returns (uint8) {

    }

    function fts_set_clientptr(s_fts ftsp, bytes clientdata) internal returns (s_ftsent) {
    }
    function fts_get_clientptr(s_fts ftsp) internal returns (s_ftsent) {

    }

    function fts_get_stream(s_ftsent f) internal returns (s_fts) {

    }

    function fts_close(s_fts ftsp) internal returns (uint8) {

    }
}
