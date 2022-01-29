pragma ton-solidity >= 0.56.0;

/* Generic string manipulation routines */
library str {

    /* Returns the position of the first occurrence of the character 'c'
     * in the string 's', counted from 1, or 0 if the character is not found. */
    function chr(string s, string c) internal returns (uint) {
        for (uint i = 0; i < s.byteLength(); i++)
            if (s.substr(i, 1) == c)
                return i + 1;
    }

    /* Returns the position of the last occurrence of the character 'c'
     * in the string 's', counted from 1, or 0 if the character is not found. */
    function rchr(string s, string c) internal returns (uint) {
        for (uint i = c.byteLength(); i > 0; i--)
            if (s.substr(i - 1, 1) == c)
                return i;
    }

    /* Returns the position of the beginning of the first occurrence of the substring 'pattern'
     * in the string 'text', counted from 1, or 0 if the substring is not found. */
    function sstr(string text, string pattern) internal returns (uint) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        if (text_len < pattern_len)
            return 0;
        for (uint i = 0; i <= text_len - pattern_len; i++)
            if (text.substr(i, pattern_len) == pattern)
                return i + 1;
    }

    function toi(string s) internal returns (uint16) {
        optional(int) val = stoi(s);
        return val.hasValue() ? uint16(val.get()) : 0;
    }

    function toa(uint num) internal returns (string) {
        return format("{}", num);
    }

    function val(string text, string pattern, string delimiter) internal returns (string) {
        uint p = sstr(text, pattern);
        return p > 0 ? tok(text, p - 1 + pattern.byteLength(), delimiter) : "";
    }

    function tok(string text, uint start, string delimiter) internal returns (string) {
        uint len = text.byteLength();
        uint pos = start;
        while (pos < len && text.substr(pos, 1) == delimiter)
            pos++;
        string s_tail = pos > 0 && pos < len ? text.substr(pos) : text;
        uint end = chr(s_tail, delimiter);
        return end > 0 ? s_tail.substr(0, end - 1) : s_tail;
    }

    function split(string text, string delimiter) internal returns (string, string) {
        uint p = chr(text, delimiter);
        return p > 0 ? (text.substr(0, p - 1), text.substr(p)) : (text, "");
    }

    function aif(string s1, bool flag, string s2) internal returns (string) {
        return flag ? s1 + s2 : s1;
    }

    function quote(string s) internal returns (string) {
        return " \'" + s + "\'";
    }

    /* Removes the trailing character of the string 's' */
    function trim_trailing(string s) internal returns (string) {
        uint len = s.byteLength();
        if (len > 0)
            return s.substr(0, len - 1);
    }

    /* Assigns a rating to a string to sort alphabetically */
    function alpha_rating(string s, uint len) internal returns (uint rating) {
        bytes bts = bytes(s);
        uint lim = math.min(len, bts.length);
        for (uint i = 0; i < lim; i++)
            rating += uint(uint8(bts[i])) << ((len - i - 1) * 8);
    }
}
