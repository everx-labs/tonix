pragma ton-solidity >= 0.49.0;

import "Map.sol";

abstract contract Format is Map {

    struct Column {
        uint16 width;
        uint8 align;
    }
    function _format_field(string s, uint16 width) internal pure returns (string) {
        uint len = s.byteLength();
        if (len > width)
            return s.substr(0, width);
    }

//    function _format_columns(string[] lines, string delimiter, string line_delimiter, uint8 align) internal pure returns (string out) {

    function _format_rows(string[] lines, string delimiter, string line_delimiter, uint8 align) internal pure returns (string out) {
        uint[] max_widths = _max_table_row_widths(lines);
        for (uint i = 0; i < lines.length; i++) {
            string[] fields = _read_entry(lines[i]);
            out.append(_pad(fields[0], max_widths[0], align));
            for (uint j = 1; j < fields.length; j++)
                out.append(delimiter + _pad(fields[j], max_widths[j], align));
            out.append(line_delimiter);
        }
    }

    function _format_table(string text, string delimiter, string line_delimiter, uint8 align) internal pure returns (string out) {
        return _format_rows(_get_lines(text), delimiter, line_delimiter, align);
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
        if (pad == 0) return s; // don't pad
        string sp = _spaces(pad_size);
        if (pad == 1) return sp + s; // right align
        if (pad == 2) return s + sp; // left align
        string spl = _spaces(pad_size / 2);
        string spr = _spaces(pad_size - pad_size / 2);
        if (pad == 3) return spl + s + spr; // center align
    }

    function _max_row_widths(string text) internal pure returns (uint[] max_widths) {
        string[] lines = _get_lines(text);
        string[] fields0 = _read_entry(lines[0]);
        for (uint i = 0; i < fields0.length; i++)
            max_widths.push(fields0[i].byteLength());
        for (uint i = 1; i < lines.length; i++) {
            string[] fields = _read_entry(lines[i]);
            for (uint j = 0; j < fields.length; j++) {
                if (fields[j].byteLength() > max_widths[j])
                    max_widths[j] = fields[j].byteLength();
            }
        }
    }

    function _max_table_row_widths(string[] rows) internal pure returns (uint[] max_widths) {
        string[] fields0 = _read_entry(rows[0]);
        for (uint i = 0; i < fields0.length; i++)
            max_widths.push(fields0[i].byteLength());
        for (uint i = 1; i < rows.length; i++) {
            string[] fields = _read_entry(rows[i]);
            for (uint j = 0; j < fields.length; j++) {
                if (fields[j].byteLength() > max_widths[j])
                    max_widths[j] = fields[j].byteLength();
            }
        }
    }

    function _max_row_width(string[] rows) internal pure returns (uint max_width) {
        max_width = 0;
        for (string s: rows)
            if (s.byteLength() > max_width)
                max_width = s.byteLength();
    }

}
