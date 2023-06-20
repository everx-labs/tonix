pragma ton-solidity >= 0.68.0;
import "types.h";

library libprint {
    function println(string[] dst, string src) internal {
        dst.push(src);
    }
    function print_lines(string[] dst, string[] src) internal {
        for (string s: src)
            dst.push(s);
    }
    function print_block(string[] dst, string header, string[] body, string footer) internal {
        dst.push("\n" + header);
        for (string s: body)
            dst.push("    " + s);
        dst.push(footer + "\n");
    }
    function print_function(string[] dst, string header, string[] body, string[] nested) internal {
        dst.push("\n    " + header);
        for (string s: body)
            dst.push("        " + s);
        for (string s: nested)
            dst.push("            " + s);
        dst.push("    }");
    }
    function print_list(string[] dst, string[] src, string delim, string prefix, string suffix) internal {
        dst.push(prefix + array_list(src, delim) + suffix);
    }
    function print_items(string[] dst, string[] src, string delim, string prefix, string header, string suffix) internal {
        string line = src[0] + header;
        for (uint i = 1; i < src.length; i++)
            line.append(delim + src[i]);
        dst.push(prefix + delim + line + suffix);
    }
    function print_lists(string[] dst, string[] src1, string[] src2, string fs, string rs, string prefix, string suffix) internal {
        dst.push(prefix + join_lists(src1, src2, fs, rs) + suffix);
    }
    function print_table(string[] dst, string[][] cols, string field_delim, string row_pref, string row_suf, string table_pref, string table_suf) internal {
        uint ncol = cols.length;
        uint nrow = cols[0].length;
        dst.push(table_pref);
        for (uint i = 0; i < nrow; i++) {
            string line = cols[0][i];
            for (uint j = 1; j < ncol; j++)
                line.append(field_delim + cols[j][i]);
            dst.push(row_pref + line + row_suf);
        }
        dst.push(table_suf + "\n");
    }
    function array_list(string[] src, string delim) internal returns (string line) {
        line = src[0];
        for (uint i = 1; i < src.length; i++)
            line.append(delim + src[i]);
    }
    function join_lists(string[] src1, string[] src2, string fs, string rs) internal returns (string line) {
        line = src1[0] + fs + src2[0];
        for (uint i = 1; i < src1.length; i++)
            line.append(rs + src1[i] + fs + src2[i]);
    }
}
library libgen {
    using libprint for string[];

    function gen_toString(a_type ta, string[] vnames, a_type[] va) internal returns (string[] body, string[] nested) {
        (uint attr, string name) = ta.unpack();
        string[] tnames;
        uint8[] tattrs;
        for (a_type t: va) {
            (uint8 tattr, string tname) = t.unpack();
            tnames.push(tname);
            tattrs.push(tattr);
        }
        if (attr == ENUM) {
            body.println("if (val == " + name + "." + vnames[0] + ") out.append(\"" + vnames[0] + "\");");
            for (uint j = 1; j < vnames.length; j++)
                nested.println("else if (val == " + name + "." + vnames[j] + ") out.append(\"" + vnames[j] + "\");");
        } else if (attr == ARRAY) {
            body.println("for (uint i = 0; i < val.length; i++)");
            nested.println("out.append(" + print_name("val[i]", tattrs[0], true) + ");");
        } else if (attr == MAP) {
            body.println("for ((" + tnames[0] + " key, " + tnames[1] +  " value): val)");
            nested.println("out.append(" + print_name("key", tattrs[0], true) + " + \" => \" + " + print_name("value", tattrs[1], true) + ");");
        } else if (attr == STRUCT) {
            string[] psn;
            for (uint i = 0; i < va.length; i++)
                psn.push(print_name(vnames[i], tattrs[i], false));
            body.print_lists(tnames, vnames, " ", ", ", "(", ") = val.unpack();");
            body.print_list(_strcat(vnames, ": {}"), " ", "out.append(format(\"", "\", ");
            nested.print_list(psn, ", ", "", "));");
        }
    }
    function print_name(string name, uint attr, bool formatted) internal returns (string res) {
        return
            attr == CELL   ? "tvm.hash(" + name + ")" :
            attr == BOOL   ? "(" + name + " ? \"Yes\" : \"No\")" :
            attr == BYTES  ? "string(bytes(" + name + "))" :
            attr == STRUCT || attr == MAP || attr == ARRAY || attr == ENUM ? name + ".toString()" :
            formatted ? "format(\"{}\", " + name + ")" : name;
    }
    function fix_arr_name(bytes sname) internal returns (string res) {
        uint q1 = strchr(sname, '[');
        uint q2 = strchr(sname, ']');
        if (q1 > 0 && q2 > 0)
            res = string(sname[ : q1 - 1]) + "s";
    }
    function fix_map_name(bytes sname) internal  returns (string res) {
        uint q1 = strchr(sname, '(');
        uint q2 = strchr(sname, ')');
        uint q3 = strchr(sname, '=');
        uint q4 = strchr(sname, '>');
        if (q1 > 0 && q2 > 0 && q3 > 0 && q4 > 0)
            res = string(sname[q1 : q3 - 2]) + "to" + string(sname[q4 + 1 : q2 - 1]);
    }
}
function _strcat(string[] fields, string prefix, string suffix) returns (string[] res) {
    for (string s: fields)
        res.push(prefix + s + suffix);
}
function _strcat(string[] fields, string suffix) returns (string[] res) {
    for (string s: fields)
        res.push(s + suffix);
}


