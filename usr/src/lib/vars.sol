pragma ton-solidity >= 0.62.0;

import "fmt.sol";

struct SHELL_VAR {
    string name;	   // Symbol that the user types.
    string value;	   // Value that is returned.
    string exportstr;  // String for the environment.
    uint16 attributes; // export, readonly, array, invisible...
    uint8 context;	   // Which context this variable belongs to.
}

library vars {

    using libstring for string;
    using vars for string[];

    function check_attrs(string attrs, bytes sattrs, bytes uattrs) internal returns (bool) {
        for (bytes1 sa: sattrs)
            if (str.strchr(attrs, sa) == 0)
                return false;
        for (bytes1 ua: uattrs)
            if (str.strchr(attrs, ua) > 0)
                return false;
        return true;
    }

//    function build_attr_sets(bytes battrs) internal returns (bool any_attr, bytes sattrs, bytes uattrs) {
//        if (battrs.empty())
//            any_attr = true;
//        if (battrs == "--")
//            any_attr = true;
//        if (!any_attr) {
    function build_attr_sets(bytes battrs) internal returns (bytes sattrs, bytes uattrs) {
            bool add_set = false;
            bool add_unset = false;
            for (bytes1 b: battrs) {
                if (add_set) {
                    sattrs.push(b);
                    add_set = false;
                } else if (add_unset) {
                    uattrs.push(b);
                    add_unset = false;
                } else if (b == '+')
                    add_unset = true;
                else if (b == '-')
                    add_set = true;
            }
    }

    function check_name(string name, string word, uint nsym) internal returns (bool) {
        if (nsym == 0)
            return word == name;
        if (name.byteLength() < nsym)
            return false;
        return word == name.substr(0, nsym);
    }

    function filter(string[] page, bytes battrs, string word, bool find_first, bool match_whole) internal returns (string[] res) {
        uint wlen = word.byteLength();
//        bool any_name = wlen == 0;
        uint nsym = match_whole ? 0 : wlen;
//        (bool any_attr, bytes sattrs, bytes uattrs) = build_attr_sets(battrs);
        bool any_attr = battrs.empty();// || battrs == "--";
        bytes sattrs;
        bytes uattrs;
//        if (!any_attr)
//            (sattrs, uattrs) = build_attr_sets(battrs);
        sattrs = battrs;
        for (string line: page) {
            (string attrs, string name, ) = split_var_record(line);
            if (str.strchr(attrs, 'I') == 0 && (any_attr || check_attrs(attrs, sattrs, uattrs)) &&
               (wlen == 0 || check_name(name, word, nsym)))
                    res.push(line);
            if (find_first)
                return res;
        }
    }

    function gen_records(string[] page, bytes1 b, string arg) internal returns (string[] res) {
        uint len = arg.byteLength();
        bool any_name = len == 0;
        bool any_attr = b == '-' || uint8(b) == 0;
        bool match_start = len > 0 && arg.substr(len - 1) == '*';
        for (string line: page) {
            (string attrs, string name, ) = split_var_record(line);
            if ((any_attr || str.strchr(attrs, b) > 0) &&
                    (any_name ||
                    (!match_start && arg == name) ||
                    (match_start && name.byteLength() >= len && arg == name.substr(0, len))))
                res.push(line);
        }
    }

    function gen_match_words(string[] page, string[] names) internal returns (string[] res) {
        for (string line: page) {
            (, string name, ) = split_var_record(line);
            for (string s: names)
                if (s == name)
                    res.push(line);
        }
    }

    function val(string key, string[] page) internal returns (string) {
        string pat = key + "=";
        for (string line: page)
            if (str.strstr(line, pat) > 0) {
                (, , string value) = split_var_record(line);
                return value;
            }
    }

    function int_val(string key, string[] page) internal returns (uint16) {
        return str.toi(val(key, page));
    }

    function array_val(string key, string[] page) internal returns (string[] res) {
        (res, ) = libstring.split(val(key, page), ' ');
    }

    function item_value(string item) internal returns (string, string) {
        return item.csplit("=");
    }

    function match_attr_set(string spart_attrs, string cur_attrs) internal returns (bool) {
        bytes part_attrs = bytes(spart_attrs);
        uint part_attrs_len = part_attrs.length / 2;
        for (uint i = 0; i < part_attrs_len; i++) {
            bytes1 attr_sign = part_attrs[i * 2];
            bytes1 attr_sym = part_attrs[i * 2 + 1];
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
            bytes1 attr_sign = part_attrs[i * 2];
            bytes1 attr_sym = part_attrs[i * 2 + 1];
            bool flag_cur = str.strchr(cur_attrs, attr_sym) > 0;
            if (!flag_cur && attr_sign == "-")
                res.append(string(bytes(attr_sym)));
            else if (flag_cur && attr_sign == "+")
                res = res.translate(string(bytes(attr_sym)), "");
        }
        if (res == "-")
            return "--";
        if (res.byteLength() > 2 && res.substr(0, 2) == "--")
            return res.substr(1);
    }

    function var_record(string attrs, string name, string value) internal returns (string) {
        if (str.strchr(attrs, "f") > 0)
            return name + " ()\n{\n" + value + "}\n";
        if (attrs.empty())
            attrs = "--";
        return attrs + " " + name + "=" + value;
    }

    function split_var_record(string line) internal returns (string, string, string) {
        (string decl, string value) = line.csplit("=");
        if (str.strchr(decl, ' ') > 0) {
            (string attrs, string name) = decl.csplit(" ");
            return (attrs, name, value);
        } else
            return ("", decl, value);
    }

    function get_pool_index(string name, string[] pool) internal returns (uint) {
        string pat = name + "=";
        uint i = 0;
        for (string line: pool) {
            i++;
            if (str.strstr(line, pat) > 0)
                return i;
        }
    }

    function get_token_index(string token, string[] pool) internal returns (uint) {
        (string name, ) = item_value(token);
        return get_pool_index(name, pool);
    }

    function get_pool_record(string name, string[] pool) internal returns (string) {
        string pat = name + "=";
        for (string line: pool)
            if (str.strstr(line, pat) > 0)
                return line;
    }

    function get_best_record(string[] names, string[] pool) internal returns (string) {
        for (string name: names) {
            string res = get_pool_record(name, pool);
            if (!res.empty())
                return res;
        }
    }

    function print_reusable(string line) internal returns (string) {
        (string attrs, string name, string value) = split_var_record(line);
        bool is_function = str.strchr(attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=" + value;
        return is_function ?
            (name + " ()\n{\n" + fmt.indent(value.translate(";", "\n"), 4, "\n") + "}\n") :
            "declare " + attrs + " " + name + var_value + "\n";
    }

    function as_var_list(string sattrs, string[][2] entries) internal returns (string[] res) {
        string sa = sattrs.empty() ? "--" : sattrs;
        sa.append(" ");
        for (string[2] entry: entries)
            res.push(sa + entry[0] + "=" + entry[1]);
    }

    function as_arrayvar(string name, string[] entries) internal returns (string) {
        string body = libstring.join_fields(entries, " ");
        return "-a " + name + "=" + body;
    }

    function get_array_name(string value, string[] context) internal returns (string) {
        for (string line: context) {
            (, string name, string arr_val) = split_var_record(line);
            (string[] items, ) = libstring.split(arr_val, " ");
            for (string item: items)
                if (item == value)
                    return name;
        }
    }

    function get_all_array_names(string value, string[] context) internal returns (string[] res) {
        for (string line: context) {
            (, string name, string arr_val) = split_var_record(line);
            (string[] items, ) = libstring.split(arr_val, " ");
            for (string item: items)
                if (item == value)
                    res.push(name);
        }
    }

    function arrayvar_add(string page, string var_name) internal {
        ( , , string arr_str) = split_var_record(page);
        if (str.strstr(arr_str, var_name) > 0)
            return;
        page.append(" " + var_name);
    }

    function arrayvar_remove(string page, string var_name) internal {
        ( , , string arr_str) = split_var_record(page);
        if (str.strstr(arr_str, var_name) == 0)
            return;
        page.translate(var_name, "");
    }

    function array_add(string[] page, string array_name, string var_name) internal {
        uint arr_idx = get_pool_index(array_name, page);
        if (arr_idx == 0)
            return;
        ( , , string arr_str) = split_var_record(page[arr_idx - 1]);
        uint var_index = str.strstr(arr_str, var_name);
        if (var_index > 0)
            return;
        page[arr_idx - 1].append(" " + var_name);
    }

    function array_remove(string[] page, string array_name, string var_name) internal {
        uint arr_idx = get_pool_index(array_name, page);
        if (arr_idx == 0)
            return;
        ( , , string arr_str) = split_var_record(page[arr_idx - 1]);
        uint var_index = str.strstr(arr_str, var_name);
        if (var_index == 0)
            return;
        page[arr_idx - 1].translate(var_name, "");
    }

    function set_int_val(string[] page, string name, uint value) internal {
        page.set_var("-i", name + "=" + str.toa(value));
    }

    function set_val(string[] page, string name, string value) internal {
        uint cur_index = get_pool_index(name, page);
        if (cur_index == 0) {
            page.push(var_record("", name, value));
            return;
        }
        (string cur_attrs, , ) = split_var_record(page[cur_index - 1]);
        if (str.strchr(cur_attrs, "r") > 0)
            return;
        page[cur_index - 1] = var_record(cur_attrs, name, value);
    }

    function set_var(string[] pg, string attrs, string token) internal {
        (string name, string value) = libstring.csplit(token, '=');
        uint cur_index = get_pool_index(name, pg);
        if (cur_index == 0) {
            pg.push(var_record(attrs, name, value));
            return;
        }
        (string cur_attrs, , string cur_value) = split_var_record(pg[cur_index - 1]);
        if (str.strchr(cur_attrs, "r") > 0)
            return;
        string new_value = !value.empty() ? value : !cur_value.empty() ? cur_value : "";
        pg[cur_index - 1] = var_record(meld_attr_set(attrs, cur_attrs), name, new_value);
    }

    function set_var_attr(string[] pg, string attrs, string name) internal {
        uint cur_index = get_pool_index(name, pg);
        if (cur_index == 0) {
            pg.push(var_record(attrs, name, ""));
            return;
        }
        (string cur_attrs, , string cur_value) = split_var_record(pg[cur_index - 1]);
        pg[cur_index - 1] = var_record(meld_attr_set(attrs, cur_attrs), name, cur_value);
    }

    function set_var_attr_old(string attrs, string name, string[] pg) internal returns (string[] res) {
        uint cur_index = get_pool_index(name, pg);
        if (cur_index == 0) {
            res.push(var_record(attrs, name, ""));
            return res;
        }
        (string cur_attrs, , string cur_value) = split_var_record(pg[cur_index - 1]);
        res[cur_index - 1] = var_record(meld_attr_set(attrs, cur_attrs), name, cur_value);
    }

    function unset_var(string[] pg, string name) internal {
        uint cur_index = get_pool_index(name, pg);
        if (cur_index == 0)
            return;
        (string cur_attrs, , ) = split_var_record(pg[cur_index - 1]);
        if (str.strchr(cur_attrs, "r") > 0)
            return;
//        delete pg[cur_index - 1];
        if (cur_index != pg.length)
            pg[cur_index - 1] = pg[pg.length - 1];
        pg.pop();
    }

    // The various attributes that a given variable can have
    uint16 constant ATTR_EXPORTED   = 0x0001; // export to environment
    uint16 constant ATTR_READONLY   = 0x0002; // cannot change
    uint16 constant ATTR_ARRAY      = 0x0004; // value is an array
    uint16 constant ATTR_FUNCTION   = 0x0008; // value is a function
    uint16 constant ATTR_INTEGER	= 0x0010; // internal representation is int
    uint16 constant ATTR_LOCAL      = 0x0020; // variable is local to a function
    uint16 constant ATTR_ASSOC      = 0x0040; // variable is an associative array
    uint16 constant ATTR_TRACE  	= 0x0080; // function is traced with DEBUG trap
    uint16 constant ATTR_INVISIBLE  = 0x0100; // cannot see
    uint16 constant ATTR_NO_UNSET   = 0x0200; // cannot unset
    uint16 constant ATTR_NO_ASSIGN  = 0x0400; // assignment not allowed
    uint16 constant ATTR_IMPORTED   = 0x0800; // came from environment
    uint16 constant ATTR_SPECIAL    = 0x1000; // requires special handling
    uint16 constant ATTR_TEMP_VAR	= 0x2000; // variable came from the temp environment
    uint16 constant ATTR_PROPAGATE  = 0x4000; // propagate to previous scope
    uint16 constant ATTR_MASK_SCOPE = 0x6000;
    uint16 constant ATTR_MASK_USER  = 0x00FF;
    uint16 constant ATTR_MASK_INT   = 0xFF00;

    function get_mask_ext(bytes sattrs) internal returns (uint16 mask) {
        for (bytes1 b: sattrs) {
            if (b == 'x') mask |= ATTR_EXPORTED;
            if (b == 'r') mask |= ATTR_READONLY;
            if (b == 'a') mask |= ATTR_ARRAY;
            if (b == 'f') mask |= ATTR_FUNCTION;
            if (b == 'i') mask |= ATTR_INTEGER;
            if (b == 'l') mask |= ATTR_LOCAL;
            if (b == 'A') mask |= ATTR_ASSOC;
            if (b == 't') mask |= ATTR_TRACE;
            if (b == 'I') mask |= ATTR_INVISIBLE;
            if (b == 'U') mask |= ATTR_NO_UNSET;
            if (b == 'N') mask |= ATTR_NO_ASSIGN;
            if (b == 'M') mask |= ATTR_IMPORTED;
            if (b == 'S') mask |= ATTR_SPECIAL;
            if (b == 'T') mask |= ATTR_TEMP_VAR;
            if (b == 'P') mask |= ATTR_PROPAGATE;
        }
    }

    /*function mask_base_type(uint16 mask) internal returns (string) {
        if ((mask & ATTR_ARRAY) > 0) return "a";
        if ((mask & ATTR_FUNCTION) > 0) return "f";
        if ((mask & ATTR_ASSOC) > 0) return "A";
        return "-";
    }*/

    function mask_str(uint16 mask) internal returns (string sattrs) {
        bytes battrs = "xrafilAtIUNMSTP";
//        sattrs = mask_base_type(mask);
        uint a = 1;
        for (bytes1 b: battrs) {
            if ((mask & a) > 0)
                sattrs.append(bytes(b));
            a <<= 1;
        }
        return sattrs.empty() ? "--" : sattrs;
        /*(if ((mask & ATTR_INTEGER) > 0) sattrs.append("i");
        if ((mask & ATTR_EXPORTED) > 0) sattrs.append("x");
        if ((mask & ATTR_READONLY) > 0) sattrs.append("r");
        if ((mask & ATTR_LOCAL) > 0) sattrs.append("l");
        if ((mask & ATTR_TRACE) > 0) sattrs.append("t");
        if ((mask & ATTR_INVISIBLE) > 0) sattrs.append("h");
        if (sattrs == "-") sattrs.append("-");*/
    }

    function as_var_record(SHELL_VAR v) internal returns (string) {
        (string name, string value, , uint16 attributes, ) = v.unpack();
        string attrs = mask_str(attributes);
        return var_record(attrs, name, value);
    }

    function as_shell_var(string line) internal returns (SHELL_VAR) {
        (string attrs, string name, string value) = split_var_record(line);
        string exportstr = name + "=" + value;
        return SHELL_VAR(name, value, exportstr, get_mask_ext(attrs), 0);
    }
}
