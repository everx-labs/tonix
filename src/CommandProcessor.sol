pragma ton-solidity >= 0.48.0;

import "IData.sol";
import "IOptions.sol";
import "FSCache.sol";
import "INode.sol";
import "Map.sol";

contract CommandProcessor is FSCache, IOptions, Map {

    function process(SessionS ses, InputS input) external view returns (Std std, INodeEventS[] ines, IOEventS[] ios, uint16 action) {
        (, , uint16 wd) = ses.unpack();
        (uint8 c, string[] args, uint flags, ) = input.unpack();
        string in_;
        string out;
        string err;

        ErrS[] errors;

        /* Process related operations in separate subroutines */
        if (_op_access(c))
            (out, ines, errors) = _access_ops(c, args, flags, wd);
        if (c == mkdir || c == touch)
            (out, ines, ios, errors) = _create_file_ops(c, args, flags, wd);
        if (c == rm || c == rmdir)
            (out, ios, errors) = _remove_file_ops(c, args, flags, wd);
        if (c == cp || c == mv || c == ln)
            (out, ios, errors) = _file_ops(c, args, flags, wd);

        if (c == dd) out = _dd(args[0]);
        if (c == cmp) (out, err) = _cmp(flags, args, wd);

        if (_op_fs(c)) out = _mount(flags, args, wd);

        if (_op_network(c)) {
            if (c == ping) {
                out = _ping(flags, args[0]);
                if (!out.empty()) action |= CHECK_STATUS;
            }
            if (c == account) {
                out = _account(flags, args[0]);
                if (!out.empty()) action |= QUERY_BALANCE;
            }
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
                (uint16 ino, uint8 ft) = _lookup_inode_and_type(s, wd);
                if (ino < INODES)
                    errors.push(ErrS(1, _command_reason(c), ino, ""));
                else
                    (ins, errors) = _process_access_op(c, flags, val, ino, ft);
            }
        }
    }

//    function _process_access_op(uint8 c, uint flags, uint16 val, uint16[] dis) private view returns (INodeEventS[] ins, ErrS[] errors) {
    function _process_access_op(uint8 c, uint flags, uint16 val, uint16 ino, uint8 ft) private view returns (INodeEventS[] ins, ErrS[] errors) {
        bool recursive = (flags & _R) > 0;
        /*bool traverse_arg = (flags & _H) > 0;
        bool traverse_all_symlinks = (flags & _L) > 0;
        bool do_not_traverse_symlinks = (flags & _P) > 0;*/
//        uint16 op = dirent.inode;
        if (ino < INODES) {
            errors.push(ErrS(1, _command_reason(c), ino, ""));
            return (ins, errors);
        }

        if (c == chgrp) ins.push(INodeEventS(INO_CHATTR, ino, 0, val, 0));
        if (c == chmod) ins.push(INodeEventS(INO_PERMISSION, ino, val, 0, 0));
        if (c == chown) ins.push(INodeEventS(INO_CHATTR, ino, val, 0, 0));

        if (!recursive || ft != FT_DIR)
            return (ins, errors);

        (uint16[] inodes, string[] names, uint8[] types) = _get_dir_contents(_inodes[ino]);

        for (uint16 j = 0; j < inodes.length; j++) {
            if (names[j] == "." || names[j] == "..")
                continue;
            (INodeEventS[] inss, ErrS[] errorss) = _process_access_op(c, flags, val, inodes[j], types[j]);
            for (INodeEventS e: inss)
                ins.push(e);
            for (ErrS e: errorss)
                errors.push(e);
        }
    }

    function _create_file_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, INodeEventS[] ins, IOEventS[] ios, ErrS[] errors) {
        bool verbose = (flags & _v) > 0;
        bool md = c == mkdir;
        for (string s: args) {
            uint16 iop = _lookup_inode_in_dir(s, wd);
            if (iop < INODES)
                ios.push(IOEventS(md ? IO_MKDIR : IO_MKFILE, wd, 0, s, ""));
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
            (uint16 iop, uint8 ft) = _lookup_inode_and_type(s, wd);

            if (iop < INODES)
                errors.push(ErrS(1, _command_reason(c), ENOENT, s));
            else {
                if (rf) {
                    if (ft != FT_DIR)
                        ios.push(IOEventS(IO_UNLINK, wd, iop, s, ""));
                    else
                        errors.push(ErrS(1, _command_reason(c), EISDIR, s));
                } else {
                    if (ft == FT_DIR) {
                        if (_inodes[iop].file_size <= 10)
                            ios.push(IOEventS(IO_UNLINK, wd, iop, s, ""));
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
        string target = args[to_dir_flag ? 0 : nargs - 1];
        (uint16 t_ino, uint8 t_ft) = _lookup_inode_and_type(target, wd);
        bool dest_exists = t_ino >= INODES;

        if (dest_exists && t_ft == FT_DIR)
            to_dir = true;

        bool collision = dest_exists && t_ft == FT_REG_FILE;
        string t_path = collision ? target : args[to_dir_flag ? 0 : nargs - 1];
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
            (uint16 iop, uint8 s_ft) = _lookup_inode_and_type(s, wd);

            if (iop < INODES) {
                errors.push(ErrS(1, _command_reason(c), ENOENT, s));
                return (out, ios, errors);
            }

            if (verbose) {
                if (c == mv) out.append("renamed");
                out.append(_quote(s) + (c == ln ? "->" : "=>") + _quote(t_path));
            }

            if (s_ft == FT_DIR && !recurse)
                errors.push(ErrS(1, omitting_directory, 0, "-r not specified; omitting directory " + s));
            else if (to_file_flag && to_dir && s_ft == FT_REG_FILE)
                errors.push(ErrS(1, cant_overwrite_dir, 0, "cannot overwrite directory" + _quote(t_path) + "with non-directory"));
            else if (collision && newer_only) {
                if (_ino_ts[t_ino].modified_at > _ino_ts[iop].modified_at)
                    continue;
            } else {
                if (etype > 0)
                    ios.push(IOEventS(etype, to_dir ? t_ino : wd, iop, _not_dir(to_dir ? s : t_path), _inodes[iop].text_data));
                if (c == mv)
                    ios.push(IOEventS(IO_UNLINK, wd, iop, "", ""));
            }
        }
        if (overwrite_dest && errors.empty())
            ios.push(IOEventS(IO_UNLINK, wd, t_ino, "", ""));
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
    function _ping(uint flags, string arg) private view returns (string out) {
        if ((flags & _q) == 0) {
            uint16 ihosts = _lookup_inode_in_dir("hosts", _get_etc_dir());
            out = _lookup_value(arg, _inodes[ihosts].text_data) + "\n";
        }
    }

    function _get_etc(string s) private view returns (uint16 ino) {
        ino = _lookup_inode_in_dir(s, _get_etc_dir());
    }

    function _account(uint flags, string arg) private view returns (string out) {
        if ((flags & _d) == 0) {
            uint16 ihosts = _lookup_inode_in_dir("hosts", _get_etc_dir());
            out = _lookup_value(arg, _inodes[ihosts].text_data) + "\n";
        }
    }

    /********************** File system read commands *************************/
    function _cmp(uint flags, string[] args, uint16 wd) private view returns (string out, string err) {
        bool verbose = (flags & _l) > 0;
        bool print_bytes = (flags & _b) > 0;

        uint16 i1 = _lookup_inode_in_dir(args[0], wd);
        uint16 i2 = _lookup_inode_in_dir(args[1], wd);
        string t1 = _inodes[i1].text_data;
        string t2 = _inodes[i2].text_data;
        bytes b1 = bytes(t1);
        bytes b2 = bytes(t2);
        for (uint16 i = 0; i < t1.byteLength(); i++) {
            uint8 u1 = uint8(b1[i]);
            uint8 u2 = uint8(b2[i]);
            if (u1 != u2) {
                if (!verbose) {
                    out = _inodes[i1].file_name + " " + _inodes[i2].file_name + " differ: byte" + _if(format(" {}", i), print_bytes, format(" is {}", u1)) + "\n";
                    return (out, err);
                }
                out += format("{:3} {:3} {:3}\n", i, u1, u2);
            }
        }
    }

    function _dd(string /*s*/) private view returns (string out) {
        for ((uint16 i, INodeS ino): _inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, string file_name, string text_data) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} SZ {} NL {}\n", i, file_name, mode, owner_id, group_id, file_size, n_links));
            if (_mode_is_dir(mode))
                out.append("\n" + text_data);
        }
        out.append("\n");
    }

    /******* Helpers ******************/

    function init() external override accept {
        _init_commands();
        _init_errors();
        _sync_fs_cache();
    }

}
