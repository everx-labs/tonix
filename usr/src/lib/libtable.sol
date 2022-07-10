pragma ton-solidity >= 0.61.2;

import "libstring.sol";

struct table_format {
    uint n_columns;
    uint[] width;
    uint[] align;
    string delimiter;
    string line_delimiter;
}
/* Assorted formatting routines */
library libtable {

    using libtable for table_format;
    using libstring for string;
    /* Alignment */
    uint8 constant NONE   = 0;
    uint8 constant RIGHT  = 1;
    uint8 constant LEFT   = 2;
    uint8 constant CENTER = 3;

    uint16 constant KILO = 1024;

    function format_rows(string[][] lines, uint[] max_width, uint def_align) internal returns (string out) {
        if (lines.empty())
            return "";
        uint n_columns = max_width.length;
        uint[] aligns = [ uint(LEFT) ];
        for (uint i = 0; i < n_columns - 2; i++)
            aligns.push(def_align);
        aligns.push(LEFT);
        uint[] max_widths;
        for (string s: lines[0])
            max_widths.push(s.byteLength());
        for (uint i = 1; i < lines.length; i++) {
            string[] fields = lines[i];
            for (uint j = 0; j < fields.length; j++)
                max_widths[j] = math.max(max_widths[j], fields[j].byteLength());
        }
        for (uint i = 0; i < n_columns; i++)
            max_width[i] = math.min(max_width[i], max_widths[i]);
        for (string[] fields: lines) {
            for (uint j = 0; j < fields.length; j++)
                out.append((j > 0 ? " " :"") + pad(fields[j], max_width[j], aligns[j]));
            out.append("\n");
        }
    }

    function def_format(uint[] max_width, uint def_align) internal returns (table_format) {
        uint n_columns = max_width.length;
        uint[] aligns = [ uint(LEFT) ];
        for (uint i = 0; i < n_columns - 2; i++)
            aligns.push(def_align);
        aligns.push(LEFT);
        return table_format(n_columns, max_width, aligns, " ", "\n");
    }

    function apply_format(table_format t, string[][] lines) internal returns (string out) {
        if (lines.empty())
            return "";
        t.adjust_width(lines);
        for (string[] fields: lines) {
            for (uint j = 0; j < fields.length; j++)
                out.append((j > 0 ? t.delimiter :"") + pad(fields[j], t.width[j], t.align[j]));
            out.append(t.line_delimiter);
        }
    }

    function spaces(uint n) internal returns (string res) {
//        string spaces_16 = "                ";
        string spaces_4 = "    ";
        for (uint i = 0; i < n / 4; i++)
            res.append(spaces_4);
        if (n % 4 > 0)
            res.append(spaces_4.substr(0, n % 4));
    }

    function pad(string s, uint width, uint pad_type) internal returns (string) {
        uint len = s.byteLength();
        if (len >= width)
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

   function adjust_width(table_format t, string[][] rows) internal {
        uint[] max_widths;
        for (string s: rows[0])
            max_widths.push(s.byteLength());
        for (uint i = 1; i < rows.length; i++) {
            string[] fields = rows[i];
            for (uint j = 0; j < fields.length; j++)
                max_widths[j] = math.max(max_widths[j], fields[j].byteLength());
        }
        for (uint i = 0; i < t.n_columns; i++)
            t.width[i] = math.min(t.width[i], max_widths[i]);
    }


}
