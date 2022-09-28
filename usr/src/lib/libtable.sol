pragma ton-solidity >= 0.62.0;

import "libstring.sol";

struct s_table {
    uint nrows;
    uint ncols;
    s_table_format format;
    string[][] rows;
}

struct s_table_format {
    uint[] max_width;
    uint[] align;
    string delimiter;
    string line_delimiter;
}
/* Assorted formatting routines */
library libtable {

    using libtable for s_table_format;
    using libstring for string;
    /* Alignment */
    uint8 constant NONE   = 0;
    uint8 constant RIGHT  = 1;
    uint8 constant LEFT   = 2;
    uint8 constant CENTER = 3;

    string constant ZERO_SPACES  = "";
    string constant ONE_SPACE   = " ";
    string constant TWO_SPACES   = "  ";
    string constant THREE_SPACES = "   ";
    string constant FOUR_SPACES  = "    ";

    uint16 constant KILO = 1024;

    function add_row(s_table t, string[] row) internal {
        if (row.length == t.ncols) {
            t.rows.push(row);
            t.nrows++;
        }
    }

    function generic(uint[] max_width, uint def_align) internal returns (s_table) {
        uint ncols = max_width.length;
        string[][] rows;
        uint[] aligns = [ uint(LEFT) ];
        for (uint i = 0; i < ncols - 2; i++)
            aligns.push(def_align);
        aligns.push(LEFT);
        return s_table(0, ncols, s_table_format(max_width, aligns, " ", "\n"), rows);
    }

    function with_header(string[] header, uint[] max_width, uint def_align) internal returns (s_table t) {
        uint h_len = header.length;
        uint n_wid = max_width.length;
        t.ncols = h_len > 0 ? math.min(h_len, n_wid) : n_wid;
        if (h_len > 0) {
            t.rows.push(header);
            t.nrows = 1;
        }
        t.format = def_format(max_width, def_align);
    }

    function table_view(uint[] max_width, uint def_align, string[][] rows) internal returns (string out) {
        uint ncols = max_width.length;
        uint nrows = rows.length;
        if (nrows == 0 || ncols == 0)
            return "";
        uint[] align = [ uint(LEFT) ];
        for (uint i = 0; i < ncols - 2; i++)
            align.push(def_align);
        align.push(LEFT);

        uint[] act_widths;
        for (string s: rows[0])
            act_widths.push(s.byteLength());
        for (uint i = 1; i < nrows; i++) {
            string[] fields = rows[i];
            for (uint j = 0; j < fields.length; j++)
                act_widths[j] = math.max(act_widths[j], fields[j].byteLength());
        }
        for (uint i = 0; i < ncols; i++)
            act_widths[i] = math.min(max_width[i], act_widths[i]);
        for (string[] row: rows) {
            for (uint j = 0; j < ncols; j++) {
                out.append(pad(row[j], act_widths[j], align[j]) + (j + 1 < ncols ? " " : "\n"));
            }
            /*string[] row;
            for (uint j = 0; j < fields.length; j++)
                row.push(pad(fields[j], act_widths[j], align[j]));
            out.append(libstring.join_fields(row, " ") + "\n");
            delete row;*/
        }
    }
    function compute(s_table t) internal returns (string out) {
        (uint nrows, uint ncols, s_table_format tformat, string[][] rows) = t.unpack();
        if (nrows == 0 || ncols == 0)
            return "";
        uint[] act_widths;
        for (string s: rows[0])
            act_widths.push(s.byteLength());
        for (uint i = 1; i < nrows; i++) {
            string[] fields = rows[i];
            for (uint j = 0; j < fields.length; j++)
                act_widths[j] = math.max(act_widths[j], fields[j].byteLength());
        }
        (uint[] max_width, uint[] align, string delimiter, string line_delimiter) = tformat.unpack();
        for (uint i = 0; i < ncols; i++)
            act_widths[i] = math.min(max_width[i], act_widths[i]);

        for (string[] fields: rows) {
            string[] row;
            for (uint j = 0; j < fields.length; j++)
                row.push(pad(fields[j], act_widths[j], align[j]));
            out.append(libstring.join_fields(row, delimiter) + line_delimiter);
            delete row;
        }
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

    function def_format(uint[] max_width, uint def_align) internal returns (s_table_format) {
        uint n_columns = max_width.length;
        uint[] aligns = [ uint(LEFT) ];
        for (uint i = 0; i < n_columns - 2; i++)
            aligns.push(def_align);
        aligns.push(LEFT);
        return s_table_format(max_width, aligns, " ", "\n");
    }

    function apply_format(s_table_format t, string[][] lines) internal returns (string out) {
        if (lines.empty())
            return "";
        t.adjust_width(lines);
        for (string[] fields: lines) {
            for (uint j = 0; j < fields.length; j++)
                out.append((j > 0 ? t.delimiter :"") + pad(fields[j], t.max_width[j], t.align[j]));
            out.append(t.line_delimiter);
        }
    }

    function few_spaces(uint n) internal returns (string) {
        return n == 0 ? ZERO_SPACES : n == 1 ? ONE_SPACE : n == 2 ? TWO_SPACES : n == 3 ? THREE_SPACES : FOUR_SPACES;
    }

    function spaces(uint n) internal returns (string res) {
        if (n < 5)
            return few_spaces(n);
        string spaces_4 = "    ";
        for (uint i = 0; i < n / 4; i++)
            res.append("    ");
        if (n % 4 > 0)
            res.append(spaces_4.substr(0, n % 4));
    }

    function pad(string s, uint width, uint pad_type) internal returns (string) {
        uint len = s.byteLength();
        if (len > width) return s.substr(0, width);
        if (len == width || pad_type == NONE) return s; // don't pad
        uint pad_size = width - len;
        if (pad_type == RIGHT) return spaces(pad_size) + s; // right align
        if (pad_type == LEFT) return s + spaces(pad_size); // left align
        if (pad_type == CENTER) return spaces(pad_size / 2) + s + few_spaces(pad_size - pad_size / 2); // center align
    }

   function adjust_width(s_table_format t, string[][] rows) internal {
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
