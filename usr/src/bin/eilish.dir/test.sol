pragma ton-solidity >= 0.61.0;

import "Shell.sol";
import "../../lib/inode.sol";
import "../../lib/libstatmode.sol";

contract test is Shell {

    using libstatmode for uint16;

    function main(svm sv_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
//        string[] params = p.params();
        string sargs = p.p_args.ar_misc.sargs;
        string dbg;
        string pool = vmem.vmem_fetch_page(sv.vmem[1], 8);

        (string arg_1, string op, string arg_2) = _parse_test_args(sargs);
        dbg.append(format("arg 1: {} op: {} arg 2: {}\n", arg_1, op, arg_2));
        bool result;
        if (arg_2.empty()) {
            if (str.strchr("aesbcdfhLpSgukrwxOGN", op) > 0)
                result = _eval_file_unary(op, arg_1, pool, inodes, data);
//            else if (str.chr("ovR", op) > 0)
//                result = _eval_option(op, arg_1, e);
            else
                result = false;
        }
//        res = result ? "true\n" : "false\n";
        p.p_xexit = result ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
        sv.cur_proc = p;
    }

    function _match_mode(string op, uint16 mode) internal pure returns (bool res) {
        if (op == "b")
//            return ft.is_block_dev(mode);
            return mode.is_block_dev();
        if (op == "c")
            return mode.is_char_dev();
        if (op == "d")
            return mode.is_dir();
        if (op == "f")
            return mode.is_reg();
        if (op == "h" || op == "L")
            return mode.is_symlink();
        if (op == "p")
            return mode.is_pipe();
        if (op == "S")
            return mode.is_socket();
        if (op == "g")
            return mode.is_gid();
        if (op == "u")
            return mode.is_uid();
        if (op == "k")
            return mode.is_vtx();
        return false;
    }

    function _can_access(string op, uint16 mode, uint16 user_id, uint16 group_id, uint16 uid, uint16 gid) internal pure returns (bool) {
        bool user_owned = user_id == uid;
        bool group_owned = group_id == gid;
        if (op == "O")
            return user_owned;
        if (op == "G")
            return group_owned;

        if (op == "r")
            return (user_owned && (mode & ft.S_IRUSR) > 0) || (group_owned && (mode & ft.S_IRGRP) > 0) || (mode & ft.S_IROTH) > 0;
        if (op == "w")
            return (user_owned && (mode & ft.S_IWUSR) > 0) || (group_owned && (mode & ft.S_IWGRP) > 0) || (mode & ft.S_IWOTH) > 0;
        if (op == "x")
            return (user_owned && (mode & ft.S_IXUSR) > 0) || (group_owned && (mode & ft.S_IXGRP) > 0) || (mode & ft.S_IXOTH) > 0;

        return false;
    }

    function _eval_file_unary(string op, string path, string pool, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (bool res) {
        uint16 wd_index = vars.int_val("WD", pool);
        (uint16 index, uint8 file_type, , ) = fs.resolve_relative_path(path, wd_index, inodes, data);

        if (file_type == ft.FT_UNKNOWN)
            return false;
        if (op == "a" || op == "e")
            return true;

        (uint16 mode, uint16 owner_id, uint16 group_id, , , , uint32 file_size, , , ) = inodes[index].unpack();
        if (op == "s")
            return file_size > 0;

        if (str.strchr("bcdfhLpStgku", op) > 0)
            return _match_mode(op, mode);

        if (str.strchr("rwxOG", op) > 0) {
            uint16 uid = vars.int_val("UID", pool);
            uint16 gid = vars.int_val("GID", pool);
            return _can_access(op, mode, owner_id, group_id, uid, gid);
        }
        return false;
    }

    function _parse_test_args(string sargs) internal pure returns (string arg_1, string op, string arg_2) {
        (string[] fields, uint n_fields) = sargs.split(" ");
        arg_1 = n_fields > 0 ? fields[n_fields - 1] : "";
        string arg_op = n_fields > 1 ? fields[n_fields - 2] : "";
        arg_2 = n_fields > 2 ? fields[n_fields - 3] : "";
        op = !arg_op.empty() && arg_op.substr(0, 1) == "-" ? arg_op.substr(1) : arg_op;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"test",
"[expr]",
"Evaluate conditional expression.",
"Exits with a status of 0 (true) or 1 (false) depending on the evaluation of EXPR.  Expressions may be unary or binary.  Unary\n\
expressions are often used to examine the status of a file.  There are string operators and numeric comparison operators as well.\n\
The behavior of test depends on the number of arguments.  Read the manual page for the complete specification.\n\
File operators:",
"-a FILE        True if file exists.\n\
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
"Other operators:\n\n\
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
