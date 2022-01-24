pragma ton-solidity >= 0.55.0;

import "stdio.sol";

library path {

    /* Separates a pathname to directory-part and not-a-directory path */
    function dir(string str) internal returns (string, string) {
        if (str.empty())
            return (".", "");
        if (str == "/")
            return ("/", "/");
        uint q = stdio.strrchr(str, "/");
        if (q == 0)
            return (".", str);
        if (q == 1)
            return ("/", str.substr(1));
        return (str.substr(0, q - 1), str.substr(q));
    }

    function strip_path(string s_path) internal returns (string res) {
        res = stdio.tr_squeeze(s_path, "/");
        uint len = res.byteLength();
        if (len > 0 && stdio.strrchr(res, "/") == len)
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
