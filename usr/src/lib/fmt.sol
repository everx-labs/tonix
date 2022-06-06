pragma ton-solidity >= 0.58.0;

import "libstring.sol";

struct Column {
    bool is_visible;
    uint width;
    uint8 align;
}

/* Assorted formatting routines */
library fmt {

    using libstring for string;
    /* Alignment */
    uint8 constant NONE   = 0;
    uint8 constant RIGHT  = 1;
    uint8 constant LEFT   = 2;
    uint8 constant CENTER = 3;

    uint16 constant KILO = 1024;

    function format_table_ext(Column[] cf, string[][] lines, string delimiter, string line_delimiter) internal returns (string out) {
        if (lines.empty())
            return "";
        uint[] max_widths = max_table_row_widths(lines);
        uint n_columns = cf.length;
        uint n_rows = lines.length;
        for (uint i = 0; i < n_columns; i++)
            cf[i].width = math.min(cf[i].width, max_widths[i]);
        for (uint i = 0; i < n_rows; i++) {
            string[] fields = lines[i];
            uint len = fields.length;
            for (uint j = 0; j < len; j++) {
                (bool is_visible, uint width, uint8 align) = cf[j].unpack();
                if (is_visible)
                    out.append((j > 0 ? delimiter :"") + pad(fields[j], width, align));
            }
            out.append(line_delimiter);
        }
    }

    function format_table(string[][] lines, string delimiter, string line_delimiter, uint8 align) internal returns (string out) {
        if (lines.empty())
            return "";
        uint[] max_widths = max_table_row_widths(lines);
        uint n_rows = lines.length;
        for (uint i = 0; i < n_rows; i++) {
            string[] fields = lines[i];
            out.append(pad(fields[0], max_widths[0], align == NONE ? NONE : LEFT));
            uint len = fields.length;
            for (uint j = 1; j < len; j++)
                out.append(delimiter + pad(fields[j], max_widths[j], (j == len - 1) ? LEFT : align));
            out.append(line_delimiter);
        }
    }

    function spaces(uint n) internal returns (string res) {
        string spaces_16 = "                ";
        for (uint i = 0; i < n / 16; i++)
            res.append(spaces_16);
        if (n % 16 > 0)
            res.append(spaces_16.substr(0, n % 16));
    }

    function pad(string s, uint width, uint8 pad_type) internal returns (string) {
        uint len = s.byteLength();
        if (len > width)
            return s.substr(0, width);
        uint pad_size = width - len;
        if (pad_type == NONE)
            return s; // don't pad
        if (pad_type == RIGHT)
            return spaces(pad_size) + s; // right align
        if (pad_type == LEFT)
            return s + spaces(pad_size); // left align
        if (pad_type == CENTER)
            return spaces(pad_size / 2) + s + spaces(pad_size - pad_size / 2); // center align
    }

    function format_list(string header, string text) internal returns (string) {
        if (!text.empty())
            return header + "\n" + indent(text, 4, "\n");
    }

    function format_line(string header, string text) internal returns (string) {
        if (!text.empty())
            return header + " " + indent(text, 0, "\n");
    }

    function format_custom(string header, string text, uint indent_size, string delimiter) internal returns (string) {
        if (!text.empty())
            return header + delimiter + indent(text, indent_size, delimiter);
    }

    function indent(string text, uint indent_size, string delimiter) internal returns (string out) {
        (string[] lines, uint n_lines) = text.split("\n");
        string sspaces;
        for (uint i = 0; i < indent_size; i++)
            sspaces.append(" ");
        for (uint i = 0; i < n_lines; i++)
            out.append(sspaces + lines[i] + delimiter);
    }

    function max_table_row_widths(string[][] rows) internal returns (uint[] max_widths) {
        string[] header = rows[0];
        uint header_len = header.length;
        for (uint i = 0; i < header_len; i++)
            max_widths.push(header[i].byteLength());
        uint n_rows = rows.length;
        for (uint i = 1; i < n_rows; i++) {
            string[] fields = rows[i];
            uint n_fields = fields.length;
            for (uint j = 0; j < n_fields; j++)
                max_widths[j] = math.max(max_widths[j], fields[j].byteLength());
        }
    }

    /* File size display helpers */
    function scale(uint32 n, uint32 factor) internal returns (string) {
        if (n < factor || factor == 1)
            return format("{}", n);
        (uint d, uint m) = math.divmod(n, factor);
        return d > 10 ? format("{}K", d) : format("{}.{}K", d, m / 100);
    }

    function smonth(uint t) internal returns (uint, string) {
        mapping (uint32 => string) mo;
        mo[1654041600] = "Jun";
        mo[1651363200] = "May";
        mo[1648771200] = "Apr";
        mo[1646092800] = "Mar";
        mo[1643673600] = "Feb";
        mo[1640995200] = "Jan";
        mo[1638316800] = "Dec";
        mo[1635724800] = "Nov";
        mo[1633046400] = "Oct";
        mo[1630454400] = "Sep";
        mo[1627776000] = "Aug";

        optional(uint32, string) pair = mo.prev(t);
        if (pair.hasValue())
            return pair.get();
    }

    /* Time display helpers */
    function to_date(uint t) internal returns (string month, uint day, uint hour, uint minute, uint second) {
        uint t_start;
        (t_start, month) = smonth(t);
        uint t0 = t - t_start;
        day = t0 / 86400 + 1;
        uint t1 = t0 % 86400;
        hour = t1 / 3600;
        uint t2 = t1 % 3600;
        minute = t2 / 60;
        second = t2 % 60;
    }

    function ts(uint t) internal returns (string) {
        (string month, uint day, uint hour, uint minute, uint second) = to_date(t);
        return format("{} {:02} {:02}:{:02}:{:02}", month, day, hour, minute, second);
    }

    /* Read tab-separated values into an array */
    function get_tsv(string s) internal returns (string[] fields) {
        if (!s.empty())
            (fields, ) = s.split("\t");
    }

    function to_address(string saddr) internal returns (address) {
        uint len = saddr.byteLength();
        if (len > 60) {
            string s_hex = "0x" + saddr.substr(2);
            optional(int) u_addr = stoi(s_hex);
            if (u_addr.hasValue())
                return address.makeAddrStd(0, uint(u_addr.get()));
        }
    }

    function dec_to_oct(uint p, uint width) internal returns (string res) {
        for (uint i = 0; i < width; i++) {
            res = format("{}", p & 0x07) + res;
            p >>= 3;
        }
    }

    function v0(uint i) internal returns (string res) {
        TvmBuilder b;
        b.storeUnsigned(i, 256);
        TvmSlice slice = b.toSlice();
        TvmSlice slice2 = slice;
        TvmSlice slice3 = slice;
        string s = slice.decode(string);
        bytes ba = slice2.decode(bytes);
        uint u = slice3.decode(uint);
        res.append(s + " ");
        res.append(string(ba) + " ");
        res.append(format("{} ", u));
        res.append("\n");
    }

    function byte_sum(bytes bts, uint offset, uint count) internal returns (uint sum) {
        for (uint i = offset; i < offset + count; i++)
            sum += uint8(bytes1(bts[i]));
    }

    function octal_dump(uint8[] widths, uint[] values) internal returns (string) {
        Column[] cf;
        string[] line;
        for (uint i = 0; i < values.length; i++) {
            cf.push(Column(true, widths[i], RIGHT));
            line.push(dec_to_oct(values[i], widths[i] - 1));
        }
        return format_table_ext(cf, [line], " ", "\n");
    }

    function parse_record(string line, string separator) internal returns (uint[] values, string[] names, address[] addresses) {
        (string[] fields, ) = line.split_line(separator, "\n");
        for (string s: fields) {
            uint len = s.byteLength();
            if (len > 65)
                addresses.push(to_address(s));
            else {
                optional(int) val = stoi(s);
                if (val.hasValue())
                    values.push(uint(val.get()));
                else
                    names.push(s);
            }
        }
    }

}
