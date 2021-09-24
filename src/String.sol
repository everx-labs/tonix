pragma ton-solidity >= 0.49.0;

/* String helpers */
abstract contract String {

    /* Returns the first occurrence of a character in a string */
    function _strchr(string text, string symbol) internal pure returns (uint16) {
        for (uint i = 0; i < text.byteLength(); i++)
            if (text.substr(i, 1) == symbol)
                return uint16(i + 1);
    }

    /* Returns the last occurrence of a character in a string */
    function _strrchr(string text, string symbol) internal pure returns (uint16) {
        for (uint i = text.byteLength(); i > 0; i--)
            if (text.substr(i - 1, 1) == symbol)
                return uint16(i);
    }

    function _strstr(string text, string pattern) internal pure returns (uint16) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        for (uint i = 0; i <= text_len - pattern_len; i++)
            if (text.substr(i, pattern_len) == pattern)
                return uint16(i + 1);
    }

    function _translate(string text, string pattern, string symbols) internal pure returns (string out) {
        uint16 p = _strstr(text, pattern);
        return p > 0 ? text.substr(0, p - 1) + symbols + _translate(text.substr(p - 1 + pattern.byteLength()), pattern, symbols) : text;
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
        uint start = 0;
        uint p = 0;
        uint len = text.byteLength();
        while (p < len) {
            if (text.substr(p, 1) == symbol) {
                res.append(text.substr(start, p - start + 1));
                while (p < len && (text.substr(p, 1) == symbol))
                    p++;
                start = p;
            }
            p++;
        }
        res.append(text.substr(start, len - start));
    }

    function _split(string text, string delimiter) internal pure returns (string[] res) {
        uint len = text.byteLength();
        uint prev = 0;
        uint cur = 0;
        while (cur < len - 1) {
            if (text.substr(cur, 1) == delimiter) {
                res.push(text.substr(prev, cur - prev));
                prev = cur + 1;
            }
            cur++;
        }
        res.push(text.substr(prev, cur - prev + 1));
    }

    function _merge(string[] lines) internal pure returns (string text) {
        for (string line: lines)
            text.append(line);
    }

    function _strtok(string text, string delimiter) internal pure returns (string[] res) {
        for (string line: _get_lines(text))
            for (string s: _split(line, delimiter))
                res.push(s);
    }

    function _element_at(uint16 line, uint16 column, string[] text, string delimiter) internal pure returns (string) {
        if (line > 0 && column > 0) {
            if (line <= text.length) {
                string[] records = _split(text[line - 1], delimiter);
                if (column <= records.length)
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
        return " \'" + s + "\' ";
    }

    function _get_lines(string text) internal pure returns (string[] lines) {
        if (!text.empty()) {
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
        if (!line.empty()) {
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

    function _line_and_word_count(string[] text) internal pure returns (uint16 lc, uint16 wc, uint32 cc, uint16 mw) {
        for (string part: text) {
            string[] lines = _get_lines(part);
            lc = uint16(lines.length);
            for (uint16 i = 0; i < lc; i++) {
                string line = lines[i];
                uint16 len = uint16(line.byteLength());
                cc += len;
                wc += _word_count(line);
                if (len > mw) mw = len;
            }
        }
    }

    function _word_count(string text) internal pure returns (uint16) {
        if (!text.empty()) {
            uint16 l = _strchr(text, " ");
            return l == 0 ? 1 : _word_count(text.substr(l, text.byteLength() - l)) + 1;
        }
    }

    /* Read tab-separated values into an array */
    function _get_tsv(string s) internal pure returns (string[] fields) {
        if (!s.empty())
            return _split(s, "\t");
    }

    function _lookup_pair_value(string name, string[] text) internal pure returns (string) {
        for (string s: text) {
            uint16 p = _strchr(s, "\t");
            string key = s.substr(0, p - 1);
            string value = s.substr(p, uint16(s.byteLength()) - p);
            if (key == name)
                return value;
            if (value == name)
                return key;
        }
    }

    function _match_value_at_index(uint16 key_index, string key, uint16 value_index, string[] text) internal pure returns (string) {
        if (key_index > 0 && value_index > 0)
            for (string s: text) {
                string[] fields = _get_tsv(s);
                if (fields[key_index - 1] == key)
                    return fields[value_index - 1];
            }
    }

    /* Path utilities */
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
        if (path.empty())
            return (".", "");
        if (path == "/")
            return ("/", "/");
        uint16 q = _strrchr(path, "/");
        if (q == 0)
            return (".", path);
        uint len = path.byteLength();
        if (q == 1)
            return ("/", path.substr(1, len - 1));
        return (path.substr(0, q - 1), path.substr(q, len - q));
    }

}
