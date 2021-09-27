pragma ton-solidity >= 0.49.0;
pragma ignoreIntOverflow;

import "SyncFS.sol";
import "CacheFS.sol";
import "Format.sol";
import "SharedCommandInfo.sol";

contract SessionManager is SyncFS, CacheFS, Format, SharedCommandInfo {

    uint16 constant CANON_NONE  = 0;
    uint16 constant CANON_MISS  = 1;
    uint16 constant CANON_DIRS  = 2;
    uint16 constant CANON_EXISTS = 3;
    uint16 constant EXPAND_SYMLINKS = 8;

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

    /* Primary entry point */
    function parse(string i_login, string i_cwd, string s_input) external view returns (string out, Session session,
                    InputS input, uint16 action, uint16 ext_action, string source, string target, Err[] errors, Arg[] arg_list, string cwd) {
        /* Validate session info: uid and wd */
        (uint16 uid, UserInfo user_info) = _query_user_data(i_login);
        (uint16 gid, string user_name, string group_name) = user_info.unpack();
        uint16 pid = _get_process_id(uid);
        uint16 wd = _resolve_absolute_path(i_cwd);
        if (wd > INODES)
            cwd = i_cwd;
        else {
            cwd = ROOT;
            wd = ROOT_DIR;
        }
        session = Session(pid, uid, gid, wd);
        /* Parse input line */
        (uint8 c, string cmds, string[] args, uint flags, string x_source, string x_target) = _parse_input(s_input);
        target = x_target;
        source = x_source;
        if (c == CMD_UNKNOWN) {
            errors.push(Err(command_not_found, 0, cmds));
//            err = cmds + ": command not found\n";
        } else if (flags >= (1 << 254)) {
            if ((flags & 1 << 255) > 0) {
                delete args;
                args.push(cmds);
                input = InputS(help, args, 0);
                action = ACT_READ_PAGE;
            }
        } else {
            /* Push assumed arguments for certain commands */
            if (args.empty()) {
                if (c == du || c == ls || c == df)
                    args.push(".");
                if (c == cd)
                    args.push("~");
                if (c == help)
                    out = "Commands: " + _join_fields(_get_file_contents("/etc/command_list"), " ") + "\n";
            }
            if (c == ln && args.length == 1)
                args.push(".");
            input = InputS(c, args, flags);
            /* Diagnose common errors early:
                - missing or extra operands
                - unknown options        */
            CmdInfoS ci = _command_info[c];
            uint16 nargs = uint16(args.length);
            uint extra_flags = flags - (ci.options & flags);
            string args_check;
            if (nargs < ci.min_args) {
                args_check = "missing file operand";
                errors.push(Err(missing_file_operand, 0, cmds));
            }
            if (nargs > ci.max_args) {
                args_check = "extra operand" + _quote(args[ci.max_args]);
                errors.push(Err(extra_operand, 0, args[ci.max_args]));
            }
            if (extra_flags > 0) {
                string extra_flags_s;
                for (uint i = 0; i < 255; i++)
                    if ((extra_flags & (1 << i)) > 0)
                        extra_flags_s.append(format("{} ", i));
                args_check = "invalid option -- " + extra_flags_s;
                errors.push(Err(invalid_option, 0, extra_flags_s));
            }
            if (!args_check.empty())
                errors.push(Err(try_help_for_info, 0, cmds));
//                err.append(cmds + ": " + args_check + "\nTry " + cmds + " --help for more information.\n");
            else {
                bool follow_symlinks = _op_format(c) || c == readlink || (flags & _L) > 0;
                uint16 deref_mode = follow_symlinks ? EXPAND_SYMLINKS : 0;
                if (c == readlink) (out, errors) = _readlink(flags, args, wd);
                if (c == realpath) (out, errors) = _realpath(flags, args, wd);
                if (_op_format(c) || _op_stat(c) || _op_access(c) || _op_file(c) || c == readlink || c == realpath || c == cd) {
                    for (uint16 i = 0; i < nargs; i++) {
                        string s = args[i];
                        if (_op_access(c) && i == 0)
                            continue;
                        Arg arg = _dereference(deref_mode, s, session.wd);
                        arg_list.push(arg);
                        (string path, uint8 ft, uint16 ino,  , ) = arg.unpack();
                        if (ino > 0 && _fs.inodes.exists(ino)) {
                            if ((c == cat || c == paste || c == wc) && ft == FT_DIR)
                                errors.push(Err(0, EISDIR, path));
//                        } else if (_op_format(c) || _op_stat(c) || _op_access(c))
                        } else if (_op_stat(c) || _op_access(c))
                            errors.push(Err(0, ino, path));
                    }
                }
                if (c == hostname) out = _hostname(flags) + "\n";
                if (c == id) out = _id(flags, user_name, uid, gid, group_name) + "\n";
                if (c == pwd) out = cwd + "\n";
                if (c == whoami) out = user_name + "\n";
                if (c == cd) {
                    uint16 nwd;
                    string n_cwd;
                    (nwd, n_cwd, errors) = _cd(flags, args[0], wd);
                    if (nwd != wd) {
                        session.wd = nwd;
                        cwd = n_cwd;
                        ext_action |= EXT_CHANGE_DIR;
                    }
                }
            }
        }

        if (!errors.empty())
            action = ACT_PRINT_ERRORS;

        if (action == 0) {
            if (_op_stat(c)) action = ACT_PRINT_STATUS;
            if (_op_file(c) || _op_access(c)) action = ACT_FILE_OP;
            if (_is_pure(c)) action = ACT_PROCESS_COMMAND;
            if (_op_dev_stat(c)) action = ACT_DEVICE_STATUS;
            if (_op_format(c)) action = ACT_READ_INDEX;
            if (_op_user_admin(c)) action = ACT_USER_ADMIN_OP;
            if (_op_user_stats(c)) action = ACT_USER_STATS_OP;
            if (_op_user_access(c)) action = ACT_USER_ACCESS_OP;
            if (_reads_file_fixed(c) && out.empty()) action = ACT_READ_PAGE;

            if (_op_dev_admin(c)) action |= ACT_UPDATE_DEVICES;
            if (c == account) ext_action |= EXT_ACCOUNT;
            if (!x_target.empty()) {
                source = "vfs/proc/2/fd/1/out";
                action |= ACT_PIPE_OUT_TO_FILE;
            }
        }
    }

    /* Session commands */
    function _cd(uint flags, string s, uint16 wd) private view returns (uint16 nwd, string cwd, Err[] es) {
        if (((flags & _e + _P) > 0) && wd < INODES)
            es.push(Err(0, ENOENT, s));
        nwd = wd;
        (uint16 di, uint8 ft, , ) = _resolve_relative_path(s, nwd);
        if (di < INODES)
            es.push(Err(0, ENOENT, s));
        else if (ft != FT_DIR)
            es.push(Err(0, ENOTDIR, s));
        else if (es.empty()) {
            nwd = di;
            cwd = _get_absolute_path(nwd);
        }
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

    function _pwd(uint /*flags*/, uint16 wd) private view returns (string) {
//        bool follow_symlinks = ((flags & _L) > 0) && ((flags & _P) == 0);
        return _get_absolute_path(wd);
    }

    function _hostname(uint flags) internal view returns (string out) {
        bool long_host_name = (flags & _f) > 0;
        bool addresses = (flags & _i) > 0;

        string[] f_hostname = _get_file_contents("/etc/hostname");
        string s_domain = "tonix";

        if (addresses)
           return f_hostname[1];
        out = f_hostname[0];
        if (long_host_name)
            out.append("." + s_domain);
    }

    /* Path resolution commands */
    function _readlink(uint flags, string[] s_args, uint16 wd) internal view returns (string out, Err[] errors) {
        bool canon_existing_dir = (flags & _f) > 0;
        bool canon_existing = (flags & _e) > 0;
        bool canon_missing = (flags & _m) > 0;
        bool no_newline = (flags & _n) > 0;
        bool print_errors = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        bool canon = (flags & _f + _e + _m) > 0;
        uint16 mode = canon_existing ? 3 : canon_existing_dir ? 2 : canon_missing ? 1 : 0;

        for (string s_arg: s_args) {
            (, uint8 ft, uint16 parent, ) = _resolve_relative_path(s_arg, wd);
            string path;
            bool exists;
            if (canon)
                (path, exists) = _canonicalize(mode, s_arg, parent);
            else if (ft == FT_SYMLINK) {
                Arg arg = _dereference(mode + EXPAND_SYMLINKS, s_arg, wd);
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

    function _realpath(uint flags, string[] s_args, uint16 wd) internal view returns (string out, Err[] errors) {
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
            string path;
            uint16 dir_index;
            uint16 cur_dir;
            if (s_arg.substr(0, 1) == "/") {
                path = s_arg;
                cur_dir = _resolve_absolute_path(arg_dir);
            } else {
                path = _xpath(s_arg, wd);
                cur_dir = wd;
            }

            if (canon_existing_dir || canon_existing)
                dir_index = _dir_index(arg_base, cur_dir);

            if (dir_index > 0 && expand_symlinks) {
                (, , uint8 ft) = _read_dir_entry(_fs.inodes[cur_dir].text_data[dir_index - 1]);
                if (ft == FT_SYMLINK) {
                    Arg arg = _dereference(EXPAND_SYMLINKS, s_arg, wd);
                    (path, ft, , , dir_index) = arg.unpack();
                }
            }

            if (!canon_missing && dir_index == 0) {
                if (print_errors)
                    errors.push(Err(0, ENOENT, s_arg));
                continue;
            }
            out.append(path + line_delimiter);
        }
    }

    /* Path utilities helpers */
    function _abs_path_walk_up(uint16 dir) internal view returns (string path) {
        uint16 cur_dir = dir;
        while (cur_dir > ROOT_DIR) {
            Inode inode = _fs.inodes[cur_dir];
            path = inode.file_name + "/" + path;
            (, uint16 parent, ) = _read_dir_entry(inode.text_data[1]);
            cur_dir = parent;
        }
    }

    function _canonicalize(uint16 mode, string s_arg, uint16 wd) internal view returns (string res, bool valid) {
        uint16 canon_mode = mode & 3;

        (string arg_dir, string arg_base) = _dir(s_arg);
        string path;
        uint16 dir_index;
        uint16 cur_dir;
        valid = true;

        if (s_arg.substr(0, 1) == "/") {
            path = s_arg;
            cur_dir = _resolve_absolute_path(arg_dir);
        } else {
            path = _xpath(s_arg, wd);
            cur_dir = wd;
        }

        if (canon_mode >= CANON_DIRS) {
            dir_index = _dir_index(arg_base, cur_dir);
            valid = dir_index > 0;
        }

        if (canon_mode == CANON_NONE)
            res = s_arg;
        if (canon_mode == CANON_MISS || canon_mode == CANON_EXISTS)
            res = path;
        if (canon_mode == CANON_DIRS)
            res = _xpath(arg_dir, _resolve_absolute_path(arg_dir)) + "/" + arg_base;
    }

    function _dereference(uint16 mode, string s_arg, uint16 wd) internal view returns (Arg arg_out) {
        bool expand_symlinks = (mode & EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd);
        Inode inode;
        if (ino > 0 && _fs.inodes.exists(ino))
            inode = _fs.inodes[ino];
        if (expand_symlinks && ft == FT_SYMLINK)
            (s_arg, ino, ft) = _read_dir_entry(inode.text_data[0]);
        arg_out = Arg(s_arg, ft, ino, parent, dir_index);
    }

    /* Session helpers */
    function _get_process_id(uint16 uid) internal view returns (uint16) {
        for ((, ProcessInfo pi): _proc)
            if (pi.owner_id == uid)
                return pi.self_id;
    }

    function _query_user_data(string login) internal view returns (uint16, UserInfo) {
        for ((uint16 uid, UserInfo user_info): _users)
            if (login == user_info.user_name)
                return (uid, user_info);
    }

    /* Parsing helpers */
    /* Parser */
    function _parse_input(string s) private view returns (uint8 cmd, string cmds, string[] args, uint flags, string source, string target) {
        uint len = s.byteLength();
        uint pos;
        bool src_next;
        bool tgt_next;
        string lexem;
        uint p = _strchr(s, " ");
        cmds = p > 0 ? s.substr(0, p - 1) : s;
        cmd = _command_index(cmds);
        if (cmd == 0)
            return (CMD_UNKNOWN, cmds, args, flags, source, target);
        pos = p > 0 ? p - 1 : len;
        while (pos < len) {
            pos++;
            (lexem, pos) = _parse_to_symbol(s, pos, len, " ");
            uint l = lexem.byteLength();
            if (l == 0)
                break;
            if (lexem.substr(0, 1) == "-") {
                if (l > 1 && lexem.substr(1, 1) == "-") {
                    if (lexem == "--help") flags |= 1 << 255;
                    if (lexem == "--version") flags |= 1 << 254;
                } else {
                    bytes opts = bytes(lexem);
                    for (uint i = 1; i < opts.length; i++)
                        flags |= uint(1) << uint8(opts[i]);
                }
            } else if (lexem.substr(0, 1) == ">") {
                if (l == 1)
                    tgt_next = true;
                else
                    target = lexem.substr(1, l - 1);
            } else if (tgt_next) {
                target = lexem;
                tgt_next = false;
            } else if (lexem.substr(0, 1) == "<") {
                if (l == 1)
                    src_next = true;
                else
                    source = lexem.substr(1, l - 1);
            } else if (src_next) {
                source = lexem;
                src_next = false;
            } else
                args.push(lexem);
        }
    }

    function _init() internal override {
        _sync_fs_cache();
        address manual_pages = address.makeAddrStd(0, 0xcc59225a037b56f2cc325c9ced611994e160c4485537fe01ab3787e5d92ddac3);
        SharedCommandInfo(manual_pages).query_command_info{value: 0.2 ton}();
    }
}
