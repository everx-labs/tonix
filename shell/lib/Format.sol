pragma ton-solidity >= 0.55.0;

//import "../lib/String.sol";
import "stdio.sol";
import "path.sol";

/* Assorted formatting routines */
abstract contract Format {
//abstract contract Format is String {

    uint8 constant ALIGN_NONE   = 0;
    uint8 constant ALIGN_RIGHT  = 1;
    uint8 constant ALIGN_LEFT   = 2;
    uint8 constant ALIGN_CENTER = 3;

    struct Column {
        bool is_visible;
        uint width;
        uint8 align;
    }

    function _format_table_ext(Column[] cf, string[][] lines, string delimiter, string line_delimiter) internal pure returns (string out) {
        if (lines.empty())
            return "";
        uint[] max_widths = _max_table_row_widths(lines);
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
                    out.append((j > 0 ? delimiter :"") + _pad(fields[j], width, align));
            }
            out.append(line_delimiter);
        }
    }

    function _format_table(string[][] lines, string delimiter, string line_delimiter, uint8 align) internal pure returns (string out) {
        if (lines.empty())
            return "";
        uint[] max_widths = _max_table_row_widths(lines);
        uint n_rows = lines.length;
        for (uint i = 0; i < n_rows; i++) {
            string[] fields = lines[i];
            out.append(_pad(fields[0], max_widths[0], align == ALIGN_NONE ? ALIGN_NONE : ALIGN_LEFT));
            uint len = fields.length;
            for (uint j = 1; j < len; j++)
                out.append(delimiter + _pad(fields[j], max_widths[j], (j == len - 1) ? ALIGN_LEFT : align));
            out.append(line_delimiter);
        }
    }

    function _spaces(uint n) internal pure returns (string res) {
        string spaces_16 = "                ";
        for (uint i = 0; i < n / 16; i++)
            res.append(spaces_16);
        if (n % 16 > 0)
            res.append(spaces_16.substr(0, n % 16));
    }

    function _pad(string s, uint width, uint8 pad) internal pure returns (string) {
        uint len = s.byteLength();
        if (len > width)
            return s.substr(0, width);
        uint pad_size = width - len;
        if (pad == ALIGN_NONE)
            return s; // don't pad
        if (pad == ALIGN_RIGHT)
            return _spaces(pad_size) + s; // right align
        if (pad == ALIGN_LEFT)
            return s + _spaces(pad_size); // left align
        if (pad == ALIGN_CENTER)
            return _spaces(pad_size / 2) + s + _spaces(pad_size - pad_size / 2); // center align
    }

    function _format_list(string header, string text) internal pure returns (string out) {
        if (!text.empty())
            return header + "\n" + _indent(text, 4, "\n");
    }

    function _format_line(string header, string text) internal pure returns (string out) {
        if (!text.empty())
            return header + " " + _indent(text, 0, "\n");
    }

    function _format_custom(string header, string text, uint indent_size, string delimiter) internal pure returns (string out) {
        if (!text.empty())
            return header + delimiter + _indent(text, indent_size, delimiter);
    }

    function _indent(string text, uint indent_size, string delimiter) internal pure returns (string out) {
        (string[] lines, uint n_lines) = stdio.split(text, "\n");
        string spaces;
        for (uint i = 0; i < indent_size; i++)
            spaces.append(" ");
        for (uint i = 0; i < n_lines; i++)
            out.append(spaces + lines[i] + delimiter);
    }

    function _max_table_row_widths(string[][] rows) internal pure returns (uint[] max_widths) {
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
    function _scale(uint32 n, uint32 factor) internal pure returns (string) {
        if (n < factor || factor == 1)
            return format("{}", n);
        (uint d, uint m) = math.divmod(n, factor);
        return d > 10 ? format("{}K", d) : format("{}.{}K", d, m / 100);
    }

    function _month(uint t) internal pure returns (string, uint) {
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
    function _to_date(uint t) internal pure returns (string month, uint day, uint hour, uint minute, uint second) {
        uint t_start;
        (month, t_start) = _month(t);
        uint t0 = t - t_start;
        day = t0 / 86400 + 1;
        uint t1 = t0 % 86400;
        hour = t1 / 3600;
        uint t2 = t1 % 3600;
        minute = t2 / 60;
        second = t2 % 60;
    }

    function _ts(uint t) internal pure returns (string) {
        (string month, uint day, uint hour, uint minute, uint second) = _to_date(t);
        return format("{} {:02} {:02}:{:02}:{:02}", month, day, hour, minute, second);
    }

    /* Network helpers */
    function _to_address(string s_addr) internal pure returns (address addr) {
        uint len = s_addr.byteLength();
        if (len > 60) {
            string s_hex = "0x" + s_addr.substr(2);
            optional(int) u_addr = stoi(s_hex);
            if (u_addr.hasValue())
                return address.makeAddrStd(0, uint(u_addr.get()));
        }
    }

    function _dec_to_oct(uint p, uint width) internal pure returns (string res) {
        for (uint i = 0; i < width; i++) {
            res = format("{}", p & 0x07) + res;
            p >>= 3;
        }
    }

    function _v0(uint i) internal pure returns (string res) {
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

    function _byte_sum(bytes bts, uint offset, uint count) internal pure returns (uint sum) {
        for (uint i = offset; i < offset + count; i++)
            sum += uint8(bytes1(bts[i]));
    }

    function _octal_dump(uint8[] widths, uint[] values) internal pure returns (string) {
        Column[] cf;
        string[] line;
        for (uint i = 0; i < values.length; i++) {
            cf.push(Column(true, widths[i], ALIGN_RIGHT));
            line.push(_dec_to_oct(values[i], widths[i] - 1));
        }
        return _format_table_ext(cf, [line], " ", "\n");
    }

    function _parse_record(string line, string separator) internal pure returns (uint[] values, string[] names, address[] addresses) {
        (string[] fields, ) = stdio.split_line(line, separator, "\n");
        for (string s: fields) {
            uint len = s.byteLength();
            if (len > 65)
                addresses.push(_to_address(s));
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
