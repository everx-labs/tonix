pragma ton-solidity >= 0.48.0;

import "IData.sol";
import "IOptions.sol";
import "FSCache.sol";
import "INode.sol";
contract Stat is IOptions, FSCache {

    function fstat(SessionS ses, InputS input) external view returns (Std std, INodeEventS[] ines, IOEventS[] ios, uint16 action) {
        (,, uint16 wd) = ses.unpack();
        (uint8 c, string[] args, uint flags, ) = input.unpack();
        string out;
        string err;

        /* Process related operations in separate subroutines */
        if (_op_stat(c))
            (out, err) = _stat_ops(c, args, flags, wd);

        std = Std(out, err);
        if (!err.empty()) action |= PRINT_ERROR;
        if (!out.empty()) action |= PRINT_OUT;
        if (!ios.empty()) action |= IO_EVENT;
        ines = ines;
    }

    /* File stat operations common routine */
    function _stat_ops(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, string err) {
        if (c == cksum)
            return (_cksum(), err);

        ErrS[] errors;
        for (string s: args) {
            (uint16 ino, uint8 ft) = _lookup_inode_and_type(s, wd);
            if (ino > 0 && _inodes.exists(ino)) {
                if ((c == cat || c == paste || c == wc) && ft == FT_DIR) {
                    errors.push(ErrS(1, _command_reason(c), EISDIR, s));
                    continue;
                }
                if (c == cat) out.append(_cat(flags, ino));
                if (c == df) out.append(_df(ino));
                if (c == du) out.append(_du(flags, s, ino, ft));
                if (c == file) out.append(_file(flags, s, ino, ft));
                if (c == paste) out.append(_paste(ino));
                if (c == ls) out.append(_ls(flags, s, ino, ft));
                if (c == stat) out.append(_stat(flags, s, ino));
                if (c == wc) out.append(_wc(flags, ino));
            } else
                errors.push(ErrS(1, _command_reason(c), ENOENT, s));
        }
        for (ErrS e: errors)
            err.append(_error_message2(c, e));
    }
    /********************** File system read commands *************************/
    // read contents(inode)

    function _cat(uint flags, uint16 ino) private view returns (string out) {
        bool number_lines = (flags & _n) > 0;
        bool number_nonempty_lines = (flags & _b) > 0;
        bool dollar_at_line_end = (flags & _E + _e + _A) > 0;
        bool suppress_repeated_empty_lines = (flags & _s) > 0;
        bool convert_tabs = (flags & _T + _t + _A) > 0;
        bool show_nonprinting = (flags & _v + _e + _t + _A) > 0;

        bool repeated_empty_line = false;
        string[] lines = _get_lines(_inodes[ino].text_data);
        for (uint16 i = 0; i < uint16(lines.length); i++) {
            string line = lines[i];
            uint16 len = uint16(line.byteLength());

            string prefix = (number_lines || (len > 0 && number_nonempty_lines)) ? format("   {}  ", i + 1) : "";
            string suffix = dollar_at_line_end ? "$" : "";
            string body;
            if (len == 0) {
                if (suppress_repeated_empty_lines) {
                    if (repeated_empty_line)
                        continue;
                    repeated_empty_line = true;
                }
            } else {
                if (suppress_repeated_empty_lines && repeated_empty_line)
                    repeated_empty_line = false;
                for (uint16 j = 0; j < len; j++) {
                    string s = line.substr(j, 1);
                    body.append((convert_tabs && s == "\t") ? "^I" : s);
                }
                body = _if(body, show_nonprinting && len > 1 && line.substr(len - 2, 1) == "\x13", "^M");
            }
            out.append(prefix + body + suffix + "\n");
        }
    }

    function _paste(uint16 inode) private view returns (string out) {
        return _inodes[inode].text_data;
    }

    function _cksum() private view returns (string out) {
        for ((uint16 i, INodeS ino): _inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, string file_name, string text_data) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} SZ {} NL {}\n", i, file_name, mode, owner_id, group_id, file_size, n_links));
            if (_mode_is_dir(mode))
                out.append("\n" + text_data);
        }
        out.append("\n");
    }

    function _df(uint16 inode) private view returns (string out) {
        out = format("DI {} Inodes: {}\n", inode, _ino_counter);
    }

    function _count_dir(uint flags, string dir_name, uint16 ino) private view returns (uint32[] counts, string[] outs) {
        uint32 cnt;
        bool count_files = (flags & _a) > 0;
        bool include_subdirs = (flags & _S) == 0;

        (uint16[] inodes, string[] names, uint8[] types) = _get_dir_contents(_inodes[ino], true);
        for (uint j = 0; j < inodes.length; j++) {
            (uint32[] cnts, string[] nms) = _count_any(flags, dir_name + "/" + names[j], inodes[j], types[j]);
            for (uint i = 0; i < cnts.length; i++) {
                if (include_subdirs || types[j] != FT_DIR)
                    cnt += cnts[i];
                counts.push(cnts[i]);
                outs.push(nms[i]);
            }
        }
    }

    function _count_any(uint flags, string dir_name, uint16 ino, uint8 ft) private view returns (uint32[] counts, string[] outs) {
        if (ft == FT_REG_FILE)
            return _count_reg_file(dir_name, ino);
        if (ft == FT_DIR)
            return _count_dir(flags, dir_name, ino);
    }

    function _count_reg_file(string dir_name, uint16 ino) private view returns (uint32[] counts, string[] outs) {
        counts.push(_inodes[ino].file_size);
        outs.push(dir_name);
    }

    function _du(uint flags, string path, uint16 ino, uint8 ft) private view returns (string out) {
        string line_end = (flags & _0) > 0 ? "\x00" : "\n";
        bool count_files = (flags & _a) > 0;
        bool human_readable = (flags & _h) > 0;
        bool produce_total = (flags & _c) > 0;
        bool summarize = (flags & _s) > 0;
        if (count_files && summarize)
            return "du: cannot both summarize and show all entries\n";

        (uint32[] counts, string[] outs) = _count_any(flags, path, ino, ft);

        if (produce_total) {
            counts.push(counts[counts.length - 1]);
            outs.push("total");
        }
        uint start = summarize ? counts.length - 1 : 0;
        for (uint i = start; i < counts.length; i++)
            out.append((human_readable ? _human_readable(counts[i]) : format("{}", counts[i])) + format("\t{}{}", outs[i], line_end));
    }

    function _stat(uint flags, string name, uint16 id) private view returns (string out) {
        bool dereference_links = (flags & _L) > 0;
        uint8 ft = _is_reg(id) ? FT_REG_FILE : FT_DIR; // also symlink
        if (dereference_links && (ft == FT_SYMLINK))
            id = _get_symlink_target(id);
        (uint32 accessed_at, uint32 modified_at, uint32 last_modified) = _ino_ts[id].unpack();
        (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, , ) = _inodes[id].unpack();
        User u = _users[_users.exists(owner_id) ? owner_id : REG_USER];
        UserGroup ug = _ugroups[_ugroups.exists(group_id) ? group_id : u.group_id];
        out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: 4096\t", name, file_size, file_size / 16384));
        out = _if(out, file_size == 0, "regular empty file");
        out = _if(out, file_size > 0, _ft(mode));
        out.append(format("\nDevice: 820h/2080d\tInode: {}\tLinks: {}\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nAccess: {}\nModify: {}\nChange: {}\n Birth: -\n", 
            id, n_links, mode, _permissions(mode), owner_id, u.name, group_id, ug.name, _ts(accessed_at), _ts(modified_at), _ts(last_modified)));
    }

    function _file(uint flags, string name, uint16 id, uint8 ft) private view returns (string out) {
        if ((flags & _v) > 0)
            return "version 2.0\n";
        bool brief_mode = (flags & _b) > 0;
        bool dont_pad = (flags & _N) > 0;
        bool add_null = (flags & _0) > 0;
        if (!_inodes.exists(id)) {
            if ((flags & _E) > 0)
                out = "ERROR: ";
            return out + "cannot stat" + _quote(name) + "(No such file or directory)\n";
        }
        uint32 fs = _inodes[id].file_size;
        if (!brief_mode)
            out = _if(name, add_null, "\x00") + _if(": ", !dont_pad, "\t");
        if (ft == FT_REG_FILE) {
            out = _if(out, fs == 0, "empty");
            out = _if(out, fs == 1, "very short file (no magic)");
            out = _if(out, fs > 1, "ASCII text");
        }
        out = _if(out, ft == FT_DIR, "directory");
        out = _if(out, ft == FT_SYMLINK, "symbolic link") + "\n";
    }

    function _human_readable(uint32 n) private pure returns (string s) {
        if (n < 1024)
            return format("{}", n);
        (uint d, uint m) = math.divmod(n, 1024);
        return (d > 10) ? format("{}K", d) : format("{}.{}K", d, m / 100);
    }
    function _ls(uint f, string s, uint16 id, uint8 ft) private view returns (string out) {

//        bool recurse = (f & _R) > 0;
//        if (recurse)
//            return _ls_r(f, s, id, ft);
        bool long = (f & _l + _n + _g + _o) > 0;    // any of -l, -n, -g, -o
        bool skip_dots = (f & _a) == 0;
        bool inode = (f & _i) > 0;
        bool no_owner = (f & _g) > 0;
        bool no_group = (f & _o) > 0;
        bool no_group_names = (f & _G) > 0;
        bool num = (f & _n) > 0;
        bool double_quotes = (f & _Q) > (f & _N); // -Q is set, -N is not
        bool append_slash_to_dirs = (f & _p + _F) > 0;
        bool human_readable = (f & _h) > 0;

        bool use_ctime = (f & _c) > 0;
        bool use_atime = (f & _u) > 0;

        // record separator: newline for long format or -1, comma for -m, tabulation otherwise (should be columns)
        string sp = long || (f & _1) > 0 ? "\n" : (f & _m) > 0 ? ", " : "\t";

        mapping (uint => uint16) ds;
        uint16[] inodes;
        string[] names;
        uint8[] types;
        if (ft == FT_REG_FILE || ft == FT_DIR && ((f & _d) > 0)) {
            inodes.push(id);
            names.push(s);
            types.push(ft);
            ds[_ls_sort_rating(f, id, use_ctime, use_atime)] = 0;
        } else if (ft == FT_DIR) {
            (inodes, names, types) = _get_dir_contents(_inodes[id], skip_dots);
            for (uint16 j = 0; j < inodes.length; j++)
                ds[_ls_sort_rating(f, inodes[j], use_ctime, use_atime)] = j;
        }
        optional (uint, uint16) p = ds.min();
        while (p.hasValue()) {
            (uint xk, uint16 j) = p.get();
            (uint16 i, string name, uint8 ftt) = (inodes[j], names[j], types[j]);
            out = _if(out, inode, format("{:3} ", i));
            if (long) {
                (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, , ) = _inodes[i].unpack();
                out.append(format("{} {:2} ", _permissions(mode), n_links));
                User u = _users[_users.exists(owner_id) ? owner_id : REG_USER];
                UserGroup ug = _ugroups[_ugroups.exists(group_id) ? group_id : u.group_id];
                out = _if(out, !no_owner, (num ? format("{:5}", owner_id) : format("{:5}", u.name)) + " ");
                out = _if(out, !no_group, num ? format("{:5}", group_id) : no_group_names ? "" : format("{:5}", ug.name));
                out.append(" " + (human_readable ? _human_readable(file_size) : format("{:5}", file_size)) + " ");
                out.append(_ts(use_atime ? _ino_ts[i].accessed_at : use_ctime ? _ino_ts[i].modified_at : _ino_ts[i].last_modified) + " ");
            }
            out = _if(out, double_quotes, "\"") + name;
            out = _if(out, double_quotes, "\"");
            out = _if(out, append_slash_to_dirs && ftt == FT_DIR, "/") + sp;
            p = ds.next(xk);
        }
        out.append("\n");
    }

    function _ls_sort_rating(uint f, uint16 id, bool use_ctime, bool use_atime) private view returns (uint rating) {
        (uint32 accessed_at, uint32 modified_at, uint32 last_modified) = _ino_ts[id].unpack();
        if ((f & _t) > 0)
            rating = use_atime ? accessed_at : use_ctime ? modified_at : last_modified;
        if ((f & _U + _f) > 0) rating = 0;
        if ((f & _S) > 0) rating = 0xFFFFFFFF - _inodes[id].file_size;
        rating = (rating << 32) + id;
        if ((f & _r) > 0)
            rating = 0xFFFFFFFFFFFFFFFF - rating;
    }

    function _wc(uint flags, uint16 ino) private view returns (string out) {
        INodeS inode = _inodes[ino];
        bool print_bytes = true;
        bool print_chars = false;
        bool print_lines = true;
        bool print_max_width = false;
        bool print_words = true;

        if (flags > 0) {
            print_bytes = (flags & _c) > 0;
            print_chars = (flags & _m) > 0;
            print_lines = (flags & _l) > 0;
            print_max_width = (flags & _L) > 0;
            print_words = (flags & _w) > 0;
        }
        (, , , uint32 bc, , string file_name, string text) = inode.unpack();
        (uint16 lc, uint16 wc, uint32 cc, uint16 mw) = _line_and_word_count(text);

        out = _if("", print_lines, format("  {} ", lc));
        out = _if(out, print_words, format(" {} ", wc));
        out = _if(out, print_bytes, format(" {} ", bc));
        out = _if(out, print_chars, format(" {} ", cc));
        out = _if(out, print_max_width, format(" {} ", mw));
        out.append(file_name + "\n");
    }

    /******* Helpers ******************/
    function _ft_sign(uint16 mode) internal pure returns (string) {
        if ((mode & S_IFMT) == S_IFREG) return "-";
        if ((mode & S_IFMT) == S_IFDIR) return "d";
        if ((mode & S_IFMT) == S_IFLNK) return "l";
    }

    function _ft(uint16 mode) internal pure returns (string) {
        if ((mode & S_IFMT) == S_IFREG) return "regular file";
        if ((mode & S_IFMT) == S_IFDIR) return "directory";
        if ((mode & S_IFMT) == S_IFLNK) return "symbolic link";
    }

    function _permissions(uint16 p) internal pure returns (string) {
        return _ft_sign(p) + _p_octet(p >> 6 & 0x0007) + _p_octet(p >> 3 & 0x0007) + _p_octet(p & 0x0007);
    }

    function _p_octet(uint16 p) internal pure returns (string out) {
        out = ((p & 4) > 0) ? "r" : "-";
        out.append(((p & 2) > 0) ? "w" : "-");
        out.append(((p & 1) > 0) ? "x" : "-");
    }

    function _to_date(uint32 t) internal pure returns (uint32 ds, uint32 hrs, uint32 mins, uint32 secs) {
        uint32 start_period = 1627776000; // Aug 1st
        if (t < start_period) return (0, 0, 0, 0);
        uint32 t0 = t - start_period;
        ds = t0 / 86400 + 1;
        uint32 t1 = t0 % 86400;
        hrs = t1 / 3600;
        uint32 t2 = t1 % 3600;
        mins = t2 / 60;
        secs = t2 % 60;
    }

    function _ts(uint32 t) internal pure returns (string) {
        (uint32 ds, uint32 hrs, uint32 mins, uint32 secs) = _to_date(t);
        return format("Aug {} {:02}:{:02}:{:02}", ds, hrs, mins, secs);
    }

    function init() external override accept {
        _init_commands();
        _init_errors();
        _sync_fs_cache();
    }

}
