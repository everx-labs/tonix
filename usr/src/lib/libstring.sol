pragma ton-solidity >= 0.67.0;

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

//    function format_string(string s, bytes fstr, string[] sv, uint16[] dv) internal {
//        uint slen = sv.length;
//        uint len = math.min(fstr.length, slen + dv.length);
//        for (uint i = 0; i < len; i++)
//            s.translate("%" + fstr[i], i < slen ? sv[i] : str.toa(dv[i - slen]));
//    }
//
//    function fmtstr(string s, bytes fstr, string[] values) internal {
//        uint len = math.min(fstr.length, values.length);
//        for (uint i = 0; i < len; i++)
//            s.translate("%" + fstr[i], values[i]);
//    }
//
//    function fmtstrint(string s, bytes fstr, uint16[] values) internal {
//        uint len = math.min(fstr.length, values.length);
//        for (uint i = 0; i < len; i++)
//            s.translate("%" + fstr[i], str.toa(values[i]));
//    }
    /*function trs(string text, string pattern, string symbols) internal {
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
    }*/

    function subst(string text, string pattern, string symbols) internal {
        uint p = text.strstr(pattern);
        if (p > 0)
            text = text.substr(0, p - 1) + symbols + text.substr(p - 1 + pattern.byteLength());
    }

//    function indentprintf(string sfmt, string[] p, uint16[] d, uint indent) internal returns (string out) {
//        out = ".";
//        repeat (indent)
//            out.append("  ");
//        out.append(printf(sfmt, p, d));
//    }

//    function printf(string sfmt, string[] ss, uint16[] dd) internal returns (string) {
//        for (string s: ss)
//            sfmt.subst("%s", s);
//        for (uint16 d: dd)
//            sfmt.subst("%d", str.toa(d));
//        return sfmt;
//    }

    function join_fields(string[] fields, string separator) internal returns (string l) {
        uint len = fields.length;
        if (len > 0) {
            l = fields[0];
            for (uint i = 1; i < len; i++)
                l.append(separator + fields[i]);
        }
    }

    function line_and_word_count(string[] text) internal returns (uint line_count, uint word_count, uint char_count, uint max_width, uint max_words_per_line) {
        for (string l: text) {
            uint line_len = l.strlen();
            (, uint n_words) = split(l, " ");
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
    function print_array(uint32[] arr) internal returns (string out) {
        if (arr.empty())
            return "[ - ]";
        for (uint i = 0; i < arr.length; i++)
            out.append(" " + str.toa(arr[i]));
        return "[" + out + " ]";
    }
    function print_byte_array(uint8[] arr) internal returns (string out) {
        if (arr.empty())
            return "[ - ]";
        for (uint i = 0; i < arr.length; i++)
            out.append(" " + str.toa(arr[i]));
        return "[" + out + " ]";
    }
    function null_term(bytes bb) internal returns (string) {
        uint len;
        for (bytes1 b: bb) {
            if (b == 0)
                break;
            len++;
        }
        return bb[ : len];
    }
}
