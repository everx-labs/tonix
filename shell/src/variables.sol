pragma ton-solidity >= 0.55.0;

import "../lib/Format.sol";

abstract contract variables is Format {

    // arrayvar commands
    // hashmaps [function] => command?
    // complete -C ? => hash db
    // hash -l => command path database
    // => hash, tosh, type, complete, command

    uint16 constant IS_STDIN        = 0;
    uint16 constant IS_STDOUT       = 1;
    uint16 constant IS_STDERR       = 2;
    uint16 constant IS_VARIABLE     = 3;    // - -
    uint16 constant IS_TOSH_VAR     = 4;    // - -
    uint16 constant IS_REDIRECT_OP  = 5;
    uint16 constant IS_ARGS         = 5;    // set: tosh read: others
    uint16 constant IS_SPEC         = 6;    // set: tosh read: - ???
    uint16 constant IS_BUILTIN      = 8;    // enable
    uint16 constant IS_COMMAND      = 9;    // - -
    uint16 constant IS_INDEX        = 10;    // used in: hash, tosh, type, complete, command => command type lookup
    uint16 constant IS_DECL         = 11;    // ? ?
    uint16 constant IS_INTEGER      = 16;   // - -
    uint16 constant IS_POOL         = 17;   // - -
    uint16 constant IS_USER         = 18;   // not yet
    uint16 constant IS_BLTN_IN      = 20;   // - -
    uint16 constant IS_BLTN_LINE    = 21;   // - -
    uint16 constant IS_CMD_QUEUE    = 25;
    uint16 constant IS_PIPELINE     = 26;
    uint16 constant IS_FD_TABLE     = 27;
    uint16 constant IS_OPTION_VALUE = 28;
    uint16 constant IS_ERROR_LOG    = 29;
    uint16 constant IS_OPTSTRING    = 30;
    uint16 constant IS_COMP_SPEC    = 31;   // tosh? others? -> binpath?
    uint16 constant IS_BINPATH      = 32;   // command, hash, type -> command lookup => index?
    uint16 constant IS_SHELL_OPTION = 33;
    uint16 constant IS_FILENAME     = 34;
    uint16 constant IS_DIRNAME      = 35;
    uint16 constant IS_POSITIONAL   = 36;
    uint16 constant IS_GROUP        = 37;
    uint16 constant IS_JOB          = 38;
    uint16 constant IS_SERVICE      = 39;
    uint16 constant IS_READONLY     = 40;
    uint16 constant IS_USER_FD      = 40;
    uint16 constant IS_LIMIT        = 41;
    uint16 constant IS_HISTORY      = 42;
    uint16 constant IS_SPECIAL_VAR  = 43;
    uint16 constant IS_HELP_TOPIC   = 44;
    uint16 constant IS_PARAM_LIST   = 45;
    uint16 constant IS_RESERVED_WORD= 46;

    uint8 constant UNDEFINED        = 0;
    uint8 constant DEFAULT_EMPTY    = 1;
    uint8 constant BUILTIN_PRINT    = 2;
    uint8 constant PRINT_REUSABLE   = 3;
    uint8 constant BUILTIN_ADD      = 4;
    uint8 constant BUILTIN_REMOVE   = 5;
    uint8 constant SET_ATTRS        = 6;
    uint8 constant UNSET_ATTRS      = 7;
    uint8 constant APPLY_TO_ALL     = 32;

    // Flags for var_context->flags
    uint16 constant VC_HASLOCAL = 1;
    uint16 constant VC_HASTMPVAR= 2;
    uint16 constant VC_FUNCENV  = 4;	// also function if name != NULL
    uint16 constant VC_BLTNENV  = 8;	// builtin_env
    uint16 constant VC_TEMPENV  = 16;	// temporary_env

    uint16 constant VC_TEMPFLAGS = VC_FUNCENV + VC_BLTNENV + VC_TEMPENV;

    // The various attributes that a given variable can have.
    // First, the user-visible attributes
    uint16 constant ATTR_EXPORTED   = 1; // export to environment
    uint16 constant ATTR_READONLY   = 2; // cannot change
    uint16 constant ATTR_ARRAY      = 4; // value is an array
    uint16 constant ATTR_FUNCTION   = 8; // value is a function
    uint16 constant ATTR_INTEGER	= 16;// internal representation is int
    uint16 constant ATTR_LOCAL      = 32;// variable is local to a function
    uint16 constant ATTR_ASSOC      = 64;// variable is an associative array
    uint16 constant ATTR_TRACE  	= 128;// function is traced with DEBUG trap

    uint16 constant ATTR_MASK_USER  = 255;

    // Internal attributes used for bookkeeping
    uint16 constant ATTR_INVISIBLE  = 256;  // cannot see
    uint16 constant ATTR_NO_UNSET   = 512;	// cannot unset
    uint16 constant ATTR_NO_ASSIGN  = 1024;	// assignment not allowed
    uint16 constant ATTR_IMPORTED   = 2048;	// came from environment
    uint16 constant ATTR_SPECIAL    = 4096;	// requires special handling
    uint16 constant ATTR_MASK_INT   = 0xFF00;

    // Internal attributes used for variable scoping.
    uint16 constant ATTR_TEMP_VAR	= 8192;	// variable came from the temp environment
    uint16 constant ATTR_PROPAGATE  = 16384;// propagate to previous scope
    uint16 constant ATTR_MASK_SCOPE = 24576;

    function _fetch_value(string key, uint16 delimiter, string page) internal pure returns (string value) {
        string key_pattern = _wrap(key, W_SQUARE);
        (string val_pattern_start, string val_pattern_end) = _wrap_symbols(delimiter);
        return _strval(page, key_pattern + "=" + val_pattern_start, val_pattern_end);
    }

    function _val(string key, string page) internal pure returns (string value) {
        return _fetch_value(key, W_DQUOTE, page);
    }

    function _function_body(string key, string page) internal pure returns (string value) {
        return _fetch_value(key, W_BRACE, page);
    }

    function _get_map_value(string map_name, string page) internal pure returns (string value) {
        return _unwrap(_fetch_value(map_name, W_PAREN, page));
    }

    function _item_value(string item) internal pure returns (string, string) {
        (string key, string value) = _strsplit(item, "=");
        return (_unwrap(key), _unwrap(value));
    }

    function _match_attr_set(string part_attrs, string cur_attrs) internal pure returns (bool) {
        uint part_attrs_len = part_attrs.byteLength() / 2;
        for (uint i = 0; i < part_attrs_len; i++) {
            string attr_sign = part_attrs.substr(i * 2, 1);
            string attr_sym = part_attrs.substr(i * 2 + 1, 1);

            bool flag_cur = _strchr(cur_attrs, attr_sym) > 0;
            bool flag_match = (flag_cur && attr_sign == "-");
            if (!flag_match)
                return false;
        }
        return true;
    }

    function _meld_attr_set(string part_attrs, string cur_attrs) internal pure returns (string res) {
        res = cur_attrs;
        uint part_attrs_len = part_attrs.byteLength() / 2;
        for (uint i = 0; i < part_attrs_len; i++) {
            string attr_sign = part_attrs.substr(i * 2, 1);
            string attr_sym = part_attrs.substr(i * 2 + 1, 1);

            bool flag_cur = _strchr(cur_attrs, attr_sym) > 0;
            if (!flag_cur && attr_sign == "-")
                res.append(attr_sym);
            else if (flag_cur && attr_sign == "+")
                res = _translate(res, attr_sym, "");
        }
        if (res == "-")
            return "--";
        if (res.byteLength() > 2 && res.substr(0, 2) == "--")
            return res.substr(1);
    }

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

    function _strrstr(string text, string pattern) internal pure returns (uint) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        if (text_len < pattern_len)
            return 0;
        for (uint i = text_len - pattern_len; i > pattern_len; i--)
            if (text.substr(i, pattern_len) == pattern)
                return i + 1;
    }

    function _str_context(string text, string pattern, string delimiter) internal pure returns (string) {
        uint q = _strstr(text, pattern);
        if (q > 0) {
            uint d_len = delimiter.byteLength();
            string s_head = text.substr(0, q - 1);
            string s_tail = text.substr(q - 1 + pattern.byteLength());

            uint p = _strrstr(s_head, delimiter);
            string s_before = p > 0 ? s_head.substr(p - 1 + d_len) : s_head;
            p = _strstr(s_tail, delimiter);
            string s_after = p > 0 ? s_tail.substr(0, p - 1) : s_tail;
            return s_before + pattern + s_after;
        }
    }

    function _var_record(string attrs, string name, string value) internal pure returns (string) {
        uint16 mask = _get_mask_ext(attrs);
        if (attrs == "")
            attrs = "--";
        bool is_function = _strchr(attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=";
        if (!value.empty())
            var_value.append(_wrap(value, (mask & ATTR_ASSOC + ATTR_ARRAY) > 0 ? W_PAREN : W_DQUOTE));
        return is_function ?
            (name + " () " + _wrap(value, W_FUNCTION)) :
            attrs + " " + _wrap(name, W_SQUARE) + var_value;
    }

    function _split_var_record(string line) internal pure returns (string, string, string) {
        (string decl, string value) = _strsplit(line, "=");
        (string attrs, string name) = _strsplit(decl, " ");
        return (attrs, _unwrap(name), _unwrap(value));
    }

    function _get_pool_record(string name, string pool) internal pure returns (string) {
        string pat = _wrap(name, W_SQUARE);
        (string[] lines, ) = _split(pool, "\n");
        for (string line: lines)
            if (_strstr(line, pat) > 0)
                return line;
    }

    function _print_reusable(string line) internal pure returns (string) {
        (string attrs, string name, string value) = _split_var_record(line);
        bool is_function = _strchr(attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=" + value;
        return is_function ?
            (name + " ()" + _wrap(_indent(_translate(value, ";", "\n"), 4, "\n"), W_FUNCTION)) :
            "declare " + attrs + " " + name + var_value + "\n";
    }

    function _get_mask_ext(string s_attrs) internal pure returns (uint16 mask) {
        uint len = s_attrs.byteLength();
        for (uint i = 0; i < len; i++) {
            string c = s_attrs.substr(i, 1);
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

    function _mask_base_type(uint16 mask) internal pure returns (string s_attrs) {
        if ((mask & ATTR_ARRAY) > 0) return "a";
        if ((mask & ATTR_FUNCTION) > 0) return "f";
        if ((mask & ATTR_ASSOC) > 0) return "A";
        return "-";
    }

    function _mask_str(uint16 mask) internal pure returns (string s_attrs) {
        s_attrs = _mask_base_type(mask);
        if ((mask & ATTR_INTEGER) > 0) s_attrs.append("i");
        if ((mask & ATTR_EXPORTED) > 0) s_attrs.append("x");
        if ((mask & ATTR_READONLY) > 0) s_attrs.append("r");
        if ((mask & ATTR_LOCAL) > 0) s_attrs.append("l");
        if ((mask & ATTR_TRACE) > 0) s_attrs.append("t");
        if (s_attrs == "-") s_attrs.append("-");
    }

    function _wrap_symbols(uint16 to) internal pure returns (string start, string end) {
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
        else if (to == W_FUNCTION)
            return ("", "\n");
    }

    function _wrap(string s, uint16 to) internal pure returns (string res) {
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
        else if (to == W_FUNCTION)
            return "\n{\n" + s + "}\n";
    }

    function _unwrap(string s) internal pure returns (string) {
        uint len = s.byteLength();
        return len > 2 ? s.substr(1, len - 2) : "";
    }

}

