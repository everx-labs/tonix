pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "IOptions.sol";
import "SyncFS.sol";

contract CommandProcessor is SyncFS, IOptions {

    function process(SessionS ses, InputS input) external view returns (Std std, IOEventS[] ios, uint16 action) {
        uint16 wd = ses.wd;
        (uint8 c, string[] args, uint flags) = input.unpack();
        string out;
        string err;

        ErrS[] errors;

        /* Process related operations in separate subroutines */
        if (_op_access(c))
            (out, ios, errors) = _access_ops(c, args, flags, wd);
        if (c == mkdir || c == touch)
            (out, ios, errors) = _create_file_ops(c, args, flags, wd);
        if (c == rm || c == rmdir)
            (out, ios, errors) = _remove_file_ops(c, args, flags, wd);
        if (c == cp || c == mv || c == ln)
            (out, ios, errors) = _file_ops(c, args, flags, wd);

        if (c == cmp) (out, err) = _cmp(flags, args, wd);

        for (ErrS e: errors)
            err.append(_error_message(c, e));
        std = Std(out, err);

        if (!ios.empty()) {
            /*for (IOEventS e: ios) {
                if (e.iotype == IO_WR_COPY || e.iotype == IO_MKFILE || e.iotype == IO_ALLOCATE || e.iotype == IO_MKDIR || e.iotype == IO_SYMLINK)
                    action |= ADD_NODES;
                if (e.iotype == IO_UNLINK || e.iotype == IO_HARDLINK || e.iotype == INO_CHATTR || e.iotype == INO_ACCESS || e.iotype == INO_PERMISSION || e.iotype == INO_UPDATE_TIME)
                    action |= UPDATE_NODES;
            }*/
            action |= UPDATE_NODES;
        }
    }

    /* Access operations common routine */
    function _access_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string /*out*/, IOEventS[] ins, ErrS[] errors) {
        uint16 val = 0;
        string s0 = args[0];
        uint16[] indices;
        string[] paths;

        if (c == chgrp)
            val = _lookup_group_id(s0);
        else if (c == chmod) {
            (uint val2, bool success) = stoi(s0);
            if (!success)
                errors.push(ErrS(invalid_mode, 0, s0));
            else
                val = uint16(val2);
        } else if (c == chown)
            val = _lookup_user_id(s0);

        for (string s: args) {
            if (s == s0)
                continue;
            (uint16 ino, uint8 ft) = _inode_and_type(s, wd);
            if (ino < INODES)
                errors.push(ErrS(0, ino, ""));
            else
                (indices, paths, errors) = _process_access_op(c, flags, val, ino, ft);
        }
        if (c == chgrp) ins.push(IOEventS(IO_CHATTR, wd, indices, paths));
        if (c == chmod) ins.push(IOEventS(IO_PERMISSION, wd, indices, paths));
        if (c == chown) ins.push(IOEventS(IO_CHATTR, wd, indices, paths));
    }

    function _process_access_op(uint8 c, uint flags, uint16 val, uint16 ino, uint8 ft) private view returns (uint16[] indices, string[] paths, ErrS[] errors) {
        bool recursive = (flags & _R) > 0;
        /*bool traverse_arg = (flags & _H) > 0;
        bool traverse_all_symlinks = (flags & _L) > 0;
        bool do_not_traverse_symlinks = (flags & _P) > 0;*/
        if (ino < INODES) {
            errors.push(ErrS(0, ino, ""));
            return (indices, paths, errors);
        }

        if (!recursive || ft != FT_DIR)
            return (indices, paths, errors);

        (uint16[] inodes, string[] names, uint8[] types) = _get_dir_contents(_fs.inodes[ino], true);

        for (uint16 j = 0; j < inodes.length; j++) {
            if (names[j] == "." || names[j] == "..")
                continue;
            (uint16[] sub_indices, string[] sub_paths, ErrS[] sub_errors) = _process_access_op(c, flags, val, inodes[j], types[j]);
            for (uint16 i: sub_indices)
                indices.push(i);
            for (string s: sub_paths)
                paths.push(s);
            for (ErrS e: sub_errors)
                errors.push(e);
        }
    }

    function _create_file_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, IOEventS[] ios, ErrS[] errors) {
        bool verbose = (flags & _v) > 0;
        bool md = c == mkdir;
        string[] paths;
        uint16[] indices;
        for (string s: args) {
            uint16 iop = _inode_in_dir(s, wd);
            if (iop < INODES) {
                paths.push(s);
                if (verbose && md)
                    out.append("mkdir: created directory" + _quote(s) + "\n");
            }
            else {
                if (md)
                    errors.push(ErrS(0, EEXIST, s));
                else {
                    paths.push(s);
                    indices.push(iop);
                }
            }
        }
        ios.push(IOEventS(md ? IO_MKDIR : indices.empty() ? IO_MKFILE : IO_UPDATE_TIME, wd, indices, paths));
    }

    function _remove_file_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, IOEventS[] ios, ErrS[] errors) {
        bool verbose = (flags & _v) > 0;
        string[] paths;
        uint16[] indices;
        for (string s: args) {
            (uint16 iop, uint8 ft) = _inode_and_type(s, wd);

            if (iop >= INODES) {
                if (c == rm && ft != FT_DIR) {
                    paths.push(s);
                    indices.push(iop);
                    out = _if(out, verbose, "removed" + _quote(s) + "\n");
                }
                if (c == rm && ft == FT_DIR)
                    errors.push(ErrS(0, EISDIR, s));
                if (c == rmdir && ft == FT_DIR) {
                    if (_fs.inodes[iop].file_size <= 10) {
                        paths.push(s);
                        indices.push(iop);
                        out = _if(out, verbose, "rmdir: removing directory," + _quote(s) + "\n");
                    } else
                        errors.push(ErrS(0, ENOTEMPTY, s));
                }
                if (c == rmdir && ft != FT_DIR)
                    errors.push(ErrS(0, ENOTDIR, s));
            } else
                errors.push(ErrS(0, ENOENT, s));
        }
        ios.push(IOEventS(IO_UNLINK, wd, indices, paths));
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
        (uint16 t_ino, uint8 t_ft) = _inode_and_type(target, wd);
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
                string[] paths;
                uint16[] indices;
                paths.push(t_path + "~");
                indices.push(t_ino);
                ios.push(IOEventS(IO_MKFILE, wd, indices, paths));
                out = _if(out, verbose, "(backup:" + _quote(t_path + "~") + ")");
            }
        }

        uint last = to_dir_flag ? nargs : nargs - 1;
        uint first = to_dir_flag ? 1 : 0;

        uint8 etype = 0;
        if (c == cp && !hardlink || c == mv && !to_dir)
            etype = IO_WR_COPY;
        if (c == ln && !symlink || c == cp && hardlink || c == mv && to_dir)
            etype = IO_HARDLINK;
        if (c == ln && symlink)
            etype = IO_SYMLINK;

        string[] paths;
        uint16[] indices;

        for (uint i = first; i < last; i++) {
            string s = args[i];
            (uint16 iop, uint8 s_ft) = _inode_and_type(s, wd);

            if (iop < INODES) {
                errors.push(ErrS(0, ENOENT, s));
                break;
            }

            if (verbose) {
                out = _if(out, c == mv, "renamed");
                out.append(_quote(s) + (c == ln ? "->" : "=>") + _quote(t_path));
            }

            if (s_ft == FT_DIR && !recurse)
                errors.push(ErrS(omitting_directory, 0, "-r not specified; omitting directory " + s));
            else if (to_file_flag && to_dir && s_ft == FT_REG_FILE)
                errors.push(ErrS(cant_overwrite_dir, 0, "cannot overwrite directory" + _quote(t_path) + "with non-directory"));
            else if (collision && newer_only) {
                if (_fs.inodes[t_ino].modified_at > _fs.inodes[iop].modified_at)
                    continue;
            } else {
                if (etype > 0) {
                    paths.push(_not_dir(to_dir ? s : t_path));
                    indices.push(iop);
                }
            }
        }
        ios.push(IOEventS(etype, to_dir ? t_ino : wd, indices, paths));
        if (c == mv && !to_dir)
            ios.push(IOEventS(IO_UNLINK, wd, indices, paths));
        if (overwrite_dest && errors.empty()) {
            indices.push(t_ino);
            paths.push(target);
            ios.push(IOEventS(IO_UNLINK, wd, indices, paths));
        }
    }

    /********************** File system read commands *************************/
    function _cmp(uint flags, string[] args, uint16 wd) private view returns (string out, string err) {
        bool verbose = (flags & _l) > 0;
        bool print_bytes = (flags & _b) > 0;

        uint16 i1 = _inode_in_dir(args[0], wd);
        uint16 i2 = _inode_in_dir(args[1], wd);
        string t1 = _fs.inodes[i1].text_data;
        string t2 = _fs.inodes[i2].text_data;
        bytes b1 = bytes(t1);
        bytes b2 = bytes(t2);
        for (uint16 i = 0; i < t1.byteLength(); i++) {
            uint8 u1 = uint8(b1[i]);
            uint8 u2 = uint8(b2[i]);
            if (u1 != u2) {
                if (!verbose) {
                    out = _fs.inodes[i1].file_name + " " + _fs.inodes[i2].file_name + " differ: byte" + _if(format(" {}", i), print_bytes, format(" is {}", u1)) + "\n";
                    return (out, err);
                }
                out.append(format("{:3} {:3} {:3}\n", i, u1, u2));
            }
        }
    }

    function _dd(string[] args, uint16 wd) private pure returns (IOEventS[] ios) {
        string[] paths;
        uint16[] indices;
        for (string s: args)
            paths.push(s);
        ios.push(IOEventS(IO_ALLOCATE, wd, indices, paths));
    }

    /******* Helpers ******************/

    function _init() internal override accept {
        _sync_fs_cache();
    }

}
