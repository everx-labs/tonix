pragma ton-solidity >= 0.49.0;

/* String helpers */
abstract contract String {

    /* Returns the first occurrence of a character in a string */
    function _strchr(string s, string c) internal pure returns (uint16) {
        for (uint16 i = 0; i < s.byteLength(); i++)
            if (s.substr(i, 1) == c)
                return i + 1;
    }

    /* Returns the last occurrence of a character in a string */
    function _strrchr(string s, string c) internal pure returns (uint16) {
        for (uint16 i = uint16(s.byteLength()); i > 0; i--)
            if (s.substr(i - 1, 1) == c)
                return i;
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

    /* Squeeze repeating occurences of "c" in "s" */
    function _tr_squeeze(string s, string c) internal pure returns (string res) {
        uint start = 0;
        uint p = 0;
        uint len = s.byteLength();
        while (p < len) {
            if (s.substr(p, 1) == c) {
                res.append(s.substr(start, p - start + 1));
                while (p < len && (s.substr(p, 1) == c))
                    p++;
                start = p;
            }
            p++;
        }
        res.append(s.substr(start, len - start));
    }

    function _split(string s, string delimiter) internal pure returns (string[] res) {
        uint16 len = uint16(s.byteLength());
        uint16 prev = 0;
        uint16 cur = 0;
        while (cur < len - 1) {
            if (s.substr(cur, 1) == delimiter) {
                res.push(s.substr(prev, cur - prev));
                prev = cur + 1;
            }
            cur++;
        }
        res.push(s.substr(prev, cur - prev + 1));
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
}
