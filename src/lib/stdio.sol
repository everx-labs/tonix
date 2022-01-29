pragma ton-solidity >= 0.56.0;

import "str.sol";

/* Generic text processing functions */
library stdio {

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
            string s_tail = text.substr(prev);
            if (!s_tail.empty() && s_tail != delimiter)
                fields.push(s_tail);
            n_fields = fields.length;
        }
    }

    function split_line(string text, string field_separator, string line_delimiter) internal returns (string[] res, uint n_fields) {
        if (!text.empty()) {
            uint p = str.rchr(text, line_delimiter);
            uint text_len = text.byteLength();
            if (p == text_len)
                text = text.substr(0, text_len - 1);
            return split(text, field_separator);
        }
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

    function trim_spaces(string s_arg) internal returns (string res) {
        res = tr_squeeze(s_arg, " ");
        uint len = res.byteLength();
        if (len > 0 && str.rchr(res, " ") == len)
            res = res.substr(0, len - 1);
        len = res.byteLength();
        if (len > 0 && res.substr(0, 1) == " ")
            res = res.substr(1);
    }

    function translate(string text, string pattern, string symbols) internal returns (string out) {
        uint pattern_len = pattern.byteLength();
        uint p = str.sstr(text, pattern);
        string s_tail = text;
        while (p > 0) {
            out.append(s_tail.substr(0, p - 1) + symbols);
            s_tail = s_tail.substr(p - 1 + pattern_len);
            p = str.sstr(s_tail, pattern);
        }
        out.append(s_tail);
    }

    function join_fields(string[] fields, string separator) internal returns (string line) {
        uint len = fields.length;
        if (len > 0) {
            line = fields[0];
            for (uint i = 1; i < len; i++)
                line.append(separator + fields[i]);
        }
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

}
