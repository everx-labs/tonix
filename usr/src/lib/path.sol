pragma ton-solidity >= 0.58.0;

import "libstring.sol";

library path {

    using str for string;
    using libstring for string;

    uint16 constant CANON_NONE  = 0;
    uint16 constant CANON_MISS  = 1;
    uint16 constant CANON_DIRS  = 2;
    uint16 constant CANON_EXISTS = 3;
    uint16 constant EXPAND_SYMLINKS = 8;

    /* Separates a pathname to directory-part and not-a-directory part */
    function dir(string s) internal returns (string, string) {
        if (s.empty())
            return (".", "");
        if (s == "/")
            return ("/", "/");
        uint q = s.strrchr("/");
        if (q == 0)
            return (".", s);
        if (q == 1)
            return ("/", s.substr(1));
        return (s.substr(0, q - 1), s.substr(q));
    }

    function dir2(string s) internal returns (string, string) {
        if (s.empty())
            return (".", "");
        if (s == "/")
            return ("/", "/");
        uint q = s.strchr("/");
        if (q == 0)
            return (".", s);
        if (q == 1)
            return ("/", s.substr(1));
        return (s.substr(0, q - 1), s.substr(q));
    }

    function dir3(string s) internal returns (string cdir, string cn, string ctail) {
        if (s.empty())
            return (".", "", "");
        if (s == "/")
            return ("/", "", "");
        uint q = s.strchr("/");
        if (q == 0)
            return (".", s, "");
        if (q == 1) {
            cdir = "/";
            cn = s.substr(1);
        } else
            (cdir, cn) = s.csplit('/');
        s = cn;
        (cn, ctail) = s.csplit('/');
    }

    function dirp(string s) internal returns (string) {
        if (s.empty())
            return ".";
        if (s == "/")
            return "/";
        uint q = s.strrchr("/");
        if (q == 0)
            return ".";
        string sorg = s;
        if (q == 1) {
            s = sorg.substr(1);
            return "/";
        }
        s = sorg.substr(q);
        return sorg.substr(0, q - 1);
    }

    function strip_path(string spath) internal returns (string res) {
        res = libstring.tr_squeeze(spath, "/");
        uint len = res.byteLength();
        if (len > 0 && res.strrchr("/") == len)
            res = res.substr(0, len - 1);
    }

    function disassemble_path(string spath) internal returns (string[] parts) {
        string dir_path;
        while (spath.byteLength() > 1) {
            (string sdir, string snot_dir) = dir(spath);
            dir_path = sdir;
            parts.push(snot_dir);
            spath = dir_path;
        }
        parts.push(spath);
    }

}
