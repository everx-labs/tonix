pragma ton-solidity >= 0.53.0;

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

struct Var {
    string name;        // Symbol that the user types
    string decl;        // Declaration string (temp)
    string value;       // Value that is returned
    string export_str;  // String for the environment
    uint16 attributes;  // export, readonly, array, invisible...
    uint16 context;     // Which context this variable belongs to
}

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

    function _export_str(Var v) internal pure returns (string) {
        (string name, string s_attrs, string value, , uint16 mask, ) = v.unpack();
        bool is_function = (mask & ATTR_FUNCTION) > 0;
        string var_value = value.empty() ? "" : "=";
        if (!value.empty())
            var_value.append(_wrap(value, (mask & ATTR_ASSOC + ATTR_ARRAY) > 0 ? W_PAREN : W_DQUOTE));
        return is_function ?
            (name + " () " + _wrap(value, W_FUNCTION)) :
            "declare " + s_attrs + " " + name + var_value + "\n";
    }

    function _pool_str(string s_attrs, string name, string value) internal pure returns (string) {
        uint16 mask = _get_mask_ext(s_attrs);
        bool is_function = _strchr(s_attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=";
        if (!value.empty())
            var_value.append(_wrap(value, (mask & ATTR_ASSOC + ATTR_ARRAY) > 0 ? W_PAREN : W_DQUOTE));
        return is_function ?
            (name + " () " + _wrap(value, W_FUNCTION)) :
            s_attrs + " " + _wrap(name, W_SQUARE) + var_value;
    }

    function _get_pool_record(string name, string pool) internal pure returns (string) {
        string pat = _wrap(name, W_SQUARE);
        (string[] lines, ) = _split(pool, "\n");
        for (string line: lines)
            if (_strstr(line, pat) > 0)
                return line;
    }

    function _print_reusable(string line) internal pure returns (string) {
        (string attrs, string stmt) = _strsplit(line, " ");
        (string name, string value) = _strsplit(stmt, "=");
        name = _unwrap(name);
        bool is_function = _strchr(attrs, "f") > 0;
        string var_value = value.empty() ? "" : "=" + value;
        return is_function ?
            (name + " ()" + _wrap(_indent(_translate(_unwrap(value), ";", "\n"), 4, "\n"), W_FUNCTION)) :
            "declare " + attrs + " " + name + var_value + "\n";
    }

    function _var_ext(string name, string pool) internal pure returns (Var) {
        string cur_record = _get_pool_record(name, pool);
        string attrs;
        string value;
        if (!cur_record.empty()) {
            (attrs, ) = _strsplit(cur_record, " ");
            (, value) = _strsplit(cur_record, "=");
        }
        return Var(name, attrs, value, "", _get_mask_ext(attrs), IS_POOL);
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
            return "( " + s + " )";
        else if (to == W_HASHMAP)
            return "( " + s + " )";
        else if (to == W_FUNCTION)
            return "\n{\n" + s + "\n}\n";
    }

    function _unwrap(string s) internal pure returns (string) {
        uint len = s.byteLength();
        return len > 2 ? s.substr(1, len - 2) : "";
    }

}
// Accessing macros
/*#define vc_isfuncenv(vc)	(((vc)->flags & VC_FUNCENV) != 0)
#define vc_isbltnenv(vc)	(((vc)->flags & VC_BLTNENV) != 0)
#define vc_istempenv(vc)	(((vc)->flags & (VC_TEMPFLAGS)) == VC_TEMPENV)

#define vc_istempscope(vc)	(((vc)->flags & (VC_TEMPENV|VC_BLTNENV)) != 0)

#define vc_haslocals(vc)	(((vc)->flags & VC_HASLOCAL) != 0)
#define vc_hastmpvars(vc)	(((vc)->flags & VC_HASTMPVAR) != 0)

// What a shell variable looks like.

typedef struct variable *sh_var_value_func_t __P((struct variable *));
typedef struct variable *sh_var_assign_func_t __P((struct variable *, char *, arrayind_t));

// For the future
union _value {
  char *s;			// string value
  intmax_t i;		// int value
  COMMAND *f;		// function
  ARRAY *a;			// array
  HASH_TABLE *h;	// associative array
  double d;			// floating point number
  void *v;			// opaque data for future use
};

typedef struct _vlist {
  SHELL_VAR **list;
  int list_size;	// allocated size
  int list_len;		// current number of entries
} VARLIST;


#define exported_p(var)		((((var)->attributes) & (att_exported)))
#define readonly_p(var)		((((var)->attributes) & (att_readonly)))
#define array_p(var)		((((var)->attributes) & (att_array)))
#define function_p(var)		((((var)->attributes) & (att_function)))
#define integer_p(var)		((((var)->attributes) & (att_integer)))
#define local_p(var)		((((var)->attributes) & (att_local)))
#define assoc_p(var)		((((var)->attributes) & (att_assoc)))
#define trace_p(var)		((((var)->attributes) & (att_trace)))

#define invisible_p(var)	((((var)->attributes) & (att_invisible)))
#define non_unsettable_p(var)	((((var)->attributes) & (att_nounset)))
#define noassign_p(var)		((((var)->attributes) & (att_noassign)))
#define imported_p(var)		((((var)->attributes) & (att_imported)))
#define specialvar_p(var)	((((var)->attributes) & (att_special)))

#define tempvar_p(var)		((((var)->attributes) & (att_tempvar)))

/* Acessing variable values: rvalues */
/*#define value_cell(var)		((var)->value)
#define function_cell(var)	(COMMAND *)((var)->value)
#define array_cell(var)		(ARRAY *)((var)->value)

#define var_isnull(var)		((var)->value == 0)
#define var_isset(var)		((var)->value != 0)

/* Assigning variable values: lvalues */
/*#define var_setvalue(var, str)	((var)->value = (str))
#define var_setfunc(var, func)	((var)->value = (char *)(func))
#define var_setarray(var, arr)	((var)->value = (char *)(arr))

/* Make VAR be auto-exported. */
/*#define set_auto_export(var) \
  do { (var)->attributes |= att_exported; array_needs_making = 1; } while (0)

#define SETVARATTR(var, attr, undo) \
	((undo == 0) ? ((var)->attributes |= (attr)) \
		     : ((var)->attributes &= ~(attr)))

#define VSETATTR(var, attr)	((var)->attributes |= (attr))
#define VUNSETATTR(var, attr)	((var)->attributes &= ~(attr))

#define VGETFLAGS(var)		((var)->attributes)

#define VSETFLAGS(var, flags)	((var)->attributes = (flags))
#define VCLRFLAGS(var)		((var)->attributes = 0)

/* Macros to perform various operations on `exportstr' member of a SHELL_VAR. */
/*#define CLEAR_EXPORTSTR(var)	(var)->exportstr = (char *)NULL
#define COPY_EXPORTSTR(var)	((var)->exportstr) ? savestring ((var)->exportstr) : (char *)NULL
#define SET_EXPORTSTR(var, value)  (var)->exportstr = (value)
#define SAVE_EXPORTSTR(var, value) (var)->exportstr = (value) ? savestring (value) : (char *)NULL

#define FREE_EXPORTSTR(var) \
	do { if ((var)->exportstr) free ((var)->exportstr); } while (0)

#define CACHE_IMPORTSTR(var, value) \
	(var)->exportstr = savestring (value)

#define INVALIDATE_EXPORTSTR(var) \
	do { \
	  if ((var)->exportstr) \
	    { \
	      free ((var)->exportstr); \
	      (var)->exportstr = (char *)NULL; \
	    } \
	} while (0)
*/
/* Stuff for hacking variables. */
//typedef int sh_var_map_func_t __P((SHELL_VAR *));

/* Where we keep the variables and functions */
/*extern VAR_CONTEXT *global_variables;
extern VAR_CONTEXT *shell_variables;

extern HASH_TABLE *shell_functions;
extern HASH_TABLE *temporary_env;

extern int variable_context;
extern char *dollar_vars[];
extern char **export_env;

extern void initialize_shell_variables __P((char **, int));
extern SHELL_VAR *set_if_not __P((char *, char *));

extern void sh_set_lines_and_columns __P((int, int));
extern void set_pwd __P((void));
extern void set_ppid __P((void));
extern void make_funcname_visible __P((int));

extern SHELL_VAR *var_lookup __P((const char *, VAR_CONTEXT *));

extern SHELL_VAR *find_function __P((const char *));
extern SHELL_VAR *find_variable __P((const char *));
extern SHELL_VAR *find_variable_internal __P((const char *, int));
extern SHELL_VAR *find_tempenv_variable __P((const char *));
extern SHELL_VAR *copy_variable __P((SHELL_VAR *));
extern SHELL_VAR *make_local_variable __P((const char *));
extern SHELL_VAR *bind_variable __P((const char *, char *));
extern SHELL_VAR *bind_function __P((const char *, COMMAND *));

extern SHELL_VAR **map_over __P((sh_var_map_func_t *, VAR_CONTEXT *));
SHELL_VAR **map_over_funcs __P((sh_var_map_func_t *));
extern SHELL_VAR **all_shell_variables __P((void));
extern SHELL_VAR **all_shell_functions __P((void));
extern SHELL_VAR **all_visible_variables __P((void));
extern SHELL_VAR **all_visible_functions __P((void));
extern SHELL_VAR **all_exported_variables __P((void));
extern SHELL_VAR **local_exported_variables __P((void));
extern SHELL_VAR **all_local_variables __P((void));
#if defined (ARRAY_VARS)
extern SHELL_VAR **all_array_variables __P((void));
#endif
extern char **all_variables_matching_prefix __P((const char *));

extern char **make_var_array __P((HASH_TABLE *));
extern char **add_or_supercede_exported_var __P((char *, int));

extern char *get_variable_value __P((SHELL_VAR *));
extern char *get_string_value __P((const char *));
extern char *sh_get_env_value __P((const char *));
extern char *make_variable_value __P((SHELL_VAR *, char *));

extern SHELL_VAR *bind_variable_value __P((SHELL_VAR *, char *));
extern SHELL_VAR *bind_int_variable __P((char *, char *));
extern SHELL_VAR *bind_var_to_int __P((char *, intmax_t));

extern int assign_in_env __P((const char *));
extern int unbind_variable __P((const char *));
extern int unbind_func __P((const char *));
extern int makunbound __P((const char *, VAR_CONTEXT *));
extern int kill_local_variable __P((const char *));
extern void delete_all_variables __P((HASH_TABLE *));
extern void delete_all_contexts __P((VAR_CONTEXT *));

extern VAR_CONTEXT *new_var_context __P((char *, int));
extern void dispose_var_context __P((VAR_CONTEXT *));
extern VAR_CONTEXT *push_var_context __P((char *, int, HASH_TABLE *));
extern void pop_var_context __P((void));
extern VAR_CONTEXT *push_scope __P((int, HASH_TABLE *));
extern void pop_scope __P((int));

extern void push_context __P((char *, int, HASH_TABLE *));
extern void pop_context __P((void));
extern void push_dollar_vars __P((void));
extern void pop_dollar_vars __P((void));
extern void dispose_saved_dollar_vars __P((void));

extern void adjust_shell_level __P((int));
extern void non_unsettable __P((char *));
extern void dispose_variable __P((SHELL_VAR *));
extern void dispose_used_env_vars __P((void));
extern void dispose_function_env __P((void));
extern void dispose_builtin_env __P((void));
extern void merge_temporary_env __P((void));
extern void merge_builtin_env __P((void));
extern void kill_all_local_variables __P((void));

extern void set_var_read_only __P((char *));
extern void set_func_read_only __P((const char *));
extern void set_var_auto_export __P((char *));
extern void set_func_auto_export __P((const char *));

extern void sort_variables __P((SHELL_VAR **));

extern void maybe_make_export_env __P((void));
extern void update_export_env_inplace __P((char *, int, char *));
extern void put_command_name_into_env __P((char *));
extern void put_gnu_argv_flags_into_env __P((intmax_t, char *));

extern void print_var_list __P((SHELL_VAR **));
extern void print_func_list __P((SHELL_VAR **));
extern void print_assignment __P((SHELL_VAR *));
extern void print_var_value __P((SHELL_VAR *, int));
extern void print_var_function __P((SHELL_VAR *));
*/

