pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "IOptions.sol";
import "SyncFS.sol";

contract InputParser is IOptions, SyncFS {

    struct CmdInfoS {
        uint8 min_args;
        uint16 max_args;
        uint options;
    }
    mapping (uint8 => CmdInfoS) public _command_info;

    /* Primary entry point */
    function parse(string i_login, string i_cwd, string s_input) external view returns (Std std, SessionS ses, InputS input, uint16 action, string redirect, string[] names, address[] addresses) {
        string out;
        string err;
        ErrS[] errors;

        /* Validate session info: uid and wd */
        (string user_name, uint16 uid, uint16 gid, string group_name) = _query_user_data(i_login);
        uint16 wd = _resolve_abs_path(i_cwd);
        string cwd = wd > 0 ? i_cwd : "/";
        ses = SessionS(user_name, uid, gid, wd, cwd);

        /* Parse input line */
        (uint8 c, string cmds, string[] args, uint flags, string target) = _parse_input(s_input);
        redirect = target;
        if (c == CMD_UNKNOWN)
            err = cmds + ": command not found\n";
        else if (flags >= (1 << 254)) {
            if ((flags & 1 << 255) > 0)
                out = _get_help_text(cmds);
        } else {
            /* Push assumed arguments for certain commands */
            if (args.empty()) {
                if (c == du || c == ls || c == df)
                    args.push(".");
                if (c == cd)
                    args.push("~");
            }

            input = InputS(c, args, flags);
            /* Diagnose common errors early:
                - missing or extra operands
                - unknown options        */
            CmdInfoS ci = _command_info[c];
            uint16 nargs = uint16(args.length);
            uint extra_flags = flags - (ci.options & flags);
            string args_check;
            if (nargs < ci.min_args)
                args_check = "missing file operand";
            if (nargs > ci.max_args)
                args_check = "extra operand" + _quote(args[ci.max_args]);
            if (extra_flags > 0) {
                string extra_flags_s;
                for (uint i = 0; i < 255; i++)
                    if ((extra_flags & (1 << i)) > 0)
                        extra_flags_s.append(format("{} ", i));
                args_check = "invalid option -- " + extra_flags_s;
            }
            if (!args_check.empty())
                err.append(cmds + ": " + args_check + "\nTry " + cmds + " --help for more information.\n");
            else {

                if (c == basename) out = _basename(args, flags);
                if (c == dirname) out = _dirname(args);
                if (c == uname) out = _uname(flags);
                if (c == help) out = _help(args);
                if (c == echo) out = _echo(flags, args);
                if (c == man) out = _man(args);

                if (c == id) out = _id(flags, user_name, uid, gid, group_name);
                if (c == pwd) out = cwd;
                if (c == whoami) out = user_name;
                if (c == cd) {
                    uint16 nwd;
                    string n_cwd;
                    (nwd, n_cwd, errors) = _cd(flags, args[0], wd);
                    if (nwd != wd) {
                        ses.wd = nwd;
                        ses.cwd = n_cwd;
                        action |= CHANGE_DIR;
                    }
                }
                if (_op_network(c))
                    (out, names, addresses, action) = _network_op(c, flags, args);
                if (c == dd) {
                    (names, errors) = _dd(args, wd);
                    if (!names.empty())
                        action |= OPEN_FILE;
                }
            }
        }

        for (ErrS e: errors)
            err.append(_error_message(c, e));

        if (!redirect.empty()) action |= PIPE_OUT_TO_FILE;
        if (_op_stat(c) || _op_dev_stat(c)) action |= PRINT_STATUS;
        if (_op_file(c) || _op_access(c)) action |= PROCESS_COMMAND;

        std = Std(out, err);
    }

    /* Commands */

    function _dd(string[] args, uint16 wd) private view returns (string[] names, ErrS[] errors) {
        for (string s: args) {
            string dir_name = _dir(s);
            string file_name = _not_dir(s);
            uint16 dir = dir_name == "." ? wd : _resolve_abs_path(dir_name);
            (uint16 ino, ) = _inode_and_type(file_name, dir);
            if (ino >= INODES)
                errors.push(ErrS(0, EEXIST, s));
            else
                names.push(file_name);
        }
    }

    /* Session commands */
    function _cd(uint flags, string s, uint16 wd) private view returns (uint16 nwd, string cwd, ErrS[] es) {
        if (((flags & _e + _P) > 0) && wd < INODES)
            es.push(ErrS(0, ENOENT, s));
        nwd = wd;
        (uint16 di, uint8 ft) = _inode_and_type(s, nwd);
        if (di < INODES)
            es.push(ErrS(0, ENOENT, s));
        if (ft != FT_DIR)
            es.push(ErrS(0, ENOTDIR, s));
        if (es.empty()) {
            nwd = di;
            cwd = _get_abs_path(nwd);
        }
    }

    function _id(uint flags, string user_name, uint16 uid, uint16 gid, string group_name) private pure returns (string out) {
        bool effective_gid_only = (flags & _g) > 0;
//        bool all_gid = (flags & _G) > 0;
        bool name_not_number = (flags & _n) > 0;
        bool real_id = (flags & _r) > 0;
        bool effective_uid_only = (flags & _u) > 0;
//        bool null_delimiter = (flags & _z) > 0;

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
        return _get_abs_path(wd);
    }

    /* Informational commands */
    function _basename(string[] args, uint flags) private pure returns (string out) {
        bool multiple_args = (flags & _a) > 0; // -a
//        bool remove_suffices = (flags & _s) > 0; // -s
        string line_terminator = ((flags & _z) > 0) ? "\x00" : "\n";
//        string suffix = remove_suffices ? args[0] : "";

        if (multiple_args)
            for (string s: args)
                out.append(_not_dir(s) + line_terminator);
        else
            out = _not_dir(args[0]) + line_terminator;
    }

    function _dirname(string[] args) internal pure returns (string out) {
        for (string s: args)
            out += _dir(s) + "\n";
    }

    function _echo(uint flags, string[] ss) private pure returns (string out) {
        bool no_trailing_newline = (flags & _n) > 0;
        uint len = ss.length;
        if (len > 0) out = ss[0];
        for (uint i = 1; i < len; i++)
            out.append(" " + ss[i]);
        if (!no_trailing_newline)
            out.append("\n");
    }

    function _help(string[] args) private view returns (string out) {
        if (!args.empty()) {
            for (string s: args) {
                string help_text = _get_help_text(s);
                if (!help_text.empty())
                    out.append(help_text);
                else {
                    out.append("help: no help topics match" + _quote(s) + "\nTry" + _quote("help help") + "or" + _quote("man -k " + s) + "or" + _quote("info " + s) + "\n");
                    break;
                }
            }
        } else
            out = "Commands:\t" + _get_file_contents("/etc/commands") + "\n";
    }

    function _man(string[] args) private view returns (string out) {
        for (string s: args) {
            string text = _get_man_text(s);
            out.append(text.empty() ? "No manual entry for " + s + "\n" : text);
        }
    }

    function _uname(uint flags) private pure returns (string out) {
        if ((flags & _s) > 0 || flags == 0) out = "Tonix ";
        if ((flags & _n) > 0) out += "FileSys ";
        if ((flags & _i + _m) > 0) out += "TON ";
        if ((flags & _o) > 0) out.append("TON OS ");
        if ((flags & _p) > 0) out.append("TON ");
        if ((flags & _a) > 0) out = "Tonix FileSys TON TONOS TON";
    }

    /* Network commands */
    function _network_op(uint8 c, uint flags, string[] args) private view returns (string out, string[] names, address[] addresses, uint16 action) {
        if (c == mount) {
            (out, names, addresses) = _mount(flags, args);
            if (!addresses.empty())
                action |= MOUNT_FS;
            else if (!names.empty())
                action |= OPEN_DIR;
        }
        if (c == ping) {
            (names, addresses) = _ping(flags, args);
            if (!addresses.empty())
                action |= CHECK_STATUS;
        }
        if (c == account) {
            (names, addresses) = _account(flags, args);
            if (!addresses.empty())
                action |= CHECK_STATUS;
        }
    }

    function _mount(uint flags, string[] args) private view returns (string out, string[] names, address[] addresses) {
        bool mount_all = (flags & _a) > 0;
//        bool canonicalize_paths = (flags & _c) == 0;
        bool dry_run = (flags & _f) > 0;
//        bool show_labels = (flags & _l) > 0;
//        bool no_mtab = (flags & _n) > 0;
//        bool verbose = (flags & _v) > 0;
//        bool read_write = (flags & _w) > 0;
//        bool alt_fstab = (flags & _T) > 0;
//        bool read_only = (flags & _r) > 0;
        bool another_namespace = (flags & _N) > 0;
//        bool bind_subtree = (flags & _B) > 0;
//        bool move_subtree = (flags & _M) > 0;

        if (another_namespace) {
            names.push(args[0]);
        } else {
            if (args.empty() && mount_all) {
                for (string s: _get_lines(_get_file_contents("/etc/fstab"))) {
                    string[] fields = _read_entry(s);
                    address source = _to_address(_lookup_pair_value(fields[0], _get_file_contents("/etc/hosts")));
                    string target = fields[1];
                    if (!dry_run) {
                        names.push(target);
                        addresses.push(source);
                    } else
                        out.append(format("{}\t{}\n", target, source));
                }
            } else {
                for (string s: args) {
                    names.push(_match_value_at_index(1, s, 2, _get_file_contents("/etc/fstab")));
                    addresses.push(_to_address(_lookup_pair_value(s, _get_file_contents("/etc/hosts"))));
                }
            }
        }
    }

    function _ping(uint flags, string[] args) private view returns (string[] names, address[] addresses) {
        string text = _get_file_contents("/etc/hosts");
        if (!args.empty())
            for (string s: args) {
                if ((flags & _d) == 0) {
                    if ((flags & _D) > 0)
                        s = format("[{}] ", now) + s;
                    names.push(s);
                    addresses.push(_to_address(_lookup_pair_value(s, text)));
                }
            }
        else {
            for (string s: _get_lines(text)) {
                string[] fields = _read_entry(s);
                names.push(fields[1]);
                addresses.push(_to_address(fields[0]));
            }
        }
    }

    function _account(uint flags, string[] args) private view returns (string[] host_names, address[] addresses) {
        string text = _get_file_contents("/etc/hosts");
        if (!args.empty())
            for (string s: args) {
                if ((flags & _d) == 0) {
                    host_names.push(s);
                    addresses.push(_to_address(_lookup_pair_value(s, text)));
                }
            }
        else {
            for (string s: _get_lines(text)) {
                string[] fields = _read_entry(s);
                host_names.push(fields[1]);
                addresses.push(_to_address(fields[0]));
            }
        }
    }

    /* Network helpers */
    function _to_address(string s_addr) private pure returns (address addr) {
        uint len = s_addr.byteLength();
        if (len > 60) {
            string s_hex = "0x" + s_addr.substr(2, len - 2);
            (uint u_addr, bool success) = stoi(s_hex);
            if (success)
                return address.makeAddrStd(0, u_addr);
        }
    }

    /* Command info helpers */
    function _get_command_info(string s) private view returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        string[] lines = _get_lines(_get_file_contents("/usr/share/commands/" + s));
        if (!lines.empty()) {
            name = lines[0];
            purpose = lines[1];
//          desc = lines[3];
            desc = _join_fields(_read_entry(lines[3]));
            uses = _read_entry(lines[2]);
            option_names = lines[4];
            option_descriptions = _read_entry(lines[5]);
        } else
            name = "failed to read command data\n";
    }

    function _get_man_text(string s) private view returns (string) {
        (string name, string purpose, string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(s);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options;
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("\t" + "-" + option_names.substr(i, 1) + "\t" + option_descriptions[i] + "\n");
        options.append("\t" + "--help\tdisplay this help and exit\n\t--version\n\t\toutput version information and exit\n");

        return name + "(1)\t\t\t\t\tUser Commands\n\nNAME\n\t" + name + " - " + purpose + "\n\nSYNOPSIS\n" + usage +
            "\nDESCRIPTION\n\t" + description + "\n\n" + options;
    }

    function _get_help_text(string s) private view returns (string) {
        (string name, , string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(s);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options;
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_names.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + usage + description + "\n" + options;
    }

    /* Session helpers */
    function _query_user_data(string login) internal view returns (string user_name, uint16 uid, uint16 gid, string group_name) {
        string[] records = _lookup_record(0, login, _get_file_contents("/etc/passwd"));
        user_name = !records.empty() ? records[0] : "guest";
        (uint res, bool success) = stoi(records[1]);
        uid = success ? uint16(res) : GUEST_USER;
        (res, success) = stoi(records[2]);
        gid = success ? uint16(res) : GUEST_USER_GROUP;
        group_name = records.length > 2 ? records[3] : "guest";
    }

    /* Parsing helpers */
    function _parse_to_symbol(string s, uint start, uint len, string sym) private pure returns (string, uint pos) {
        pos = start;
        while (pos < len) {
            if (s.substr(pos, 1) == sym)
                return (s.substr(start, pos - start), pos);
            pos++;
        }
        return (pos > start ? s.substr(start, pos - start) : "", pos);
    }

    /* Parser */
    function _parse_input(string s) private view returns (uint8 cmd, string cmds, string[] args, uint flags, string target) {
        uint len = s.byteLength();
        uint pos;
        bool tgt_next;
        string lexem;
        (cmds, pos) = _parse_to_symbol(s, 0, len, " ");
        cmd = _command_by_name(cmds);
        if (cmd == CMD_UNKNOWN)
            return (CMD_UNKNOWN, cmds, args, flags, target);
        while (pos < len) {
            pos++;
            (lexem, pos) = _parse_to_symbol(s, pos, len, s.substr(pos, 1) == "\"" ? "\"" : " ");
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
            } else
                args.push(lexem);
        }
    }


    /* Command info composition */
    function _init() internal override {
        _sync_fs_cache();
        uint _RHLP = _R + _H + _L + _P;
        uint _bfntTv = _b + _f + _n + _t + _T + _v;
        _insert(account,    0, M, _D);
        _insert(basename,   1, M, _a + _s + _z);
        _insert(cat,        1, M, _b + _e + _E + _n + _s + _t + _T + _u + _v);
        _insert(cd,         1, 1, _L + _P + _e);
        _insert(chgrp,      2, M, _c + _f + _v + _h + _RHLP);
        _insert(chmod,      2, M, _c + _f + _v + _R);
        _insert(chown,      2, M, _c + _f + _v + _h + _RHLP);
        _insert(cksum,      1, M, 0);
        _insert(cmp,        2, 2, _b + _i + _l + _n + _s + _v);
        _insert(column,     0, M, _e + _n + _t + _x);
        _insert(cp,         2, M, _a + _d + _l + _p + _r + _s + _u + _x + _RHLP + _bfntTv);
        _insert(cut,        0, 1, _f + _s + _z);
        _insert(dd,         0, M, 0);
        _insert(df,         1, M, _a + _h + _H + _i + _k + _l + _P + _v);
        _insert(dirname,    1, M, _z);
        _insert(du,         1, M, _a + _b + _c + _D + _h + _H + _k + _l + _L + _m + _P + _s + _S + _x + _0);
        _insert(echo,       1, M, _n);
        _insert(file,       1, M, _b + _E + _N + _v + _0);
        _insert(findmnt,    0, M, _s + _m + _k + _A + _b + _D + _f + _n + _u);
        _insert(grep,       2, M, _i + _v + _w + _x);
        _insert(help,       0, M, _d + _m);
        _insert(id,         0, 1, _a + _g + _G + _n + _r + _u + _z);
        _insert(ln,         2, M, _r + _s + _L + _P + _bfntTv);
        _insert(ls,         1, M, _a + _A + _B + _c + _C + _d + _f + _F + _g + _G + _h + _H + _i + _k + _l + _L + _m + _n + _N +
            _o + _p + _q + _Q + _r + _R + _s + _S + _t + _u + _U + _v + _x + _1);
        _insert(lsblk,      0, M, _a + _b + _f + _m + _n + _O + _p);
        _insert(man,        0, M, _a);
        _insert(mkdir,      1, M, _m + _p + _v);
        _insert(mount,      0, 3, _a + _c + _f + _T + _l + _n + _r + _v + _w + _N + _B + _M);
        _insert(mv,         2, M, _u + _bfntTv);
        _insert(paste,      1, M, _s + _z);
        _insert(ping,       0, M, _D + _n + _q + _U + _v);
        _insert(pwd,        0, 0, _L + _P);
        _insert(rm,         1, M, _f + _r + _R + _d + _v);
        _insert(rmdir,      1, M, _p + _v);
        _insert(stat,       1, M, _L + _f + _t);
        _insert(touch,      1, M, _a + _c + _m);
        _insert(uname,      0, 0, _a + _s + _n + _r + _v + _m + _p + _i + _o);
        _insert(wc,         1, M, _c + _m + _l + _L + _w);
        _insert(whoami,     0, 0, 0);
    }

    function _insert(uint8 index, uint8 min_args, uint16 max_args, uint options) private {
        _command_info[index] = CmdInfoS(min_args, max_args, options);
    }

}
