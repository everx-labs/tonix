pragma ton-solidity >= 0.61.2;

import "str.sol";

/* Generic text processing functions */
library libstring {

    using str for string;

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
            string stail = text.substr(prev);
            if (!stail.empty() && stail != delimiter)
                fields.push(stail);
            n_fields = fields.length;
        }
    }

    function split_line(string text, string field_separator, string line_delimiter) internal returns (string[] res, uint n_fields) {
        if (!text.empty()) {
//            uint p = text.strrchr(line_delimiter);
            uint p = str.strrchr(text, bytes(line_delimiter)[0]);
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

    function trim_spaces(string sarg) internal returns (string res) {
        res = tr_squeeze(sarg, " ");
        uint len = res.byteLength();
        if (len > 0 && res.strrchr(" ") == len)
            res = res.substr(0, len - 1);
        len = res.byteLength();
        if (len > 0 && res.substr(0, 1) == " ")
            res = res.substr(1);
    }

    function translate(string text, string pattern, string symbols) internal returns (string out) {
        uint pattern_len = pattern.byteLength();
        uint p = text.strstr(pattern);
        string stail = text;
        while (p > 0) {
            out.append(stail.substr(0, p - 1) + symbols);
            stail = stail.substr(p - 1 + pattern_len);
            p = stail.strstr(pattern);
        }
        out.append(stail);
        text = out;
    }

    function trs(string text, string pattern, string symbols) internal {
        uint pattern_len = pattern.strlen();
        uint p = text.strstr(pattern);
        string stail = text;
        string out;
        while (p > 0) {
            out.append(stail.substr(0, p - 1) + symbols);
            stail = stail.substr(p - 1 + pattern_len);
            p = stail.strstr(pattern);
        }
        out.append(stail);
        text = out;
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
            uint line_len = line.strlen();
            (, uint n_words) = split(line, " ");
            char_count += line_len;
            word_count += n_words;
            max_width = math.max(max_width, line_len);
            max_words_per_line = math.max(max_words_per_line, n_words);
            line_count++;
        }
    }

    function ssplit(string text, string delimiter) internal returns (string, string) {
        uint p = text.strstr(delimiter);
        return p > 0 ? (text.substr(0, p - 1), text.substr(p + delimiter.strlen() - 1)) : (text, "");
    }
    function csplit(string text, string delimiter) internal returns (string, string) {
        uint p = str.strchr(text, bytes(delimiter)[0]);
        return p > 0 ? (text.substr(0, p - 1), text.substr(p)) : (text, "");
    }

    function val(string text, string pattern, string delimiter) internal returns (string) {
        uint p = text.strstr(pattern);
        return p > 0 ? text.strtok(p - 1 + pattern.byteLength(), delimiter) : "";
    }
    /* Returns the line in the text containing the specified pattern */
    function line(string text, string pattern) internal returns (string) {
        uint pos = text.strstr(pattern);
        if (pos > 0) {
            uint pat_len = pattern.strlen();
            (string shead, string stail) = ssplit(text, pattern);
            uint p = shead.strrchr("\n");
            uint q = stail.strchr("\n");
            return text.substr(p, q + pat_len);
        }
    }

    /* Removes the trailing character of the string 's' */
    function trim_trailing(string s) internal returns (string) {
        uint16 len = s.strlen();
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

    function sval(string text, string pattern, string delimiter) internal {
        uint p = text.strstr(pattern);
        text = p > 0 ? text.strtok(p - 1 + pattern.strlen(), delimiter) : "";
    }
}
