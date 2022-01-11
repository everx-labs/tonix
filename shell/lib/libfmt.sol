pragma ton-solidity >= 0.51.0;

library libfmt {
    uint8 constant ALIGN_NONE   = 0;
    uint8 constant ALIGN_RIGHT  = 1;
    uint8 constant ALIGN_LEFT   = 2;
    uint8 constant ALIGN_CENTER = 3;

    struct Column {
        bool is_visible;
        uint width;
        uint8 align;
    }

    function _format_table_ext(Column[] cf, string[][] lines, string delimiter, string line_delimiter) internal returns (string out) {
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

    function _format_table(string[][] lines, string delimiter, string line_delimiter, uint8 align) internal returns (string out) {
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

    function _spaces(uint n) internal returns (string res) {
        string spaces_16 = "                ";
//        string spaces_4 = "    ";
        for (uint i = 0; i < n / 16; i++)
            res.append(spaces_16);
        if (n % 16 > 0)
            res.append(spaces_16.substr(0, n % 16));
//        string space_field = "                                                                          ";
//        return space_field.substr(0, n);
    }

    function _pad(string s, uint width, uint8 pad) internal returns (string) {
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

    function _max_table_row_widths(string[][] rows) internal returns (uint[] max_widths) {
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

    function _month(uint t) internal returns (string, uint) {
        uint Aug_1st = 1627776000;
        uint Sep_1st = 1630454400;
        uint Oct_1st = 1633046400;
        uint Nov_1st = 1635724800;
        uint Dec_1st = 1638316800;

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

    function _to_date(uint t) internal returns (string month, uint day, uint hour, uint minute, uint second) {
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

    function _ts(uint t) internal returns (string) {
        (string month, uint day, uint hour, uint minute, uint second) = _to_date(t);
        return format("{} {} {:02}:{:02}:{:02}", month, day, hour, minute, second);
    }

}