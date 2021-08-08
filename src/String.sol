pragma ton-solidity >= 0.48.0;

abstract contract String {

    function _path(string s) internal pure returns (string res) {
        uint16 p1 = 0;
        uint16 len = uint16(s.byteLength());
        uint16 p2 = len - 1;
        while (s.substr(p1, 1) == " ")
            p1++;
        while (s.substr(p2, 1) == " ")
            p2--;
        if (p2 - p1 + 1 < len)
            res = s.substr(p1, p2 - p1);
        else
            res = s;
        p1 = 0;
        len = uint16(res.byteLength());
        if (res.substr(0, 1) == "/") {
            while (res.substr(p1 + 1, 1) == "/")
                p1++;
        }
        while (res.substr(p2, 1) == "/")
            p2--;
        if (p2 - p1 + 1 < len)
            res = s.substr(p1, p2 - p1 + 1);
    }

    function _not_dir(string s0) internal pure returns (string) {
        string s = _path(s0);
        uint16 q = _strrchr(s, "/");
        return q == 0 ? s : s.substr(q, s.byteLength() - q);
    }

    function _dir(string s0) internal pure returns (string) {
        string s = _path(s0);
        uint16 q = _strrchr(s, "/");
        return (q < 2) ? s : s.substr(0, q - 1);
    }

    function _strchr(string s, string c) internal pure returns (uint16) {
        for (uint16 i = 0; i < s.byteLength(); i++)
            if (s.substr(i, 1) == c)
                return i + 1;
    }

    function _strrchr(string s, string c) internal pure returns (uint16) {
        uint16 len = uint16(s.byteLength());
        for (uint16 i = len; i > 0; i--)
            if (s.substr(i - 1, 1) == c)
                return i;
    }

    function _if(string s1, bool flag, string s2) internal pure returns (string) {
        return flag ? s1 + s2 : s1;
    }

    function _quote(string s) internal pure returns (string) {
        return " \'" + s + "\' ";
    }

    function _get_lines(string text) internal pure returns (string[] lines) {
        if (text != "") {
            uint16 l = _strchr(text, "\n");
            if (l == 0)
                lines.push(text);
            else {
                lines.push(text.substr(0, l - 1));
                string[] tail = _get_lines(text.substr(l, text.byteLength() - l));
                for (string s: tail)
                    lines.push(s);
            }
        }
    }
    function _get_words(string line) internal pure returns (string[] words) {
        if (line != "") {
            uint16 l = _strchr(line, "\n");
            if (l == 0)
                words.push(line);
            else {
                words.push(line.substr(0, l - 1));
                string[] tail = _get_words(line.substr(l, line.byteLength() - l));
                for (string s: tail)
                    words.push(s);
            }
        }
    }

    function _line_and_word_count(string text) internal pure returns (uint16 lc, uint16 wc, uint32 cc, uint16 mw) {
        if (text == "") return (0, 0, 0, 0);

        string[] lines = _get_lines(text);
        lc = uint16(lines.length);
        for (uint16 i = 0; i < lc; i++) {
            string line = lines[i];
            uint16 len = uint16(line.byteLength());
            cc += len;
            wc += _word_count(line);
            if (len > mw) mw = len;
        }
    }
    function _word_count(string text) internal pure returns (uint16) {
        if (text == "") return 0;
        uint16 l = _strchr(text, " ");
        return l == 0 ? 1 : _word_count(text.substr(l, text.byteLength() - l)) + 1;
    }


}
