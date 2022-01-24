pragma ton-solidity >= 0.55.0;

library stdio {

    /* Returns the first occurrence of a character in a string */
    function strchr(string text, string symbol) internal returns (uint) {
        for (uint i = 0; i < text.byteLength(); i++)
            if (text.substr(i, 1) == symbol)
                return i + 1;
    }

    /* Returns the last occurrence of a character in a string */
    function strrchr(string text, string symbol) internal returns (uint) {
        for (uint i = text.byteLength(); i > 0; i--)
            if (text.substr(i - 1, 1) == symbol)
                return i;
    }

    function strstr(string text, string pattern) internal returns (uint) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        if (text_len < pattern_len)
            return 0;
        for (uint i = 0; i <= text_len - pattern_len; i++)
            if (text.substr(i, pattern_len) == pattern)
                return i + 1;
    }

    function split(string text, string delimiter) internal returns (string[] fields, uint n_fields) {
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
    function split_line(string text, string field_separator, string line_delimiter) internal returns (string[] res, uint n_fields) {
        if (!text.empty()) {
            uint p = strrchr(text, line_delimiter);
            uint text_len = text.byteLength();
            if (p == text_len)
                text = text.substr(0, text_len - 1);
            return split(text, field_separator);
        }
    }

    function atoi(string s) internal returns (uint16) {
        optional(int) val = stoi(s);
        return val.hasValue() ? uint16(val.get()) : 0;
    }

    function itoa(uint num) internal returns (string) {
        return format("{}", num);
    }

    /* Squeeze repeating occurences of "symbol" in "text" */
    function tr_squeeze(string text, string symbol) internal returns (string res) {
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

    function strval(string text, string pattern, string delimiter) internal returns (string) {
        uint p = strstr(text, pattern);
        return p > 0 ? strtok(text, p - 1 + pattern.byteLength(), delimiter) : "";
    }

    function strtok(string text, uint start, string delimiter) internal returns (string) {
        uint len = text.byteLength();
        uint pos = start;
        while (pos < len && text.substr(pos, 1) == delimiter)
            pos++;
        string s_tail = pos > 0 && pos < len ? text.substr(pos) : text;
        uint end = strchr(s_tail, delimiter);
        return end > 0 ? s_tail.substr(0, end - 1) : s_tail;
    }

    function strsplit(string text, string delimiter) internal returns (string, string) {
        uint p = strchr(text, delimiter);
        return p > 0 ? (text.substr(0, p - 1), text.substr(p)) : (text, "");
    }

    function translate(string text, string pattern, string symbols) internal returns (string out) {
        uint pattern_len = pattern.byteLength();
        uint p = strstr(text, pattern);
        string s_tail = text;
        while (p > 0) {
            out.append(s_tail.substr(0, p - 1) + symbols);
            s_tail = s_tail.substr(p - 1 + pattern_len);
            p = strstr(s_tail, pattern);
        }
        out.append(s_tail);
    }

    function translate_old(string text, string pattern, string symbols) internal returns (string out) {
        uint p = strstr(text, pattern);
        uint pattern_len = pattern.byteLength();
        if (p > 0) {
            string s_head = text.substr(0, p - 1) + symbols;
            string s_tail = translate(text.substr(p - 1 + pattern_len), pattern, symbols);
            return s_head + s_tail;
        } else
            return text;
    }

    function join_fields(string[] fields, string separator) internal returns (string line) {
        uint len = fields.length;
        if (len > 0) {
            line = fields[0];
            for (uint i = 1; i < len; i++)
                line.append(separator + fields[i]);
        }
    }

    function aif(string s1, bool flag, string s2) internal returns (string) {
        return flag ? s1 + s2 : s1;
    }

    function line_and_word_count(string[] text) internal returns (uint line_count, uint word_count, uint char_count, uint max_width, uint max_words_per_line) {
        for (string line: text) {
            uint line_len = line.byteLength();
            (, uint n_words) = split(line, " ");
            char_count += line_len;
            word_count += n_words;
            max_width = math.max(max_width, line_len);
            max_words_per_line = math.max(max_words_per_line, n_words);
            line_count++;
        }
    }

    function quote(string s) internal returns (string) {
        return " \'" + s + "\'";
    }

    /* Read tab-separated values into an array */
    function get_tsv(string s) internal returns (string[] fields) {
        if (!s.empty())
            (fields, ) = split(s, "\t");
    }

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
