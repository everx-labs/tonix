pragma ton-solidity >= 0.62.0;

import "libstring.sol";

struct table {
    uint         nrows;
    uint         ncols;
    table_format format;
    string[]     header;
    string[][]   rows;
    string       out;
    string[]     err;
}

struct table_format {
    uint[] max_width;
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

    function add_row(table t, string[] row) internal {
        if (row.length != t.ncols) {
            t.err.push("Row length mismatch");
            return;
        }
        t.rows.push(row);
        t.nrows++;
    }

    function add_header(table t, string[] header, uint[] max_width, uint def_align) internal {
        t.header = header;
        uint ncols = header.length;
        uint n_wid = max_width.length;
        if (ncols != n_wid) {
            t.err.push("Header size mismatch");
            ncols = math.min(ncols, n_wid);
        }
        t.ncols = ncols;
        t.format = def_format(max_width, def_align);
        t.rows.push(header);
        t.nrows = 1;
    }

    function compute(table t) internal {
        string out;
        uint[] act_widths;
        for (string s: t.header)
            act_widths.push(s.byteLength());
        for (uint i = 1; i < t.nrows; i++) {
            string[] fields = t.rows[i];
            for (uint j = 0; j < fields.length; j++)
                act_widths[j] = math.max(act_widths[j], fields[j].byteLength());
        }

        for (uint i = 0; i < t.ncols; i++)
            act_widths[i] = math.min(t.format.max_width[i], act_widths[i]);

        for (string[] fields: t.rows) {
            string[] row;
            for (uint j = 0; j < fields.length; j++) {
//                out.append((j > 0 ? " " :"") + pad(fields[j], act_widths[j], t.format.align[j]) + "\n");
                row.push(pad(fields[j], act_widths[j], t.format.align[j]));
            }
            out.append(libstring.join_fields(row, t.format.delimiter) + t.format.line_delimiter);
            delete row;
        }
        for (string s: t.err)
            out.append(s + '\n');
        t.out = out;
    }

    function format_rows(string[][] lines, uint[] max_width, uint def_align) internal returns (string out) {
        string errs;
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
        uint actual_n_columns = max_widths.length;
        if (actual_n_columns < n_columns) {
            errs.append("Table header is wider than the table\n");
            n_columns = actual_n_columns;
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
        return table_format(max_width, aligns, " ", "\n");
    }

    function apply_format(table_format t, string[][] lines) internal returns (string out) {
        if (lines.empty())
            return "";
        t.adjust_width(lines);
        for (string[] fields: lines) {
            for (uint j = 0; j < fields.length; j++)
                out.append((j > 0 ? t.delimiter :"") + pad(fields[j], t.max_width[j], t.align[j]));
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
        string[] header = rows[0];
        uint n_columns = header.length;
        for (string s: header)
            max_widths.push(s.byteLength());
        for (uint i = 1; i < rows.length; i++) {
            string[] fields = rows[i];
            for (uint j = 0; j < fields.length; j++)
                max_widths[j] = math.max(max_widths[j], fields[j].byteLength());
        }
        for (uint i = 0; i < n_columns; i++)
            t.max_width[i] = math.min(t.max_width[i], max_widths[i]);
    }
}
