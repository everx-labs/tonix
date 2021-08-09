pragma ton-solidity >= 0.48.0;

import "IData.sol";
import "IOptions.sol";
import "FSCache.sol";
import "INode.sol";

contract CommandProcessor is FSCache, IOptions {

    function process(SessionS ses, InputS input) external view returns (Std std, SessionS o_ses, INodeEventS[] ines, IOEventS[] ios, uint16 action) {
        /* Validate session info: uid and wd */
        uint16 uid = _users.exists(ses.uid) ? ses.uid : _init_ids[11];
        uint16 gid = _ugroups.exists(ses.gid) ? ses.gid : _get_group_id(uid);
        uint16 wd = _inodes.exists(ses.wd) ? ses.wd : _users[uid].home_dir;
        o_ses = SessionS(uid, gid, wd);
        (uint8 c, string[] args, uint flags, string target) = input.unpack();
        string in_;
        string out;
        string err;

        ErrS[] errors;

        if (args.length == 0) {
            if (c == pwd) out = _pwd(flags, wd) + "\n";
            if (c == whoami) out = _users[uid].name + "\n";
        }

        /* Process related operations in separate subroutines */
        if (_op_access(c))
            (out, ines, errors) = _access_ops(c, args, flags, wd);
        if (c == mkdir || c == touch)
            (out, ines, ios, errors) = _create_file_ops(c, args, flags, wd);
        if (c == rm || c == rmdir)
            (out, ios, errors) = _remove_file_ops(c, args, flags, wd);
        if (c == cp || c == mv || c == ln)
            (out, ios, errors) = _file_ops(c, args, flags, wd);

        if (c == cd) (o_ses.wd, errors) = _cd(flags, args[0], wd);
        if (c == echo) out = _echo(flags, args);
        if (c == dd) out = _dd(args[0]);
        if (c == cmp) (out, err) = _cmp(flags, args, wd);

        if (_op_fs(c)) out = _mount(flags, args, wd);

        if (_op_network(c)) {
            if (c == ping) out = _ping(flags, args[0], wd);
            if (c == account) out = _account(flags, args[0], wd);
        }

        if (target != "") {
            (uint16 tgt, ) = _lookup_in_dir(target, wd);
            ios.push(tgt < INODES ? IOEventS(IO_MKFILE, wd, gid, target, out) : IOEventS(IO_WR_APPEND, tgt, gid, target, out));
            out = "";
        }
        for (ErrS e: errors)
            err.append((e.code == 1) ? _error_message2(c, e) : _internal_error_message(c, e));
        std = Std(out, err);

        if (!err.empty()) action |= PRINT_ERROR;
        if (!out.empty()) action |= PRINT_OUT;
        if (!in_.empty()) action |= PRINT_IN;
        if (!ines.empty()) action |= INODE_EVENT;
        if (!ios.empty()) action |= IO_EVENT;
    }

    /* Session commands */
    function _cd(uint flags, string s, uint16 cwd) private view returns (uint16 wd, ErrS[] es) {
        if (((flags & _e + _P) > 0) && cwd < DIRENTS)
            es.push(ErrS(1, 0, /*no_such_file_or_dir*/ENOENT, s));
        wd = cwd;
        bool follow_symlinks = ((flags & _L) > 0) && ((flags & _P) == 0);
        (uint16 di, ) = follow_symlinks ? _lookup_opnd_deref(s, wd, 1) : _lookup_in_dir(s, wd);
        if (di < INODES)
            es.push(ErrS(1, 0, /*no_such_file_or_dir*/ENOENT, s));
        else
            wd = di;
    }

    function _pwd(uint flags, uint16 wd) private view returns (string) {
        bool follow_symlinks = ((flags & _L) > 0) && ((flags & _P) == 0);
        (uint16 di, ) = follow_symlinks ? _lookup_opnd_deref(_inodes[wd].file_name, wd, 1) : (wd, 0);
        return _inodes[di].text_data;
    }

    /* Access operations common routine */
    function _access_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string /*out*/, INodeEventS[] ins, ErrS[] errors) {
        uint16 val = 0;
        string s0 = args[0];

        if (c == chgrp) {
            for ((uint16 i, UserGroup ug): _ugroups)
                if (s0 == ug.name) {
                    val = i;
                    break;
                }
            if (val == 0)
                errors.push(ErrS(1, invalid_group, 0, s0));
        } else if (c == chmod) {
            (uint val2, bool success) = stoi(s0);
            if (!success)
                errors.push(ErrS(1, invalid_mode, 0, s0));
            else
                val = uint16(val2);
        } else if (c == chown) {
            for ((uint16 i, User u): _users)
                if (s0 == u.name) {
                    val = i;
                    break;
                }
            if (val == 0)
                errors.push(ErrS(1, invalid_owner, 0, s0));
        }

        if (val > 0) {
            for (string s: args) {
                if (s == s0)
                    continue;
                (, uint16 di) = _lookup_in_dir(s, wd);
                if (di < DIRENTS)
                    errors.push(ErrS(1, _command_reason(c), di, ""));
                else
                    (ins, errors) = _process_access_op(c, flags, val, _de[di]);
            }
        }
    }

//    function _process_access_op(uint8 c, uint flags, uint16 val, uint16[] dis) private view returns (INodeEventS[] ins, ErrS[] errors) {
    function _process_access_op(uint8 c, uint flags, uint16 val, DirEntry dirent) private view returns (INodeEventS[] ins, ErrS[] errors) {
        bool recursive = (flags & _R) > 0;
        /*bool traverse_arg = (flags & _H) > 0;
        bool traverse_all_symlinks = (flags & _L) > 0;
        bool do_not_traverse_symlinks = (flags & _P) > 0;*/
        uint16 op = dirent.inode;
        if (op < INODES)
            errors.push(ErrS(1, _command_reason(c), op, ""));
        else {
            if (c == chgrp) ins.push(INodeEventS(INO_CHATTR, op, 0, val, 0));
            if (c == chmod) ins.push(INodeEventS(INO_PERMISSION, op, val, 0, 0));
            if (c == chown) ins.push(INodeEventS(INO_CHATTR, op, val, 0, 0));
            if (recursive && dirent.file_type == FT_DIR) {
                for (uint16 dc:_dc[op]) {
                    if (dc > 0 && _de.exists(dc)) {
                        DirEntry d = _de[dc];
                        if (d.name == "." || d.name == "..")
                            continue;
                        (INodeEventS[] inss, ErrS[] errorss) = _process_access_op(c, flags, val, d);
                        for (INodeEventS e: inss) ins.push(e);
                        for (ErrS e: errorss) errors.push(e);
                    }
                }
            }
        }
    }

    function _create_file_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, INodeEventS[] ins, IOEventS[] ios, ErrS[] errors) {
        bool verbose = (flags & _v) > 0;
        bool md = c == mkdir;
        for (string s: args) {
            (uint16 iop, uint16 op) = _lookup_in_dir(s, wd);
            if (op < DIRENTS)
                ios.push(IOEventS(md ? IO_MKDIR : IO_MKFILE, wd, 0, s, md ? _pwd(0, wd) + "/" + s : ""));
            else {
                if (md)
                    errors.push(ErrS(1, _command_reason(c), EEXIST, s));
                else
                    ins.push(INodeEventS(INO_UPDATE_TIME, iop, 0, 0, now));
            }
        }
        if (verbose && md)
            for (IOEventS e: ios)
                out.append("mkdir: created directory" + _quote(e.path) + "\n");
    }
    function _remove_file_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, IOEventS[] ios, ErrS[] errors) {
        bool verbose = (flags & _v) > 0;
        bool rf = c == rm;
        for (string s: args) {
            (, uint16 op) = _lookup_in_dir(s, wd);
            if (op < DIRENTS)
                errors.push(ErrS(1, _command_reason(c), ENOENT, s));
            else {
                (uint16 inode, uint16 parent, string name, uint8 ft) = _de[op].unpack();
                if (rf) {
                    if (ft != FT_DIR)
                        ios.push(IOEventS(IO_UNLINK, parent, op, name, ""));
                    else
                        errors.push(ErrS(1, _command_reason(c), EISDIR, s));
                } else {
                    if (ft == FT_DIR) {
                        if (_dc[inode].length <= 2)
                            ios.push(IOEventS(IO_UNLINK, parent, op, name, ""));
                        else
                            errors.push(ErrS(1, _command_reason(c), ENOTEMPTY, s));
                    } else
                        errors.push(ErrS(1, _command_reason(c), ENOTDIR, s));
                }
            }
        }
        if (verbose)
            for (IOEventS e: ios)
                out.append(rf ? "removed" : "rmdir: removing directory," + _quote(e.path) + "\n");
    }
    /* File operations common routine */
    function _file_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, IOEventS[] ios, ErrS[] errors) {
        bool verbose = (flags & _v) > 0;
        bool preserve = (flags & _n) > 0;
        bool request_backup = (flags & _b) > 0;
        bool to_file_flag = (flags & _T) > 0;
        bool to_dir_flag = (flags & _t) > 0;
        bool newer_only = (flags & _u) > 0;
        bool force = (flags & _f) > 0;
        bool hardlink = (c == cp) && ((flags & _l) > 0);
        bool symlink = (c == ln) && ((flags & _s) > 0);
        bool to_dir = to_dir_flag;
        bool recurse = (flags & _r + _R) > 0;

        uint nargs = args.length;
        (uint16 t_ino, uint16 t_fop) = _lookup_in_dir(args[to_dir_flag ? 0 : nargs - 1], wd);
        bool dest_exists = t_fop >= DIRENTS;
        DirEntry dt;

        if (dest_exists) {
            dt = _de[t_fop];
            if (dt.file_type == FT_DIR)
                to_dir = true;
        }

        bool collision = dest_exists && dt.file_type == FT_REG_FILE;
        string t_path = collision ? dt.name : args[to_dir_flag ? 0 : nargs - 1];
        bool overwrite_dest = collision && (!preserve || force);

        if (collision) {
            if (preserve)
                return (out, ios, errors);
            if (request_backup && overwrite_dest) {
                ios.push(IOEventS(IO_MKFILE, wd, t_ino, t_path + "~", _inodes[t_ino].text_data));
                if (verbose)
                    out.append("(backup:" + _quote(t_path + "~") + ")");
            }
        }

        uint last = to_dir_flag ? nargs : nargs - 1;
        uint first = to_dir_flag ? 1 : 0;

        uint8 etype = 0;
        if (c == cp && !hardlink || c == mv && !to_dir)
            etype = IO_MKFILE;
        if (c == ln && !symlink || c == cp && hardlink || c == mv && to_dir)
            etype = IO_HARDLINK;
        if (c == ln && symlink)
            etype = IO_SYMLINK;

        for (uint i = first; i < last; i++) {
            string s = args[i];
            (uint16 iop, uint16 op) = _lookup_in_dir(s, wd);

            if (op < DIRENTS && iop < INODES) {
                errors.push(ErrS(1, _command_reason(c), ENOENT, s));
                return (out, ios, errors);
            }
            DirEntry de = _de[op];

            if (verbose) {
                if (c == mv) out.append("renamed");
                out.append(_quote(s) + (c == ln ? "->" : "=>") + _quote(t_path));
            }

            if (de.file_type == FT_DIR && !recurse)
                errors.push(ErrS(1, omitting_directory, 0, "-r not specified; omitting directory " + s));
            else if (to_file_flag && to_dir && de.file_type == FT_REG_FILE)
                errors.push(ErrS(1, cant_overwrite_dir, 0, "cannot overwrite directory" + _quote(t_path) + "with non-directory"));
            else if (collision && newer_only) {
                if (_ino_ts[t_ino].modified_at > _ino_ts[iop].modified_at)
                    continue;
            } else {
                if (etype > 0)
//                    ios.push(IOEventS(etype, to_dir ? t_ino : wd, iop, to_dir ? s : t_path, _inodes[iop].text_data));
                    ios.push(IOEventS(etype, to_dir ? t_ino : wd, iop, _not_dir(to_dir ? s : t_path), _inodes[iop].text_data));
                if (c == mv)
                    ios.push(IOEventS(IO_UNLINK, de.parent, op, "", ""));
            }
        }
        if (overwrite_dest && errors.empty())
            ios.push(IOEventS(IO_UNLINK, dt.parent, t_fop, "", ""));
    }

//    function _read_fstab() private view returns ()

    function _hosts(uint16 id) private view returns (string addr, string account) {
        string s = _inodes[id].text_data;
        uint16 p = _strchr(s, "\t");
        uint16 n = _strchr(s, "\n");
        addr = s.substr(0, p - 2);
        account = s.substr(p, n - p);
    }

    function _mount(uint flags, string[] args, uint16 wd) private view returns (string out) {
        if ((flags & _a) > 0) {
            // mount all fstab
  //          for ()
        }
        (string addr, string accnt) = _hosts(wd);
        out = addr + " : " + accnt + "\n";
        if ((flags & _q) == 0) {
            if (wd > 0)
                out = args[0];
            if ((flags & _v) > 0) {
            }
        }
    }
    function _ping(uint flags, string arg, uint16 wd) private pure returns (string out) {
        if ((flags & _q) == 0) {
            if (wd > 0)
                out = arg;
            if ((flags & _v) > 0) {
            }
        }
    }

    function _get_etc(string s) private view returns (uint16 ino) {
        (ino, ) = _lookup_in_dir(s, _init_ids[4]);
    }

    function _account(uint flags, string arg, uint16 wd) private view returns (string out) {
        if ((flags & _d) == 0) {
//            uint16 ihosts = _get_etc("hosts");
            (uint16 ihosts, ) = _lookup_in_dir("hosts", _init_ids[4]);
            INodeS hosts = _inodes[ihosts];
            string text = hosts.text_data;
            out = text;
            (string addr, string accnt) = _hosts(ihosts);
            out += addr + " : " + accnt + "\n";
//            out += _hosts(ihosts);
        }
    }

    /********************** File system read commands *************************/
    function _cmp(uint flags, string[] args, uint16 wd) private view returns (string out, string err) {
    }

    function _dd(string /*s*/) private view returns (string out) {
        for ((uint16 i, INodeS ino): _inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, string file_name, ) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} SZ {} NL {}\n", i, file_name, mode, owner_id, group_id, file_size, n_links));
        }
        for ((uint16 i, DirEntry d): _de) {
            (uint16 id, uint16 parent, string name,) = d.unpack();
            out.append(format("D {} INO {} PAR {} N {} \n", i, id, parent, name));
        }
        for ((uint16 i, uint16[] cc): _dc) {
            out.append(format("DIR: {}\t", i) + _inodes[i].text_data + "\t");
            for (uint16 c: cc) {
                if (c == 0) continue;
                out.append(format("{} ", c) + _de[c].name + "  ");
            }
            out.append("\n");
        }
        out.append("\n");
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

    /******* Helpers ******************/

    function init() external override accept {
        _init_commands();
        _init_errors();
        _sync_fs_cache();
    }

}
