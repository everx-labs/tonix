pragma ton-solidity >= 0.55.0;

import "../include/Internal.sol";
import "../lib/stdio.sol";
import "../lib/vars.sol";
import "../lib/arg.sol";

struct Job {
    uint16 id;
    uint16 parent_id;
    uint16[] sub_jobs;
    string status;
    string stdin;
    string stdout;
    string stderr;
    string s_input;
    string name;
    string cmd_type;
    string s_args;
    string[] args;
    string short_options;
    string[] long_options;
    string stdin_redirect;
    string stdout_redirect;
    string s_action;
    string script;
    uint16 ec;
}

struct BuiltinHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string arguments;
    string exit_status;
}

struct CommandHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string notes;
    string author;
    string bugs;
    string see_also;
    string version;
}

struct Item {
    string name;
    uint16 attrs;
    string value;
}

struct ItemHashMap {
    string name;
    uint16 attrs;
    mapping (uint => Item) value;
}

struct Write {
    uint16 fd;
    string text;
    uint16 mask;
}

struct En {
    string index;
    Item[] aliases;
}

abstract contract Shell is Internal {

//    uint8 constant EPERM   = 1;  // Operation not permitted
//    uint8 constant ENOENT  = 2;  // No such file or directory
    uint8 constant ESRCH   = 3;  // No such process
    uint8 constant EINTR   = 4;  // Interrupted system call
    uint8 constant EIO     = 5;  // I/O error
    uint8 constant ENXIO   = 6;  // No such device or address
    uint8 constant E2BIG   = 7;  // Argument list too long
    uint8 constant ENOEXEC = 8;  // Exec format error
//    uint8 constant EBADF   = 9;  // Bad file number
    uint8 constant ECHILD  = 10; // No child processes
    uint8 constant EAGAIN  = 11; // Try again
    uint8 constant ENOMEM  = 12; // Out of memory
//    uint8 constant EACCES  = 13; // Permission denied
//    uint8 constant EFAULT  = 14; // Bad address
    uint8 constant ENOTBLK = 15; // Block device required
//    uint8 constant EBUSY   = 16; // Device or resource busy
//    uint8 constant EEXIST  = 17; // File exists
    uint8 constant EXDEV   = 18; // Cross-device link
    uint8 constant ENODEV  = 19; // No such device
//    uint8 constant ENOTDIR = 20; // Not a directory
//    uint8 constant EISDIR  = 21; // Is a directory
//    uint8 constant EINVAL  = 22; // Invalid argument
    uint8 constant ENFILE  = 23; // File table overflow
    uint8 constant EMFILE  = 24; // Too many open files
    uint8 constant ENOTTY  = 25; // Not a typewriter
    uint8 constant ETXTBSY = 26; // Text file busy
    uint8 constant EFBIG   = 27; // File too large
    uint8 constant ENOSPC  = 28; // No space left on device
    uint8 constant ESPIPE  = 29; // Illegal seek
//    uint8 constant EROFS   = 30; // Read-only file system
    uint8 constant EMLINK  = 31; // Too many links
    uint8 constant EPIPE   = 32; // Broken pipe
    uint8 constant EDOM    = 33; // Math argument out of domain of func
    uint8 constant ERANGE  = 34; // Math result not representable

    uint16 constant TYPE_STRING          = 0;
    uint16 constant TYPE_INDEXED_ARRAY   = 1;
    uint16 constant TYPE_HASHMAP         = 2;
    uint16 constant TYPE_FUNCTION        = 3;
    /*uint16 constant ATTR_INDEXED_ARRAY   = 4;
    uint16 constant ATTR_INTEGER         = 8;
    uint16 constant ATTR_READONLY        = 16;
    uint16 constant ATTR_REFERENCE       = 32;
    uint16 constant ATTR_TRACE           = 64;
    uint16 constant ATTR_EXPORT          = 128;
    uint16 constant ATTR_DISABLED        = 512;*/

    uint16 constant ACT_NO_OP           = 0;
    uint16 constant ACT_EXEC_BUILTIN    = 1;
    uint16 constant ACT_PROCESS_JOB     = 2;
    uint16 constant ACT_READ_FS         = 3;
    uint16 constant ACT_READ_FS_TO_ENV  = 4;
    uint16 constant ACT_FSTAT           = 5;
    uint16 constant ACT_INDUCE          = 6;
    uint16 constant ACT_EXEC            = 7;
    uint16 constant ACT_UADM            = 8;
    uint16 constant ACT_USTAT           = 9;
    uint16 constant ACT_ALTER           = 10;
    uint16 constant ACT_AUTHORIZE       = 11;
    uint16 constant ACT_FORMAT_BUILTIN_HELP = 12;

    uint16 constant O_RDONLY    = 0;
    uint16 constant O_WRONLY    = 1;
    uint16 constant O_RDWR      = 2;
    uint16 constant O_ACCMODE   = 3;
    uint16 constant O_LARGEFILE = 16;
    uint16 constant O_DIRECTORY = 32;   // must be a directory
    uint16 constant O_NOFOLLOW  = 64;   // don't follow links
    uint16 constant O_CLOEXEC   = 128;  // set close_on_exec
    uint16 constant O_CREAT     = 256;
    uint16 constant O_EXCL      = 512;
    uint16 constant O_NOCTTY    = 1024;
    uint16 constant O_TRUNC     = 2048;
    uint16 constant O_APPEND    = 4096;
    uint16 constant O_NONBLOCK  = 8192;
    uint16 constant O_DSYNC     = 16384;
    uint16 constant FASYNC      = 32768;
    /* Handling variables:
     *
     * Declare: associate the name with a base type (string, set, indexed array or hashmap)
     * Scope: define visibility of the variable
     * Set attributes: append attributes to the base type
     * Define: associate variable with a context
     *         allocate storage for the variable according to the attributes
     * Dereference:
     * Assign:
     */

    uint16 constant VAR_RAW_LINE    = 1;    // Print as it's internally stored
    uint16 constant VAR_DEFAULT     = 2;    // As it is printed by the command with no args (may vary)
    uint16 constant VAR_REUSABLE    = 3;    // "reusable" format, supplied with -p
    uint16 constant VAR_ASSIGN      = 4;    // name=value, no attrs
    uint16 constant VAR_NAME_ONLY   = 5;
    uint16 constant VAR_AS_ARRAY    = 6;
    uint16 constant VAR_AS_HASHMAP  = 7;
    uint16 constant VAR_OMIT_ATTRS  = 16;
    uint16 constant VAR_OMIT_NAME   = 32;
    uint16 constant VAR_OMIT_VALUE  = 64;

    // Flags for describe_command
    uint16 constant CDESC_ALL       = 1; // type -a
    uint16 constant CDESC_SHORTDESC = 2; // command -V
    uint16 constant CDESC_REUSABLE  = 4; // command -v
    uint16 constant CDESC_TYPE      = 8; // type -t
    uint16 constant CDESC_PATH_ONLY = 16; // type -p
    uint16 constant CDESC_FORCE_PATH= 32; // type -ap or type -P
    uint16 constant CDESC_NOFUNCS   = 64; // type -f

    int8 constant NO_PIPE = 1;
    int8 constant REDIRECT_BOTH = -2;

    int8 constant NO_VARIABLE = -1;

    // Special exit statuses used by the shell, internally and externally
    uint8 constant EX_BINARY_FILE   = 126;
    uint8 constant EX_NOEXEC        = 127;
    uint8 constant EX_NOINPUT       = 128;
    uint8 constant EX_NOTFOUND      = 129;

    uint8 constant EX_SHERRBASE     = 192;	//all special error values are > this

    uint8 constant EX_BADSYNTAX     = 193;	// shell syntax error
    uint8 constant EX_USAGE         = 194;	// syntax error in usage
    uint8 constant EX_REDIRFAIL     = 195;	// redirection failed
    uint8 constant EX_BADASSIGN     = 196;	// variable assignment error
    uint8 constant EX_EXPFAIL       = 197;	// word expansion failed

// Flag values that control parameter pattern substitution
    uint8 constant MATCH_ANY        = 0;
    uint8 constant MATCH_BEG        = 1;
    uint8 constant MATCH_END        = 2;

    uint8 constant MATCH_TYPEMASK   = 3;

    uint8 constant MATCH_GLOBREP    = 16;
    uint8 constant MATCH_QUOTED     = 32;

    uint8 constant Q_DOUBLE_QUOTES  = 1;
    uint8 constant Q_HERE_DOCUMENT  = 2;
    uint8 constant Q_KEEP_BACKSLASH = 4;
    uint8 constant Q_PATQUOTE       = 8;
    uint8 constant Q_QUOTED         = 16;
    uint8 constant Q_ADDEDQUOTES    = 32;
    uint8 constant Q_QUOTEDNULL     = 64;

    // Values for character flags in syntax tables
    uint16 constant CWORD       = 0;	// nothing special; an ordinary character
    uint16 constant CSHMETA     = 1;	// shell meta character
    uint16 constant CSHBRK      = 2;	// shell break character
    uint16 constant CBACKQ      = 4;	// back quote
    uint16 constant CQUOTE      = 8;	// shell quote character
    uint16 constant CSPECL      = 16;	// special character that needs quoting
    uint16 constant CEXP        = 32;	// shell expansion character
    uint16 constant CBSDQUOTE   = 64;	// characters escaped by backslash in double quotes
    uint16 constant CBSHDOC     = 128;	// characters escaped by backslash in here doc
    uint16 constant CGLOB       = 256;	// globbing characters
    uint16 constant CXGLOB      = 512;	// extended globbing characters
    uint16 constant CXQUOTE     = 1024;	// cquote + backslash
    uint16 constant CSPECVAR    = 2048;	// single-character shell variable name
    uint16 constant CSUBSTOP    = 4096;	// values of OP for ${word[:]OPstuff}

    // Some defines for calling file status functions.
    uint16 constant FS_EXISTS	    = 1;
    uint16 constant FS_EXECABLE     = 2;
    uint16 constant FS_EXEC_PREF    = 4;
    uint16 constant FS_EXEC_ONLY    = 8;
    uint16 constant FS_DIRECTORY	= 16;
    uint16 constant FS_NODIRS       = 32;

    string constant FLAG_ON = '-';
    string constant FLAG_OFF = '+';

    int8 constant FLAG_ERROR = -1;
    int8 constant FLAG_UNKNOWN = 0;

    function _item_index(string name, Item[] map) internal pure returns (uint) {
        for (uint i = 0; i < map.length; i++)
            if (map[i].name == name)
                return i + 1;
    }

    function _as_var_list(string[][2] entries) internal pure returns (string res) {
        for (uint i = 0; i < entries.length; i++)
            res.append("-- " + vars.wrap(entries[i][0], vars.W_SQUARE) + (entries[i][1].empty() ? "" : ("=" + vars.wrap(entries[i][1], vars.W_DQUOTE))) + "\n");
    }

    function _as_hashmap(string name, string[][2] entries) internal pure returns (string res) {
        string body;
        for (uint i = 0; i < entries.length; i++)
            body.append(vars.wrap(entries[i][0], vars.W_SQUARE) + "=" + vars.wrap(entries[i][1], vars.W_DQUOTE) + " ");
        res = "-A " + vars.wrap(name, vars.W_SQUARE) + "=" + vars.wrap(body, vars.W_HASHMAP);
    }

    function _as_indexed_array(string name, string value, string ifs) internal pure returns (string res) {
        string body;
        (string[] fields, uint n_fields) = stdio.split(value, ifs);
        for (uint i = 0; i < n_fields; i++)
            body.append(format("[{}]=\"{}\" ", i, fields[i]));
        res = "-a " + vars.wrap(name, vars.W_SQUARE) + "=" + vars.wrap(body, vars.W_ARRAY);
    }


    function _encode_items(string[][2] entries, string delimiter) internal pure returns (string res) {
        for (uint i = 0; i < entries.length; i++)
            res.append(_encode_item_2(entries[i][0], entries[i][1]) + delimiter);
    }

    function _encode_item(string key, string value) internal pure returns (string res) {
        res = vars.wrap(key, vars.W_SQUARE) + "=" + vars.wrap(value, vars.W_DQUOTE);
    }

    function _as_map(string value) internal pure returns (string res) {
        res = vars.wrap(value, vars.W_HASHMAP);
    }

    function _encode_item_2(string key, string value) internal pure returns (string res) {
        res = vars.wrap(key, vars.W_SQUARE);
        if (!value.empty())
            res.append("=" + (stdio.strchr(value, "(") > 0 ? value : vars.wrap(value, vars.W_DQUOTE)));
    }

     function _flag(string name, string[] env_in) internal pure returns (bool) {
        return stdio.strstr(env_in[vars.IS_OPTION_VALUE], name + "=") > 0;
    }

    function _trim_spaces(string s_arg) internal pure returns (string res) {
        res = stdio.tr_squeeze(s_arg, " ");
        uint len = res.byteLength();
        if (len > 0 && stdio.strrchr(res, " ") == len)
            res = res.substr(0, len - 1);
        len = res.byteLength();
        if (len > 0 && res.substr(0, 1) == " ")
            res = res.substr(1);
    }
    function _value_of(string name, string page) internal pure returns (string) {
        string empty;
        if (name.empty())
            return empty;
        string name_pattern = vars.wrap(name, vars.W_SQUARE) + "=";
        (string[] lines, ) = stdio.split(page, "\n");
        for (string line: lines) {
            if (stdio.strstr(line, name_pattern) > 0) {
                uint q = stdio.strstr(line, "=");
                return q > 0 ? line.substr(q) : empty;
            }
        }
    }

    function _get_array_name(string value, string context) internal pure returns (string name) {
        (string[] lines, ) = stdio.split(context, "\n");
        string val_pattern = vars.wrap(value, vars.W_SPACE);
        for (string line: lines)
            if (stdio.strstr(line, val_pattern) > 0)
                return stdio.strval(line, "[", "]");
    }

    function _set_item_value(string name, string value, string page) internal pure returns (string) {
        string cur_value = vars.val(name, page);
        string new_record = _encode_item(name, value);
        return cur_value.empty() ? page + " " + new_record : stdio.translate(page, _encode_item(name, cur_value), new_record);
    }

    function _set_var(string attrs, string token, string pg) internal pure returns (string page) {
        (string name, string value) = stdio.strsplit(token, "=");
        string cur_record = vars.get_pool_record(name, pg);
        string new_record = vars.var_record(attrs, name, value);
        if (!cur_record.empty()) {
            (string cur_attrs, ) = stdio.strsplit(cur_record, " ");
            (, string cur_value) = stdio.strsplit(cur_record, "=");
            string new_value = !value.empty() ? value : !cur_value.empty() ? vars.unwrap(cur_value) : "";
            new_record = vars.var_record(vars.meld_attr_set(attrs, cur_attrs), name, new_value);
            page = stdio.translate(pg, cur_record, new_record);
        } else
            page = pg + new_record + "\n";
    }

    function _set_add(string token, string context) internal pure returns (string) {
        if (stdio.strstr(context, " " + token + " ") == 0)
            return stdio.translate(context, " )", " " + token + " )");
        return context;
    }

    function _lookup_value(string map_name, string name, mapping (uint => ItemHashMap) env_in) internal pure returns (string) {
        return env_in[tvm.hash(map_name)].value[tvm.hash(name)].value;
    }

    function _get_option_value(string options, string s) internal pure returns (bool) {
        return stdio.strchr(options, s) > 0;
    }

    function _get_option_param(string s_args, string short_option) internal pure returns (string) {
        if (s_args.empty())
            return "";
        (string[] fields, uint n_fields) = stdio.split(s_args, " ");
        string opt_arg = "-" + short_option;
        for (uint i = 0; i < n_fields - 1; i++)
            if (fields[i] == opt_arg)
                return fields[i + 1];
    }

    function _get_dual_option_param(string s_args, string short_option) internal pure returns (string, bool) {
        if (s_args.empty())
            return ("", false);
        (string[] fields, uint n_fields) = stdio.split(s_args, " ");
        string opt_arg_dash = "-" + short_option;
        string opt_arg_plus = "+" + short_option;
        for (uint i = 0; i < n_fields - 1; i++) {
            if (fields[i] == opt_arg_dash)
                return (fields[i + 1], false);
            else if (fields[i] == opt_arg_plus)
                return (fields[i + 1], true);
        }
    }

    function builtin_help() external pure returns (BuiltinHelp bh) {
        return _builtin_help();
    }

    function _builtin_help() internal pure virtual returns (BuiltinHelp bh);
}
