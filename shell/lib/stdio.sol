pragma ton-solidity >= 0.51.0;

library stdio {

    /* Returns the first occurrence of a character in a string */
    function _strchr(string text, string symbol) internal returns (uint) {
        for (uint i = 0; i < text.byteLength(); i++)
            if (text.substr(i, 1) == symbol)
                return i + 1;
    }

    /* Returns the last occurrence of a character in a string */
    function _strrchr(string text, string symbol) internal returns (uint) {
        for (uint i = text.byteLength(); i > 0; i--)
            if (text.substr(i - 1, 1) == symbol)
                return i;
    }

    function _strstr(string text, string pattern) internal returns (uint) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        if (text_len < pattern_len)
            return 0;
        for (uint i = 0; i <= text_len - pattern_len; i++)
            if (text.substr(i, pattern_len) == pattern)
                return i + 1;
    }

    function _split(string text, string delimiter) internal returns (string[] fields, uint n_fields) {
        uint len = text.byteLength();
        if (len > 0) {
            uint prev;
            uint cur;
            while (cur < len) {
                if (text.substr(cur, 1) == delimiter) {
                    fields.push(text.substr(prev, cur - prev));
                    prev = cur + 1;
                }
                cur++;
            }
            fields.push(text.substr(prev));
            n_fields = fields.length;
        }
    }
    function _split_line(string text, string field_separator, string line_delimiter) internal returns (string[] res, uint n_fields) {
        if (!text.empty()) {
            uint p = _strrchr(text, line_delimiter);
            uint text_len = text.byteLength();
            if (p == text_len)
                text = text.substr(0, text_len - 1);
            return _split(text, field_separator);
        }
    }

}