pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract test is Shell {

    function builtin_read_fs(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Write[] wr) {
        (, , string argv) = _get_args(e[IS_ARGS]);
        string s_args = _val("@", e[IS_TOSH_VAR]);
//        string s_args = argv;
        string dbg;
        (string arg_1, string op, string arg_2) = _parse_test_args(s_args);
        dbg.append(format("arg 1: {} op: {} arg 2: {}\n", arg_1, op, arg_2));
        bool res;
        if (arg_2.empty()) {
            if (_strchr("aesbcdfhLpSgukrwxOGN", op) > 0)
                res = _eval_file_unary(op, arg_1, e, inodes, data);
            else if (_strchr("ovR", op) > 0)
                res = _eval_option(op, arg_1, e);
        }
//        env[IS_SPECIAL_VAR] = _assign("", "?=" + (res ? "0" : "1"), e[IS_SPECIAL_VAR]);
        wr.push(Write(IS_STDERR, dbg, O_WRONLY + O_APPEND));
//        env[IS_STDERR].append(dbg);
//        uint16 ec = res ? 0 : 1;
    }

    function _eval_option(string op, string name, string[] e) internal pure returns (bool res) {
//        uint arg_hash = tvm.hash(name);
//        uint16 page_index = op == "o" ? IS_OPTION : op == "v" ? IS_VARIABLE : op == "R" ? IS_ALIAS : 0;
//        string page = e[page_index];
//        (, , string line) = _fetch_var(name, page);
//        if (!line.empty())
//            return true;
        return false;
    }

    function _match_mode(string op, uint16 mode) internal pure returns (bool res) {
        if (op == "b")
            return (mode & S_IFMT) == S_IFBLK;
        if (op == "c")
            return (mode & S_IFMT) == S_IFCHR;
        if (op == "d")
            return (mode & S_IFMT) == S_IFDIR;
        if (op == "f")
            return (mode & S_IFMT) == S_IFREG;
        if (op == "h" || op == "L")
            return (mode & S_IFMT) == S_IFLNK;
        if (op == "p")
            return (mode & S_IFMT) == S_IFIFO;
        if (op == "S")
            return (mode & S_IFMT) == S_IFSOCK;
        if (op == "g")
            return (mode & S_ISGID) > 0;
        if (op == "u")
            return (mode & S_ISUID) > 0;
        if (op == "k")
            return (mode & S_ISVTX) > 0;
        return false;
    }

    function _can_access(string op, uint16 mode, uint16 user_id, uint16 group_id) internal pure returns (bool) {

        if (op == "r" && user_id == user_id)
            return (mode & S_IRUSR) > 0;
        if (op == "w" && user_id == user_id)
            return (mode & S_IWUSR) > 0;
        if (op == "x" && user_id == user_id)
            return (mode & S_IXUSR) > 0;

        if (op == "O")
            return user_id == user_id; // uid;
        if (op == "G")
            return group_id == group_id; // uid;

        return false;
    }

    function _eval_file_unary(string op, string path, string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (bool res) {
//        string cached_wd = _lookup_value("shell_vars", "PWD", env);
        string cached_wd = _value_of("PWD", e[IS_VARIABLE]);
        uint16 pwd_index = _resolve_absolute_path(cached_wd, inodes, data);
        if (pwd_index > INODES) {
//            string abs_path = _get_absolute_path(pwd_index, inodes, data);
            (uint16 index, uint8 file_type, ) = _lookup_dir_ext(inodes[pwd_index], data[pwd_index], path);

            if (file_type == FT_UNKNOWN)
                return false;
            if (op == "a" || op == "e")
                return true;

            (uint16 mode, uint16 owner_id, uint16 group_id, , , , uint32 file_size, , , ) = inodes[index].unpack();
            if (op == "s")
                return file_size > 0;

            if (_strchr("bcdfhLpStgku", op) > 0)
                return _match_mode(op, mode);

            if (_strchr("rwxOG", op) > 0)
                return _can_access(op, mode, owner_id, group_id);
        }
        return false;
    }

    function _parse_test_args(string s_args) internal pure returns (string arg_1, string op, string arg_2) {
        (string[] fields, uint n_fields) = _split(s_args, " ");
        string arg_op;
        if (n_fields > 0)
            arg_1 = fields[n_fields - 1];
        if (n_fields > 1)
            arg_op = fields[n_fields - 2];
        if (n_fields > 2)
            arg_2 = fields[n_fields - 3];

        op = !arg_op.empty() && arg_op.substr(0, 1) == "-" ? arg_op.substr(1) : arg_op;
    }

    function read_fs(Job job_in, mapping (uint => ItemHashMap) env_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (Job job, mapping (uint => ItemHashMap) env) {
        job = job_in;
        env = env_in;
        (, , , , , , , , , , string s_args, , , , , , , , ) = job_in.unpack();
//            bool res = _eval(s_args, env_in, inodes, data);
        (string arg_1, string op, string arg_2) = _parse_test_args(s_args);
        bool res;
        if (arg_2.empty()) {
//            if (_strchr("aesbcdfhLpSgukrwxOGN", op) > 0)
///                res = _eval_file_unary(op, arg_1, env, inodes, data);
//            else if (_strchr("ovR", op) > 0)
//                res = _eval_option(op, arg_1, env);
        }
        uint16 ec = res ? 0 : 1;

//            (uint16 ec, string out, mapping (uint => ItemHashMap) env_x, string s_action) = _test(args, short_options, env_in);
        job.ec = ec;
//            job.stdout.append(out);
//            job.s_action = s_action;
    }

    /*function _test(string[] args, string short_options, mapping (uint => ItemHashMap) env_in) internal pure returns (uint16 ec, string out, mapping (uint => ItemHashMap) env, string s_action) {

        bool file_exists = _get_option_value(short_options, "a") || _get_option_value(short_options, "e");
        bool file_exists_and_not_empty = _get_option_value(short_options, "s");

        bool file_is_block = _get_option_value(short_options, "b");
        bool file_is_char = _get_option_value(short_options, "c");
        bool file_is_dir = _get_option_value(short_options, "d");
        bool file_is_reg = _get_option_value(short_options, "f");
        bool file_is_symlink = _get_option_value(short_options, "h") || _get_option_value(short_options, "L");
        bool file_is_pipe = _get_option_value(short_options, "p");
        bool file_is_socket = _get_option_value(short_options, "S");

        bool file_is_set_gid = _get_option_value(short_options, "g"); // ??
        bool file_is_set_uid = _get_option_value(short_options, "u");
        bool file_has_sticky_bit = _get_option_value(short_options, "k");

        bool file_is_user_readable = _get_option_value(short_options, "r");
        bool file_is_user_writable = _get_option_value(short_options, "w");
        bool file_is_user_executable = _get_option_value(short_options, "x");

        bool file_is_effectively_owned = _get_option_value(short_options, "O");
        bool file_is_effectively_group_owned = _get_option_value(short_options, "G");
        bool file_has_been_modified = _get_option_value(short_options, "N");

        bool file_opened_on_terminal = _get_option_value(short_options, "t");

        bool file_is_newer = _get_option_value(short_options, "nt");
        bool file_is_older = _get_option_value(short_options, "ot");
        bool file_is_hardlink = _get_option_value(short_options, "ef");

        bool string_is_empty = _get_option_value(short_options, "z");
        bool string_is_not_empty = _get_option_value(short_options, "n") || short_options.empty();

        bool strings_equal = _get_option_value(short_options, "=");
        bool strings_not_equal = _get_option_value(short_options, "!=");
        bool strings_lex_before = _get_option_value(short_options, "<");
        bool strings_lex_after = _get_option_value(short_options, ">");

        bool option_enabled = _get_option_value(short_options, "o");
        bool shell_var_set = _get_option_value(short_options, "v");
        bool shell_var_set_and_reference = _get_option_value(short_options, "R");

        bool expr_logical_false = _get_option_value(short_options, "!");
        bool expr_logical_and = _get_option_value(short_options, "a");
        bool expr_logical_or = _get_option_value(short_options, "o");

        bool expr_arithmetic_eq = _get_option_value(short_options, "eq");
        bool expr_arithmetic_ne = _get_option_value(short_options, "ne");
        bool expr_arithmetic_lt = _get_option_value(short_options, "lt");
        bool expr_arithmetic_le = _get_option_value(short_options, "le");
        bool expr_arithmetic_gt = _get_option_value(short_options, "gt");
        bool expr_arithmetic_ge = _get_option_value(short_options, "ge");

        env = env_in;
    }*/

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
            "test",
            "[expr]",
            "Evaluate conditional expression.",
            "\
Exits with a status of 0 (true) or 1 (false) depending on the evaluation of EXPR.  Expressions may be unary or binary.  Unary\n\
expressions are often used to examine the status of a file.  There are string operators and numeric comparison operators as well.\n\
The behavior of test depends on the number of arguments.  Read the manual page for the complete specification.\n\
File operators:",
            "\
-a FILE        True if file exists.\n\
-b FILE        True if file is block special.\n\
-c FILE        True if file is character special.\n\
-d FILE        True if file is a directory.\n\
-e FILE        True if file exists.\n\
-f FILE        True if file exists and is a regular file.\n\
-g FILE        True if file is set-group-id.\n\
-h FILE        True if file is a symbolic link.\n\
-L FILE        True if file is a symbolic link.\n\
-k FILE        True if file has its `sticky' bit set.\n\
-p FILE        True if file is a named pipe.\n\
-r FILE        True if file is readable by you.\n\
-s FILE        True if file exists and is not empty.\n\
-S FILE        True if file is a socket.\n\
-t FD          True if FD is opened on a terminal.\n\
-u FILE        True if the file is set-user-id.\n\
-w FILE        True if the file is writable by you.\n\
-x FILE        True if the file is executable by you.\n\
-O FILE        True if the file is effectively owned by you.\n\
-G FILE        True if the file is effectively owned by your group.\n\
-N FILE        True if the file has been modified since it was last read.\n\
FILE1 -nt FILE2  True if file1 is newer than file2 (according to modification date).\n\
FILE1 -ot FILE2  True if file1 is older than file2.\n\
FILE1 -ef FILE2  True if file1 is a hard link to file2.\n\
All file operators except -h and -L are acting on the target of a symbolic link, not on\n\
the symlink itself, if FILE is a symbolic link.\n\
String operators:\n\
  -z STRING      True if string is empty.\n\
  -n STRING\n\
     STRING      True if string is not empty.\n\
  STRING1 = STRING2  True if the strings are equal.\n\
  STRING1 != STRING2 True if the strings are not equal.\n\
  STRING1 < STRING2  True if STRING1 sorts before STRING2 lexicographically.\n\
  STRING1 > STRING2  True if STRING1 sorts after STRING2 lexicographically.",
            "\
Other operators:\n\n\
-o OPTION      True if the shell option OPTION is enabled.\n\
-v VAR         True if the shell variable VAR is set.\n\
-R VAR         True if the shell variable VAR is set and is a name reference.\n\
! EXPR         True if expr is false.\n\
EXPR1 -a EXPR2 True if both expr1 AND expr2 are true.\n\
EXPR1 -o EXPR2 True if either expr1 OR expr2 is true.\n\n\
arg1 OP arg2   Arithmetic tests.  OP is one of -eq, -ne, -lt, -le, -gt, or -ge.\n\n\
Arithmetic binary operators return true if ARG1 is equal, not-equal, less-than, less-than-or-equal,\n\
greater-than, or greater-than-or-equal than ARG2.",
            "Returns success if EXPR evaluates to true; fails if EXPR evaluates to false or an invalid argument is given.");
    }
}
