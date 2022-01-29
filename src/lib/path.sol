pragma ton-solidity >= 0.56.0;

import "stdio.sol";
import "str.sol";

library path {

    uint16 constant CANON_NONE  = 0;
    uint16 constant CANON_MISS  = 1;
    uint16 constant CANON_DIRS  = 2;
    uint16 constant CANON_EXISTS = 3;
    uint16 constant EXPAND_SYMLINKS = 8;

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

    /* Separates a pathname to directory-part and not-a-directory path */
    function dir(string s) internal returns (string, string) {
        if (s.empty())
            return (".", "");
        if (s == "/")
            return ("/", "/");
        uint q = str.rchr(s, "/");
        if (q == 0)
            return (".", s);
        if (q == 1)
            return ("/", s.substr(1));
        return (s.substr(0, q - 1), s.substr(q));
    }

    function strip_path(string s_path) internal returns (string res) {
        res = stdio.tr_squeeze(s_path, "/");
        uint len = res.byteLength();
        if (len > 0 && str.rchr(res, "/") == len)
            res = res.substr(0, len - 1);
    }

    function disassemble_path(string s_path) internal returns (string[] parts) {
        string dir_path;
        while (s_path.byteLength() > 1) {
            (string s_dir, string s_not_dir) = dir(s_path);
            dir_path = s_dir;
            parts.push(s_not_dir);
            s_path = dir_path;
        }
        parts.push(s_path);
    }

}
