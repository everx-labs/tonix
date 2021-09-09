pragma ton-solidity >= 0.49.0;

import "String.sol";

/* Path utilities */
abstract contract Path is String {

    function _disassemble_path(string path) internal pure returns (string[] parts) {
        string dir_path;
        while (path.byteLength() > 1) {
            (string dir, string not_dir) = _dir(path);
            dir_path = dir;
            parts.push(not_dir);
            path = dir_path;
        }
        parts.push(path);
    }

    function _assemble_path(string[] parts) internal pure returns (string path) {
        uint len = parts.length;
        path = parts[len - 1];
        for (uint i = len - 1; i > 0; i--)
            path.append("/" + parts[i - 1]);
    }

    function _canon_path(string path) internal pure returns (string) {
        return _assemble_path(_disassemble_path(path));
    }

    function _first_component(string path) internal pure returns (string) {
        uint16 p = _strchr(path, "/");
        if (p == 0)
            return path;
        if (p == 1)
            return "/";
        return path.substr(0, p - 1);
    }

    function _strip_path(string path) internal pure returns (string res) {
        res = _tr_squeeze(path, "/");
        uint len = res.byteLength();
        if (len > 0) {
            uint16 p = _strrchr(res, "/");
            if (p == len)
                res = res.substr(0, len - 1);
        }
    }

    function _dir(string path) internal pure returns (string dir, string not_dir) {
        if (!path.empty()) {
            string s = path;
            if (s == "/")
                return ("/", "/");
            uint16 len = uint16(s.byteLength());
            uint16 q = _strrchr(s, "/");
            if (q == 0)
                return (".", s);
            if (q == 1)
                return ("/", s.substr(1, len - 1));
            if (q > 1)
                return (s.substr(0, q - 1), s.substr(q, len - q));
        }
    }

}
