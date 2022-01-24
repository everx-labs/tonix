pragma ton-solidity >= 0.55.0;

import "stdio.sol";
import "path.sol";

struct Column {
    bool is_visible;
    uint width;
    uint8 align;
}

/* Assorted formatting routines */
library fmt {

    uint8 constant ALIGN_NONE   = 0;
    uint8 constant ALIGN_RIGHT  = 1;
    uint8 constant ALIGN_LEFT   = 2;
    uint8 constant ALIGN_CENTER = 3;

    function format_table_ext(Column[] cf, string[][] lines, string delimiter, string line_delimiter) internal returns (string out) {
        if (lines.empty())
            return "";
        uint[] max_widths = max_table_row_widths(lines);
        uint n_columns = cf.length;
        uint n_rows = lines.length;
        for (uint i = 0; i < n_columns; i++)
            cf[i].width = math.min(cf[i ].width, max_widths[i]);
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
            out.append(pad(fields[0], max_widths[0], align == ALIGN_NONE ? ALIGN_NONE : ALIGN_LEFT));
            uint len = fields.length;
            for (uint j = 1; j < len; j++)
                out.append(delimiter + pad(fields[j], max_widths[j], (j == len - 1) ? ALIGN_LEFT : align));
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
        if (pad_type == ALIGN_NONE)
            return s; // don't pad
        if (pad_type == ALIGN_RIGHT)
            return spaces(pad_size) + s; // right align
        if (pad_type == ALIGN_LEFT)
            return s + spaces(pad_size); // left align
        if (pad_type == ALIGN_CENTER)
            return spaces(pad_size / 2) + s + spaces(pad_size - pad_size / 2); // center align
    }

    function format_list(string header, string text) internal returns (string out) {
        if (!text.empty())
            return header + "\n" + indent(text, 4, "\n");
    }

    function format_line(string header, string text) internal returns (string out) {
        if (!text.empty())
            return header + " " + indent(text, 0, "\n");
    }

    function format_custom(string header, string text, uint indent_size, string delimiter) internal returns (string out) {
        if (!text.empty())
            return header + delimiter + indent(text, indent_size, delimiter);
    }

    function indent(string text, uint indent_size, string delimiter) internal returns (string out) {
        (string[] lines, uint n_lines) = stdio.split(text, "\n");
        string s_spaces;
        for (uint i = 0; i < indent_size; i++)
            s_spaces.append(" ");
        for (uint i = 0; i < n_lines; i++)
            out.append(s_spaces + lines[i] + delimiter);
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

    function s_month(uint t) internal returns (string, uint) {
        uint Aug_1st = 1627776000;
        uint Sep_1st = 1630454400;
        uint Oct_1st = 1633046400;
        uint Nov_1st = 1635724800;
        uint Dec_1st = 1638316800;

        uint Jan_1st = 1640995200;
        uint Feb_1st = 1643673600;
        uint Mar_1st = 1646092800;
        uint Apr_1st = 1648771200;
        uint May_1st = 1651363200;
        uint Jun_1st = 1654041600;

        if (t >= Jun_1st)
            return ("Jun", Jun_1st);
        if (t >= May_1st)
            return ("May", May_1st);
        if (t >= Apr_1st)
            return ("Apr", Apr_1st);
        if (t >= Mar_1st)
            return ("Mar", Mar_1st);
        if (t >= Feb_1st)
            return ("Feb", Feb_1st);
        if (t >= Jan_1st)
            return ("Jan", Jan_1st);

        if (t >= Dec_1st)
            return ("Dec", Dec_1st);
        else if (t >= Nov_1st)
            return ("Nov", Nov_1st);
        else if (t >= Oct_1st)
            return ("Oct", Oct_1st);
        else if (t >= Sep_1st)
            return ("Sep", Sep_1st);
        else if (t >= Aug_1st)
            return ("Aug", Aug_1st);
    }

    /* Time display helpers */
    function to_date(uint t) internal returns (string month, uint day, uint hour, uint minute, uint second) {
        uint t_start;
        (month, t_start) = s_month(t);
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

    /* Network helpers */
    function to_address(string s_addr) internal returns (address addr) {
        uint len = s_addr.byteLength();
        if (len > 60) {
            string s_hex = "0x" + s_addr.substr(2);
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
            cf.push(Column(true, widths[i], ALIGN_RIGHT));
            line.push(dec_to_oct(values[i], widths[i] - 1));
        }
        return format_table_ext(cf, [line], " ", "\n");
    }

    function parse_record(string line, string separator) internal returns (uint[] values, string[] names, address[] addresses) {
        (string[] fields, ) = stdio.split_line(line, separator, "\n");
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
