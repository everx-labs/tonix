pragma ton-solidity >= 0.53.0;

/* String helpers */
abstract contract String {

    /* Returns the first occurrence of a character in a string */
    function _strchr(string text, string symbol) internal pure returns (uint) {
        for (uint i = 0; i < text.byteLength(); i++)
            if (text.substr(i, 1) == symbol)
                return i + 1;
    }

    /* Returns the last occurrence of a character in a string */
    function _strrchr(string text, string symbol) internal pure returns (uint) {
        for (uint i = text.byteLength(); i > 0; i--)
            if (text.substr(i - 1, 1) == symbol)
                return i;
    }

    function _strstr(string text, string pattern) internal pure returns (uint) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        if (text_len < pattern_len)
            return 0;
        for (uint i = 0; i <= text_len - pattern_len; i++)
            if (text.substr(i, pattern_len) == pattern)
                return i + 1;
    }

    function _translate(string text, string pattern, string symbols) internal pure returns (string out) {
        uint p = _strstr(text, pattern);
        uint pattern_len = pattern.byteLength();
        if (p > 0) {
            string s_head = text.substr(0, p - 1) + symbols;
            string s_tail = _translate(text.substr(p - 1 + pattern_len), pattern, symbols);
            return s_head + s_tail;
        } else
            return text;
    }

    function _parse_to_symbol(string s, uint start, uint len, string sym) internal pure returns (string, uint pos) {
        pos = start;
        while (pos < len) {
            if (s.substr(pos, 1) == sym)
                return (s.substr(start, pos - start), pos);
            pos++;
        }
        return (pos > start ? s.substr(start, pos - start) : "", pos);
    }

    /* Squeeze repeating occurences of "symbol" in "text" */
    function _tr_squeeze(string text, string symbol) internal pure returns (string res) {
        uint start;
        uint p;
        uint len = text.byteLength();
        while (p < len) {
            if (text.substr(p, 1) == symbol) {
                res.append(text.substr(start, p - start + 1));
                while (p < len && text.substr(p, 1) == symbol)
                    p++;
                start = p;
            }
            p++;
        }
        res.append(text.substr(start));
    }

    function _strsplit(string text, string delimiter) internal pure returns (string, string) {
        uint p = _strchr(text, delimiter);
        return p > 0 ? (text.substr(0, p - 1), text.substr(p)) : (text, "");
    }

    function _strval(string text, string pattern, string delimiter) internal pure returns (string) {
        uint p = _strstr(text, pattern);
        return p > 0 ? _strtok(text, p - 1 + pattern.byteLength(), delimiter) : "";
    }

    function _strtok(string text, uint start, string delimiter) internal pure returns (string) {
        uint len = text.byteLength();
        uint pos = start;
        while (pos < len && text.substr(pos, 1) == delimiter)
            pos++;
        string s_tail = pos > 0 && pos < len ? text.substr(pos) : text;
        uint end = _strchr(s_tail, delimiter);
        return end > 0 ? s_tail.substr(0, end - 1) : s_tail;
    }

    function _strrtok(string text, string delimiter) internal pure returns (string, string) {
        uint p = _strrchr(text, delimiter);
        return p > 0 ? (text.substr(0, p - 1), text.substr(p)) : (text, "");
    }

    function _split(string text, string delimiter) internal pure returns (string[] fields, uint n_fields) {
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

    function _split_line(string text, string field_separator, string line_delimiter) internal pure returns (string[] res, uint n_fields) {
        if (!text.empty()) {
            uint p = _strrchr(text, line_delimiter);
            uint text_len = text.byteLength();
            if (p == text_len)
                text = text.substr(0, text_len - 1);
            return _split(text, field_separator);
        }
    }

    function _element_at(uint16 line, uint16 column, string[] text, string delimiter) internal pure returns (string) {
        if (line > 0 && column > 0) {
            if (line <= text.length) {
                (string[] records, uint n_records) = _split(text[line - 1], delimiter);
                if (column <= n_records)
                    return records[column - 1];
            }
        }
    }

    function _join_fields(string[] fields, string separator) internal pure returns (string line) {
        uint len = fields.length;
        if (len > 0) {
            line = fields[0];
            for (uint i = 1; i < len; i++)
                line.append(separator + fields[i]);
        }
    }

    function _if(string s1, bool flag, string s2) internal pure returns (string) {
        return flag ? s1 + s2 : s1;
    }

    function _quote(string s) internal pure returns (string) {
        return " \'" + s + "\'";
    }

    function _line_and_word_count(string[] text) internal pure returns (uint line_count, uint word_count, uint char_count, uint max_width, uint max_words_per_line) {
        for (string line: text) {
            uint line_len = line.byteLength();
            (, uint n_words) = _split(line, " ");
            char_count += line_len;
            word_count += n_words;
            max_width = math.max(max_width, line_len);
            max_words_per_line = math.max(max_words_per_line, n_words);
            line_count++;
        }
    }

    /* Read tab-separated values into an array */
    function _get_tsv(string s) internal pure returns (string[] fields) {
        if (!s.empty())
            (fields, ) = _split(s, "\t");
    }

    function _atoi(string s) internal pure returns (uint16) {
        optional(int) val = stoi(s);
        return val.hasValue() ? uint16(val.get()) : 0;
    }

    /********** Path utilities ************/

    /* Disassembles a pathname into components */
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

    /* strips extra heading and trailing slashes from a pathname */
    function _strip_path(string path) internal pure returns (string res) {
        res = _tr_squeeze(path, "/");
        uint len = res.byteLength();
        if (len > 0 && _strrchr(res, "/") == len)
            res = res.substr(0, len - 1);
    }

    /* Separates a pathname to directory-part and not-a-directory path */
    function _dir(string path) internal pure returns (string dir, string not_dir) {
        if (path.empty())
            return (".", "");
        if (path == "/")
            return ("/", "/");
        uint q = _strrchr(path, "/");
        if (q == 0)
            return (".", path);
        if (q == 1)
            return ("/", path.substr(1));
        return (path.substr(0, q - 1), path.substr(q));
    }

    /* Assigns a rating to a string to sort alphabetically */
    function _alpha_rating(string s, uint len) internal pure returns (uint rating) {
        bytes bts = bytes(s);
        uint lim = math.min(len, bts.length);
        for (uint i = 0; i < lim; i++)
            rating += uint(uint8(bts[i])) << ((len - i - 1) * 8);
    }
}
