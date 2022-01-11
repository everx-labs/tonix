pragma ton-solidity >= 0.51.0;

import "Utility.sol";
import "../include/Commands.sol";
import "../lib/libuadm.sol";

contract sh is Utility, Commands, libuadm {

    uint16 constant EXT_NO_ACTION   = 0;
    uint16 constant EXT_READ_IN     = 1;
    uint16 constant EXT_WRITE_IN    = 2;
    uint16 constant EXT_MAP_FILE    = 4;
    uint16 constant EXT_OPEN_FILE   = 8;
    uint16 constant EXT_READ_DIR    = 16;
    uint16 constant EXT_PIPE_TO     = 32;
    uint16 constant EXT_OPEN_DIR    = 64;
    uint16 constant EXT_READ_TREE   = 128;
    uint16 constant EXT_OPEN_TREE   = 256;
    uint16 constant EXT_WRITE_FILES = 512;
    uint16 constant EXT_ACCOUNT     = 2048;
    uint16 constant EXT_CHANGE_DIR  = 4096;
    uint16 constant EXT_MOUNT_FS    = 8192;
    uint16 constant EXT_SPAWN       = 16384;

    struct Task {
        uint16 id;
    }
/*cd is a shell builtin
echo is a shell builtin
help is a shell builtin
logout is a shell builtin
mapfile is a shell builtin
pwd is a shell builtin*/
/*struct ParsedCommand {
    string command;
    string[] args;
    string short_options;
    string[] long_options;
    string stdin_redirect;
    string stdout_redirect;
    uint16 action;
    string s_action;
}*/
    uint16 constant SH_NO_ACTION       = 0;
    uint16 constant SH_EXEC            = 1;
    uint16 constant SH_PRINT_STATUS    = 1;
    uint16 constant SH_FILE_OP         = 2;
    uint16 constant SH_WRITE_FILES     = 3;
    uint16 constant SH_PROCESS_COMMAND = 4;
    uint16 constant SH_FORMAT_TEXT     = 5;
    uint16 constant SH_DEVICE_STATUS   = 6;
    uint16 constant SH_READ_INDEX      = 7;
    uint16 constant SH_USER_ADMIN_OP   = 8;
    uint16 constant SH_USER_STATS_OP   = 9;
    uint16 constant SH_USER_ACCESS_OP  = 10;
    uint16 constant SH_READ_PAGE       = 11;
    uint16 constant SH_FILE_ACTION     = 12;
    uint16 constant SH_RUN_SESSION     = 13;
    uint16 constant SH_PARSE_INPUT     = 14;
    uint16 constant SH_GET_OPTIONS     = 15;
    uint16 constant SH_PRINT_USAGE     = 16;
    uint16 constant SH_PRINT_VERSION   = 17;
    uint16 constant SH_COMMAND_INFO    = 18;
    uint16 constant SH_MAKE_FS         = 19;
    uint16 constant SH_READ_FS         = 20;
    uint16 constant SH_CLONE_FS        = 21;
    uint16 constant SH_UPLOAD          = 22;
    uint16 constant SH_DOWNLOAD        = 23;
    uint16 constant SH_SHELL           = 24;

    function parse_input(string s_input, CommandInfo command_info) external pure returns (InputS input, ParsedCommand pc, Err[] parse_errors, string script) {
//        if (s_input.empty())
//            return (pc, out);
        uint p = _strrchr(s_input, ">");
        uint q = _strrchr(s_input, "<");
        (string c, string s_args) = _strsplit(s_input, " ");
        string out_redirect = p > 0 ? _strtok(s_input, p, " ") : "";
        string in_redirect = q > 0 ? _strtok(s_input, q, " ") : "";

        string[] args;
        string short_options;
        string[] long_options;
        uint16 action;
        if (!s_args.empty())
            (args, short_options, long_options) = _parse_args(s_args);

        if (c != command_info.name)
            parse_errors.push(Err(command_not_found, 0, c));
        else {
            uint flags = _parse_short_options(short_options);
            if (args.empty()) {
                if (c == "du" || c == "ls" || c == "df")
                    args.push(".");
                if (c == "cd")
                    args.push("~");
            }
            if (c == "ln" && args.length == 1)
                args.push(".");

            parse_errors = _check_args(c, command_info, short_options, args);

            input = InputS(0, args, flags);
            string s_action;

            if (!parse_errors.empty())
                s_action = "error";

            for (string s: long_options) {
                if (s == "help") s_action = "usage";
                if (s == "version") s_action = "version";
            }
            if (s_action.empty()) {
                /*if (_op_builtin_s(c)) action = ACT_RUN_SESSION;
                if (_op_stat_s(c)) action = ACT_PRINT_STATUS;
                if (_op_file_s(c) || _op_access_s(c)) action = ACT_FILE_ACTION;
                if (_is_pure_s(c)) action = ACT_PROCESS_COMMAND;
                if (_op_dev_stat_s(c)) action = ACT_DEVICE_STATUS;
                if (_op_format_s(c)) action = ACT_READ_INDEX;
                if (_op_user_admin_s(c)) action = ACT_USER_ADMIN_OP;
                if (_op_user_stats_s(c)) action = ACT_USER_STATS_OP;
                if (_op_user_access_s(c)) action = ACT_USER_ACCESS_OP;
                if (_reads_file_fixed_s(c)) action = ACT_READ_PAGE;
                if (_op_filesystem_s(c)) action = ACT_ALTER_FS;
                if (_op_dev_admin_s(c)) action |= ACT_UPDATE_DEVICES;*/
                if (_op_builtin_s(c)) s_action = "builtin";
                if (_op_stat_s(c)) s_action = "fstat";
                if (_op_file_s(c) || _op_access_s(c)) s_action = "induce";
                if (_is_pure_s(c)) s_action = "exec";
                if (_op_dev_stat_s(c)) s_action = "exec";
                if (_op_format_s(c)) s_action = "exec";
                if (_op_user_admin_s(c)) s_action = "uadm";
                if (_op_user_stats_s(c)) s_action = "ustat";
                if (_op_user_access_s(c)) s_action = "exec";
                if (_reads_file_fixed_s(c)) s_action = "exec";
                if (_op_filesystem_s(c)) s_action = "alter";
                if (_op_dev_admin_s(c)) s_action = "exec";
                if (c == "login") s_action = "authorize";
            }
//            string s_action = _action_function(action);
            pc = ParsedCommand(c, args, short_options, long_options, in_redirect, out_redirect, action, s_action);
            script = "./vfs/bin/sh " + s_action + " " + c + ";";
            if (!out_redirect.empty()) {
                script.append("./vfs/bin/tmpfs fopen " + out_redirect + ";");
                script.append("./vfs/bin/tmpfs fwrite vfs/tmp/tmpfs/file_in;");
                script.append("./vfs/bin/tmpfs fclose " + out_redirect + ";");
            }
        }
    }

    function _action_function(uint16 action) internal pure returns (string) {
        /*if (action == ACT_PRINT_ERRORS) return "error";
        if (action == ACT_RUN_SESSION) return "shell";
        if (action == ACT_PRINT_STATUS) return "stat";
        if (action == ACT_FILE_ACTION) return "induce";
        if (action == ACT_PROCESS_COMMAND) return "??";
        if (action == ACT_DEVICE_STATUS) return "devstat";
        if (action == ACT_READ_INDEX) return "iread";
        if (action == ACT_USER_ADMIN_OP) return "uadm";
        if (action == ACT_USER_STATS_OP) return "ustat";
        if (action == ACT_USER_ACCESS_OP) return "??";
        if (action == ACT_READ_PAGE) return "fread";
        if (action == ACT_UPDATE_DEVICES) return "devadm";*/
        if (action == ACT_ALTER_FS) return "alter";
        if (action == ACT_RUN_SESSION) return "builtin";
        if (action == ACT_USER_STATS_OP) return "ustat";
        if (action == ACT_PRINT_STATUS) return "fstat";
        if (action == ACT_FILE_ACTION) return "induce";
        if (action == ACT_PRINT_USAGE) return "usage";
        if (action == ACT_USER_ADMIN_OP) return "uadm";
        if (action == ACT_PRINT_VERSION) return "version";
        return "exec";
    }

    function _parse_args(string s_args) internal pure returns (string[] args, string short_options, string[] long_options) {
        (string[] tokens, ) = _split(s_args, " ");
        bool discard_next = false;
        for (string token: tokens) {
            uint len = token.byteLength();
            if (len == 0 || discard_next)
                continue;
            string s1 = token.substr(0, 1);
            if (s1 == ">" || s1 == "<") {
                discard_next = true;
                continue;
            }
            if (s1 == "-" && len > 1) {
                if (token.substr(1, 1) == "-") {
                    if (len > 2)
                        long_options.push(token.substr(2));
                } else
                    short_options.append(token.substr(1));
            } else
                args.push(token);
        }
    }

    function _check_args(string command_s, CommandInfo ci, string short_options, string[] args) private pure returns (Err[] errors) {
        uint16 n_args = uint16(args.length);
        string extra_flags;
        uint short_options_len = short_options.byteLength();
        string possible_options = ci.options;
        for (uint i = 0; i < short_options_len; i++) {
            string actual_option = short_options.substr(i, 1);
            uint p = _strchr(possible_options, actual_option);
            if (p == 0)
                extra_flags.append(actual_option);
        }

        if (n_args < ci.min_args)
            errors.push(Err(missing_file_operand, 0, command_s));
        if (n_args > ci.max_args)
            errors.push(Err(extra_operand, 0, args[ci.max_args]));
        if (!extra_flags.empty())
            errors.push(Err(invalid_option, 0, extra_flags));
        if (!errors.empty())
            errors.push(Err(try_help_for_info, 0, command_s));
    }

    function _parse_short_options(string short_options) private pure returns (uint flags) {
        bytes opts = bytes(short_options);
        for (uint i = 0; i < opts.length; i++)
            flags |= uint(1) << uint8(opts[i]);
    }

    function authorize(string i_login, string i_host_name, string i_cwd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (Session session) {
        /* Validate session info: uid and wd */
//        (uint16 uid, UserInfo user_info) = _query_user_data(i_login);
        uint16 uid;
        UserInfo user_info;
        uint u_ord;
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        for ((uint16 userid, UserInfo ui): users) {
            u_ord++;
            if (i_login == ui.user_name) {
                uid = userid;
                user_info = ui;
                break;
            }
        }
        (uint16 gid, string user_name, string group_name) = user_info.unpack();

        uint16 pid = uint16(u_ord);

        uint16 wd = _resolve_absolute_path(i_cwd, inodes, data);
        string cwd;
        if (wd > INODES)
            cwd = i_cwd;
        else {
            cwd = ROOT;
            wd = ROOT_DIR;
        }
        string host_name;
        (string[] lines, ) = _split(_get_file_contents_at_path("/etc/hosts", inodes, data), "\n");
        for (string s: lines) {
            (string[] fields, uint n_fields) = _split(s, "\t");
            if (n_fields > 0 && fields[0] == i_host_name) {
                host_name = i_host_name;
                break;
            }
        }

        session = Session(pid, uid, gid, wd, user_name, group_name, host_name, cwd);
    }

//    function run_session(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Session session_out, Err[] errors) {
    function builtin(Session session, ParsedCommand pc, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, string script, Session session_out, Err[] errors) {
        (, , uint flags) = input.unpack();
        (, uint16 uid, uint16 gid, uint16 wd, string user_name, string group_name, /*string host_name*/, string cwd) = session.unpack();
        (string c, string[] args, string short_options, string[] long_options, string stdin_redirect, string stdout_redirect,
            uint16 action, string s_action) = pc.unpack();

        session_out = session;
//        bool follow_symlinks = _op_format(c) || c == readlink || (flags & _L) > 0;
//        uint16 deref_mode = follow_symlinks ? EXPAND_SYMLINKS : 0;
        if (c == "readlink") (out, errors) = _readlink(flags, args, wd, inodes, data);
        if (c == "realpath") (out, errors) = _realpath(flags, args, wd, inodes, data);
//        if (c == env) (out, errors) = _debug(flags, args, wd, inodes, data);
        if (c == "hostname") out = _hostname(flags, inodes, data) + "\n";
        if (c == "id") out = _id(flags, user_name, uid, gid, group_name) + "\n";
        if (c == "pwd") out = cwd + "\n";
        if (c == "echo") out = _echo(flags, args);
        if (c == "help") {
            (string[] fields, ) = _split(_get_file_contents_at_path("/etc/command_list", inodes, data), "\n");
            out = "Commands: " + _join_fields(fields, " ") + "\n";
        }
        if (c == "whoami") out = user_name + "\n";
        if (c == "cd") {
            uint16 nwd;
            string n_cwd;
            (nwd, n_cwd, errors) = _cd(flags, args[0], wd, inodes, data);
            if (nwd != wd) {
                session_out.wd = nwd;
                session_out.cwd = n_cwd;
            }
        }
//        if (!stdout_redirect.empty())
//            script = "./vfs/bin/sh " + s_action + " " + c + ";";
    }

    function _print_dir(DirEntry[] contents, int16 status) internal pure returns (string out) {
        if (status < 0)
            return format("Error: {} \n", status);
        uint len = uint(status);
        uint len1 = contents.length;
        out.append(format("\n{} {} \n", len, len1));
        for (uint16 j = 0; j < len; j++) {
            (uint8 sub_ft, string sub_name, uint16 sub_index) = contents[j].unpack();
            out.append(format("{} {} {}\n", sub_ft, sub_name, sub_index));
        }
    }

    /* Session commands */
    function _cd(uint flags, string s, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (uint16 nwd, string cwd, Err[] es) {
        bool follow_symlinks = (flags & _L) > 0;
        Arg arg = _dereference(follow_symlinks ? EXPAND_SYMLINKS : 0, s, wd, inodes, data);
        if (((flags & _e + _P) > 0) && wd < INODES)
            es.push(Err(0, ENOENT, s));
        (string path, uint8 ft, uint16 ino, , ) = arg.unpack();
        nwd = wd;
        if (ino < INODES)
            es.push(Err(0, ENOENT, path));
        else if (ft != FT_DIR)
            es.push(Err(0, ENOTDIR, path));
        else if (es.empty()) {
            nwd = ino;
            cwd = _get_absolute_path(nwd, inodes, data);
        }
    }

    function _echo(uint flags, string[] args) internal pure returns (string out) {
        bool no_trailing_newline = (flags & _n) > 0;
        out = _join_fields(args, " ");
        if (!no_trailing_newline)
            out.append("\n");
    }

    function _id(uint flags, string user_name, uint16 uid, uint16 gid, string group_name) private pure returns (string out) {
        bool effective_gid_only = (flags & _g) > 0;
        bool name_not_number = (flags & _n) > 0;
        bool real_id = (flags & _r) > 0;
        bool effective_uid_only = (flags & _u) > 0;

        bool is_ugG = (flags & _u + _g + _G) > 0;

        if ((name_not_number || real_id) && !is_ugG)
            out = "id: cannot print only names or real IDs in default format";
        else if (effective_gid_only && effective_uid_only)
            out = "id: cannot print \"only\" of more than one choice";
        else if (effective_gid_only)
            out = name_not_number ? group_name : format("{}", gid);
        else if (effective_uid_only)
            out = name_not_number ? user_name : format("{}", uid);
        else
            out = format("uid={}({}) gid={}({})", uid, user_name, gid, group_name);
    }

    function _pwd(uint /*flags*/, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string) {
//        bool follow_symlinks = ((flags & _L) > 0) && ((flags & _P) == 0);
        return _get_absolute_path(wd, inodes, data);
    }

    function _hostname(uint flags, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        bool long_host_name = (flags & _f) > 0;
        bool addresses = (flags & _i) > 0;

        (string[] f_hostname, uint n_fields) = _split(_get_file_contents_at_path("/etc/hostname", inodes, data), "\n");
        string s_domain = "tonix";

        if (addresses && n_fields > 1)
           return f_hostname[1];
        out = f_hostname[0];
        if (long_host_name)
            out.append("." + s_domain);
    }

    /* Path resolution commands */
    function _readlink(uint flags, string[] s_args, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        bool canon_existing_dir = (flags & _f) > 0;
        bool canon_existing = (flags & _e) > 0;
        bool canon_missing = (flags & _m) > 0;
        bool no_newline = (flags & _n) > 0;
        bool print_errors = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        bool canon = (flags & _f + _e + _m) > 0;
        uint16 mode = canon_existing ? 3 : canon_existing_dir ? 2 : canon_missing ? 1 : 0;

        for (string s_arg: s_args) {
            (, uint8 ft, uint16 parent, ) = _resolve_relative_path(s_arg, wd, inodes, data);
            string path;
            bool exists;
            if (canon)
                (path, exists) = _canonicalize(mode, s_arg, parent, inodes, data);
            else if (ft == FT_SYMLINK) {
                Arg arg = _dereference(mode + EXPAND_SYMLINKS, s_arg, wd, inodes, data);
                (path, ft, , , ) = arg.unpack();
                exists = ft > FT_UNKNOWN;
            } else
                continue;

            if (!exists) {
                if (print_errors)
                    errors.push(Err(0, ENOENT, s_arg));
                continue;
            }
            out.append(path);
            out = _if(out, !no_newline, line_delimiter);
        }
    }

    function _realpath(uint flags, string[] s_args, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Err[] errors) {
        bool canon_existing = (flags & _e) > 0;
        bool canon_missing = (flags & _m) > 0;
        bool canon_existing_dir = (flags & _m + _e) == 0;
//        bool logical = (flags & _L) > 0;
//        bool physical = (flags & _P) > 0;
        bool expand_symlinks = (flags & _s) == 0;
        bool print_errors = (flags & _q) == 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        for (string s_arg: s_args) {
            (string arg_dir, string arg_base) = _dir(s_arg);
            bool is_abs_path = s_arg.substr(0, 1) == "/";
            string path = is_abs_path ? s_arg : _xpath(s_arg, wd, inodes, data);
            uint16 cur_dir = is_abs_path ? _resolve_absolute_path(arg_dir, inodes, data) : wd;

            if ((canon_existing_dir || canon_existing) && expand_symlinks) {
                (uint16 index, uint8 ft) = _lookup_dir(inodes[cur_dir], data[cur_dir], arg_base);
                if (ft == FT_SYMLINK)
                    (path, ft, , ,) = _dereference(EXPAND_SYMLINKS, s_arg, wd, inodes, data).unpack();
                if (!canon_missing && index < INODES) {
                    if (print_errors)
                        errors.push(Err(0, index, s_arg));
                    continue;
                }
            }
            out.append(path + line_delimiter);
        }
    }

    /* Path utilities helpers */
    function _abs_path_walk_up(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string path) {
        uint16 cur_dir = dir;
        while (cur_dir > ROOT_DIR) {
            Inode inode = inodes[cur_dir];
            path = inode.file_name + "/" + path;
            (DirEntry[] contents, int16 status) = _read_dir(inode, data[cur_dir]);
            if (status > 1)
                cur_dir = contents[1].index;
        }
    }

    function _canonicalize(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string res, bool valid) {
        uint16 canon_mode = mode & 3;
        (string arg_dir, string arg_base) = _dir(s_arg);
        bool is_abs_path = s_arg.substr(0, 1) == "/";
        valid = true;

        if (canon_mode >= CANON_DIRS) {
            uint16 dir_index = is_abs_path ? _resolve_absolute_path(arg_dir, inodes, data) : wd;
            (, uint8 ft) = _lookup_dir(inodes[dir_index], data[dir_index], arg_base);
            if (ft == FT_UNKNOWN)
                valid = false;
        }

        res = canon_mode == CANON_NONE || (canon_mode == CANON_MISS || canon_mode == CANON_EXISTS) && is_abs_path ?
            s_arg : canon_mode == CANON_DIRS ? _xpath(arg_dir, _resolve_absolute_path(arg_dir, inodes, data), inodes, data) + "/" + arg_base : _xpath(s_arg, wd, inodes, data);
    }

    function _dereference(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (Arg) {
        bool expand_symlinks = (mode & EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
        Inode inode;
        if (ino > 0 && inodes.exists(ino))
            inode = inodes[ino];
        if (expand_symlinks && ft == FT_SYMLINK) {
            (ft, s_arg, ino) = _get_symlink_target(inode, data[ino]).unpack();
        }
        return Arg(s_arg, ft, ino, parent, dir_index);
    }

    function _is_pure_s(string c) internal pure returns (bool) {
        return c == "basename" || c == "dirname" || c == "pathchk" || c == "uname";
    }

    function _op_stat_s(string c) internal pure returns (bool) {
        return c == "cksum" || c == "du" || c == "file" || c == "getent" || c == "ls" || c == "namei" || c == "stat";
    }

    function _op_format_s(string c) internal pure returns (bool) {
        return c == "cat" || c == "colrm" || c == "column" || c == "cut" || c == "expand" || c == "grep" || c == "head" || c == "look"
           || c == "mapfile" || c == "more" || c == "paste" || c == "rev" || c == "tail" || c == "tr" || c == "unexpand" || c == "wc";
    }

    function _op_fs_status_s(string c) internal pure returns (bool) {
        return c == "cksum" || c == "du" || c == "file" || c == "ls" || c == "stat";
    }

    function _op_filesystem_s(string c) internal pure returns (bool) {
        return c == "mke2fs" || c == "fsck" || c == "mount" || c == "umount";
    }

    function _op_dev_stat_s(string c) internal pure returns (bool) {
        return c == "df" || c == "findmnt" || c == "lsblk" || c == "mountpoint";
    }

    function _op_dev_admin_s(string c) internal pure returns (bool) {
        return c == "losetup" || c == "mknod" || c == "mount" || c == "udevadm" || c == "umount";
    }

    function _op_access_s(string c) internal pure returns (bool) {
        return c == "chgrp" || c == "chmod" || c == "chown";
    }

    function _op_file_s(string c) internal pure returns (bool) {
        return c == "cp" || c == "cmp" || c == "dd" || c == "fallocate" || c == "ld" || c == "ln" || c == "mkdir" || c == "mv" || c == "rm"
           || c == "rmdir" || c == "tar" || c == "touch" || c == "truncate";
    }

    function _op_file_action_s(string c) internal pure returns (bool) {
        return c == "cp" || /*c == "cmp" || c == "dd" || */c == "fallocate" || c == "ld" || c == "ln" || c == "mkdir" || c == "mv" || c == "rm"
           || c == "rmdir" || c == "tar" || c == "touch" || c == "truncate";
    }

    function _op_builtin_s(string c) internal pure returns (bool) {
        return c == "cd" || c == "id" || c == "login" || c == "logout" || c == "last" || c == "pwd" || c == "script" || c == "who" || c == "whoami" || c == "echo";
    }

    function _op_user_access_s(string c) internal pure returns (bool) {
        return c == "login" || c == "logout" || c == "newgrp";
    }

    function _op_network_s(string c) internal pure returns (bool) {
        return c == "account" || c == "mount" || c == "ping";
    }

    function _op_user_admin_s(string c) internal pure returns (bool) {
        return c == "gpasswd" || c == "groupadd" || c == "groupdel" || c == "groupmod" || c == "useradd" || c == "userdel" || c == "usermod";
    }

    function _op_user_stats_s(string c) internal pure returns (bool) {
        return c == "finger" || c == "fuser" || c == "last" || c == "lslogins" || c == "ps" || c == "utmpdump" || c == "who";
    }

    function _reads_file_fixed_s(string c) internal pure returns (bool) {
        return c == "help" || c == "man" || c == "whatis" || c == "whereis";
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("sh", "display", "[-dms]",
            "Displays brief summaries of builtin commands.",
            "dms", 0, M, [
            "output short description for each topic",
            "display usage in pseudo-manpage format",
            "output only a short usage synopsis for each topic"]);
    }

}
