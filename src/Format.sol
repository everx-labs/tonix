pragma ton-solidity >= 0.49.0;

import "Map.sol";

/* Table formatting routines */
abstract contract Format is Map {

    uint8 constant ALIGN_NONE   = 0;
    uint8 constant ALIGN_RIGHT  = 1;
    uint8 constant ALIGN_LEFT   = 2;
    uint8 constant ALIGN_CENTER = 3;

    struct Column {
        uint16 width;
        uint8 align;
    }

    function _format_table(string[][] lines, string delimiter, string line_delimiter, uint8 align) internal pure returns (string out) {
        uint[] max_widths = _max_table_row_widths(lines);
        uint n_rows = lines.length;
        for (uint i = 0; i < n_rows; i++) {
            string[] fields = lines[i];
            out.append(_pad(fields[0], max_widths[0], ALIGN_LEFT));
            uint len = fields.length;
            for (uint j = 1; j < len; j++)
                out.append(delimiter + _pad(fields[j], max_widths[j], (j == len - 1) ? ALIGN_LEFT : align));
            out.append(line_delimiter);
        }
    }

    function _spaces(uint n) internal pure returns (string) {
        string space_field = "                                                                                            ";
        return space_field.substr(0, n);
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

    function _max_table_row_widths(string[][] rows) internal pure returns (uint[] max_widths) {
        string[] fields0 = rows[0];
        for (uint i = 0; i < fields0.length; i++)
            max_widths.push(fields0[i].byteLength());
        for (uint i = 1; i < rows.length; i++) {
            string[] fields = rows[i];
            for (uint j = 0; j < fields.length; j++)
                if (fields[j].byteLength() > max_widths[j])
                    max_widths[j] = fields[j].byteLength();
        }
    }
}
