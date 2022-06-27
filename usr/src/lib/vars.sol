pragma ton-solidity >= 0.61.2;

import "fmt.sol";

library vars {

    using libstring for string;

    // The various attributes that a given variable can have
    uint16 constant ATTR_EXPORTED   = 1; // export to environment
    uint16 constant ATTR_READONLY   = 2; // cannot change
    uint16 constant ATTR_ARRAY      = 4; // value is an array
    uint16 constant ATTR_FUNCTION   = 8; // value is a function
    uint16 constant ATTR_INTEGER	= 16;// internal representation is int
    uint16 constant ATTR_LOCAL      = 32;// variable is local to a function
    uint16 constant ATTR_ASSOC      = 64;// variable is an associative array
    uint16 constant ATTR_TRACE  	= 128;// function is traced with DEBUG trap
    uint16 constant ATTR_MASK_USER  = 255;
    uint16 constant ATTR_INVISIBLE  = 256;  // cannot see
    uint16 constant ATTR_NO_UNSET   = 512;	// cannot unset
    uint16 constant ATTR_NO_ASSIGN  = 1024;	// assignment not allowed
    uint16 constant ATTR_IMPORTED   = 2048;	// came from environment
    uint16 constant ATTR_SPECIAL    = 4096;	// requires special handling
    uint16 constant ATTR_MASK_INT   = 0xFF00;
    uint16 constant ATTR_TEMP_VAR	= 8192;	// variable came from the temp environment
    uint16 constant ATTR_PROPAGATE  = 16384;// propagate to previous scope
    uint16 constant ATTR_MASK_SCOPE = 24576;

    uint16 constant W_NONE      = 0;
    uint16 constant W_COLON     = 1;
    uint16 constant W_DQUOTE    = 2;
    uint16 constant W_PAREN     = 3;
    uint16 constant W_BRACE     = 4;
    uint16 constant W_SQUARE    = 5;
    uint16 constant W_SPACE     = 6;
    uint16 constant W_NEWLINE   = 7;
    uint16 constant W_SQUOTE    = 8;
    uint16 constant W_ARRAY     = 9;
    uint16 constant W_HASHMAP   = 10;
    uint16 constant W_FUNCTION  = 11;
    uint16 constant W_ATTR_HASHMAP   = 12;

    function fetch_value(string key, uint16 delimiter, string page) internal returns (string) {
        string key_pattern = wrap(key, W_SQUARE);
        (string val_pattern_start, string val_pattern_end) = wrap_symbols(delimiter);
        return page.val(key_pattern + "=" + val_pattern_start, val_pattern_end);
    }

    function val(string key, string page) internal returns (string) {
        return fetch_value(key, W_DQUOTE, page);
    }

    function int_val(string key, string page) internal returns (uint16) {
        return str.toi(fetch_value(key, W_DQUOTE, page));
    }

    function function_body(string key, string page) internal returns (string) {
        return fetch_value(key, W_BRACE, page);
    }

    function get_map_value(string map_name, string page) internal returns (string) {
        string s = fetch_value(map_name, W_PAREN, page);
        return str.unwrp(s);
    }

    function item_value(string item) internal returns (string, string) {
        (string key, string value) = item.csplit("=");
        return (str.unwrp(key), str.unwrp(value));
    }

    function match_attr_set(string spart_attrs, string cur_attrs) internal returns (bool) {
//        uint part_attrs_len = part_attrs.byteLength() / 2;
//        for (uint i = 0; i < part_attrs_len; i++) {
//            string attr_sign = part_attrs.substr(i * 2, 1);
//            string attr_sym = part_attrs.substr(i * 2 + 1, 1);
        bytes part_attrs = bytes(spart_attrs);
        uint part_attrs_len = part_attrs.length / 2;
        for (uint i = 0; i < part_attrs_len; i++) {
//            string attr_sign = part_attrs.substr(i * 2, 1);
//            string attr_sym = part_attrs.substr(i * 2 + 1, 1);
            byte attr_sign = part_attrs[i * 2];
            byte attr_sym = part_attrs[i * 2 + 1];

            bool flag_cur = str.strchr(cur_attrs, attr_sym) > 0;
            bool flag_match = (flag_cur && attr_sign == "-");
            if (!flag_match)
                return false;
        }
        return true;
    }

    function meld_attr_set(string spart_attrs, string cur_attrs) internal returns (string res) {
        res = cur_attrs;
        bytes part_attrs = bytes(spart_attrs);
        uint part_attrs_len = part_attrs.length / 2;
        for (uint i = 0; i < part_attrs_len; i++) {
//            string attr_sign = part_attrs.substr(i * 2, 1);
//            string attr_sym = part_attrs.substr(i * 2 + 1, 1);
            byte attr_sign = part_attrs[i * 2];
            byte attr_sym = part_attrs[i * 2 + 1];
            bool flag_cur = str.strchr(cur_attrs, attr_sym) > 0;
            if (!flag_cur && attr_sign == "-")
                res.append(string(attr_sym));
            else if (flag_cur && attr_sign == "+")
                res = res.translate(string(attr_sym), "");
        }
        if (res == "-")
            return "--";
        if (res.byteLength() > 2 && res.substr(0, 2) == "--")
            return res.substr(1);
    }

    function var_record(string attrs, string name, string value) internal returns (string) {
        uint16 mask = get_mask_ext(attrs);
        if (attrs == "")
            attrs = "--";
        bool is_function = str.strchr(attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=";
        if (!value.empty())
            var_value.append(wrap(value, (mask & ATTR_ASSOC + ATTR_ARRAY) > 0 ? W_PAREN : W_DQUOTE));
        return is_function ?
            (name + " () " + wrap(value, W_FUNCTION)) :
            attrs + " " + wrap(name, W_SQUARE) + var_value;
    }

    function split_var_record(string line) internal returns (string, string, string) {
        (string decl, string value) = line.csplit("=");
        (string attrs, string name) = decl.csplit(" ");
        return (attrs, str.unwrp(name), str.unwrp(value));
    }

    function get_pool_record(string name, string pool) internal returns (string) {
        string pat = wrap(name, W_SQUARE);
        (string[] lines, ) = pool.split("\n");
        for (string line: lines)
            if (str.strstr(line, pat) > 0)
                return line;
    }

    function print_reusable(string line) internal returns (string) {
        (string attrs, string name, string value) = split_var_record(line);
        bool is_function = str.strchr(attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=" + value;
        return is_function ?
            (name + " ()" + wrap(fmt.indent(value.translate(";", "\n"), 4, "\n"), W_FUNCTION)) :
            "declare " + attrs + " " + name + var_value + "\n";
    }

    function as_var_list(string sattrs, string[][2] entries) internal returns (string res) {
        string sa = sattrs.empty() ? "--" : sattrs;
        sa.append(" ");
        for (uint i = 0; i < entries.length; i++)
            res.append(sa + wrap(entries[i][0], W_SQUARE) + (entries[i][1].empty() ? "" : ("=" + wrap(entries[i][1], W_DQUOTE))) + "\n");
    }

    function as_hashmap(string name, string[][2] entries) internal returns (string) {
        string body;
        for (uint i = 0; i < entries.length; i++)
            body.append(wrap(entries[i][0], W_SQUARE) + "=" + wrap(entries[i][1], W_DQUOTE) + " ");
        return "-A " + wrap(name, W_SQUARE) + "=" + wrap(body, W_HASHMAP);
    }

    function as_indexed_array(string name, string value, string ifs) internal returns (string) {
        string body;
        (string[] fields, uint n_fields) = value.split(ifs);
        for (uint i = 0; i < n_fields; i++)
            body.append(format("[{}]=\"{}\" ", i, fields[i]));
        return "-a " + wrap(name, W_SQUARE) + "=" + wrap(body, W_ARRAY);
    }

    function encode_item(string key, string value) internal returns (string) {
        return wrap(key, W_SQUARE) + "=" + wrap(value, W_DQUOTE);
    }

    function as_attributed_hashmap(string name, string value) internal returns (string) {
        return "-A " + wrap(name, W_SQUARE) + "=" + wrap(value, W_ATTR_HASHMAP);
    }

    function as_map(string value) internal returns (string res) {
        res = wrap(value, W_HASHMAP);
    }

    function get_array_name(string value, string context) internal returns (string) {
        (string[] lines, ) = context.split("\n");
        string val_pattern = wrap(value, vars.W_SPACE);
        for (string line: lines)
            if (str.strstr(line, val_pattern) > 0)
                return line.val("[", "]");
    }

    function set_item_value(string name, string value, string page) internal returns (string) {
        string cur_value = val(name, page);
        string new_record = encode_item(name, value);
        return cur_value.empty() ? page + " " + new_record : page.translate(encode_item(name, cur_value), new_record);
    }

    function set_var(string attrs, string token, string pg) internal returns (string) {
        (string name, string value) = token.csplit("=");
        string cur_record = get_pool_record(name, pg);
        string new_record = var_record(attrs, name, value);
        if (cur_record.empty())
            return pg + new_record + "\n";

        (string cur_attrs, , string cur_value) = split_var_record(cur_record);
        if (str.strchr(cur_attrs, "r") > 0)
            return pg;

        cur_value = str.unwrp(cur_value);
        string new_value = !value.empty() ? value : !cur_value.empty() ? cur_value : "";
        new_record = var_record(meld_attr_set(attrs, cur_attrs), name, new_value);
        return pg.translate(cur_record, new_record);
    }

    function set_var_attr(string attrs, string name, string pg) internal returns (string) {
        string cur_record = get_pool_record(name, pg);
        if (cur_record.empty())
            return pg + var_record(attrs, name, "") + "\n";

        (string cur_attrs, , string cur_value) = split_var_record(cur_record);
        string new_record = var_record(meld_attr_set(attrs, cur_attrs), name, cur_value);
        return pg.translate(cur_record, new_record);
    }

    function unset_var(string name, string pg) internal returns (string) {
        string cur_record = get_pool_record(name, pg);
        if (cur_record.empty())
            return pg;
        (string cur_attrs, , ) = split_var_record(cur_record);
        if (str.strchr(cur_attrs, "r") > 0)
            return pg;
        else
            return pg.translate(cur_record + "\n", "");
    }

    function get_mask_ext(string sattrs) internal returns (uint16 mask) {
        for (uint i = 0; i < sattrs.byteLength(); i++) {
            string c = sattrs.substr(i, 1);
            if (c == "x") mask |= ATTR_EXPORTED;
            if (c == "r") mask |= ATTR_READONLY;
            if (c == "a") mask |= ATTR_ARRAY;
            if (c == "f") mask |= ATTR_FUNCTION;
            if (c == "i") mask |= ATTR_INTEGER;
            if (c == "l") mask |= ATTR_LOCAL;
            if (c == "A") mask |= ATTR_ASSOC;
            if (c == "t") mask |= ATTR_TRACE;
        }
    }

    function mask_base_type(uint16 mask) internal returns (string) {
        if ((mask & ATTR_ARRAY) > 0) return "a";
        if ((mask & ATTR_FUNCTION) > 0) return "f";
        if ((mask & ATTR_ASSOC) > 0) return "A";
        return "-";
    }

    function mask_str(uint16 mask) internal returns (string sattrs) {
        sattrs = mask_base_type(mask);
        if ((mask & ATTR_INTEGER) > 0) sattrs.append("i");
        if ((mask & ATTR_EXPORTED) > 0) sattrs.append("x");
        if ((mask & ATTR_READONLY) > 0) sattrs.append("r");
        if ((mask & ATTR_LOCAL) > 0) sattrs.append("l");
        if ((mask & ATTR_TRACE) > 0) sattrs.append("t");
        if (sattrs == "-") sattrs.append("-");
    }

    function wrap_symbols(uint16 to) internal returns (string, string) {
        if (to == W_COLON)
            return (":", ":");
        else if (to == W_DQUOTE)
            return ("\"", "\"");
        else if (to == W_PAREN)
            return ("(", ")");
        else if (to == W_BRACE)
            return ("{", "}");
        else if (to == W_SQUARE)
            return ("[", "]");
        else if (to == W_SPACE)
            return (" ", " ");
        else if (to == W_NEWLINE)
            return ("\n", "\n");
        else if (to == W_SQUOTE)
            return ("\'", "\'");
        else if (to == W_ARRAY)
            return ("( ", " )");
        else if (to == W_HASHMAP)
            return ("( ", " )");
        else if (to == W_ATTR_HASHMAP)
            return ("(\n", " )\n");
        else if (to == W_FUNCTION)
            return ("", "\n");
    }

    function wrap(string s, uint16 to) internal returns (string) {
        if (to == W_COLON)
            return ":" + s + ":";
        else if (to == W_DQUOTE)
            return "\"" + s + "\"";
        else if (to == W_PAREN)
            return "(" + s + ")";
        else if (to == W_BRACE)
            return "{" + s + "}";
        else if (to == W_SQUARE)
            return "[" + s + "]";
        else if (to == W_SPACE)
            return " " + s + " ";
        else if (to == W_NEWLINE)
            return "\n" + s + "\n";
        else if (to == W_SQUOTE)
            return "\'" + s + "\'";
        else if (to == W_ARRAY)
            return "( " + s + ")";
        else if (to == W_HASHMAP)
            return "( " + s + ")";
        else if (to == W_ATTR_HASHMAP)
            return "(\n" + s + " )\n";
        else if (to == W_FUNCTION)
            return "\n{\n" + s + "}\n";
    }
}
