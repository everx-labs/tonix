pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "IOptions.sol";
import "SyncFS.sol";
import "Format.sol";

contract Stat is IOptions, Format, SyncFS {

    function fstat(SessionS ses, InputS input) external view returns (Std std, uint16 action) {

        (uint8 c, string[] args, uint flags) = input.unpack();

        string out;
        string err;
        if (c == cksum) out = _cksum(); // 250

        ErrS[] errors;

        if (_op_dev_stat(c))
            out.append(_dev_stat(c, flags, args, ses.wd));  // 2.3

        for (string s: args) {
            (uint16 ino, uint8 ft) = _inode_and_type(s, ses.wd);
            if (ino > 0 && _fs.inodes.exists(ino)) {
                if ((c == cat || c == paste || c == wc) && ft == FT_DIR) {
                    errors.push(ErrS(0, EISDIR, s));
                    continue;
                }
                INodeS inode = _fs.inodes[ino];
                if (c == cat) out.append(_cat(flags, inode));         // 550
                if (c == column) out.append(_column(flags, inode));
                if (c == du) out.append(_du(flags, s, ino, ft));    // 800
                if (c == file) out.append(_file(flags, s, inode, ft));// 500
//                if (c == grep) out.append(_grep(flags, s, ino, ft));
                if (c == paste) out.append(_paste(flags, inode));     // 120
                if (c == ls) out.append(_ls(flags, s, ino, ft));    // 1.3
                if (c == stat) out.append(_stat(flags, s, ino, ft));// 800
                if (c == wc) out.append(_wc(flags, inode));           // 600
                out.append("\n");
            } else
                errors.push(ErrS(0, ENOENT, s));
        }
        for (ErrS e: errors)
            err.append(_error_message(c, e)); // 700
        action = 0;
        std = Std(out, err);
    }

    function _dev_stat(uint8 c, uint flags, string[] args, uint16 /*wd*/) private view returns (string out) {
        if (c == df) out.append(_df(flags, args));      // 600
        if (c == lsblk) out.append(_lsblk(flags, args));// 800
        if (c == findmnt) out.append(_findmnt(flags, args));// 500

    }
    /********************** File system read commands *************************/
    function _column(uint flags, INodeS inode) private pure returns (string out) {
        bool ignore_empty_lines = (flags & _e) == 0;
        bool merge_delimiters = (flags & _n) == 0;
//        bool create_table = (flags & _t) > 0;
        bool columns_before_rows = (flags & _x) > 0;
        string delimiter = " ";
        string line_delimiter = "\n";

        uint8 pad_mode = ignore_empty_lines ? 1 : merge_delimiters ? 2 : columns_before_rows ? 3 : 0;

        string text = inode.text_data;
        string[] lines = _get_lines(text);

        uint[] max_widths = _max_row_widths(text);

        for (string line: lines) {
            string[] fields = _read_entry(line);
            for (uint j = 0; j < fields.length; j++)
                out.append(_pad(fields[j], max_widths[j], pad_mode) + delimiter);
            out.append(line_delimiter);
        }
    }

    /*function _grep(uint flags, string arg, uint16 ino, uint8 ft) private view returns (string out) {
        bool ignore_case = (flags & _i) > 0;
        bool invert_match = (flags & _v) > 0;
        bool match_words = (flags & _w) > 0;
        bool match_lines = (flags & _x) > 0;

        string[] lines = _get_lines(_fs.inodes[ino].text_data);
        for (uint16 i = 0; i < uint16(lines.length); i++) {
        }

    }*/

    function _cat(uint flags, INodeS inode) private pure returns (string out) {
        bool number_lines = (flags & _n) > 0;
        bool number_nonempty_lines = (flags & _b) > 0;
        bool dollar_at_line_end = (flags & _E + _e + _A) > 0;
        bool suppress_repeated_empty_lines = (flags & _s) > 0;
        bool convert_tabs = (flags & _T + _t + _A) > 0;
        bool show_nonprinting = (flags & _v + _e + _t + _A) > 0;

        bool repeated_empty_line = false;
        string[] lines = _get_lines(inode.text_data);
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

    function _paste(uint flags, INodeS inode) private pure returns (string out) {
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        string[] lines = _get_lines(inode.text_data);
        for (uint16 i = 0; i < uint16(lines.length); i++)
            out.append(lines[i] + line_delimiter);
    }

    function _cksum() private view returns (string out) {
        for ((uint16 i, INodeS ino): _fs.inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, , , , string file_name, string text_data) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} SZ {} NL {}\n", i, file_name, mode, owner_id, group_id, file_size, n_links));
            if ((mode & S_IFMT) == S_IFDIR)
                out.append(text_data);
        }
    }

    function _df(uint flags, string[] /*args*/) private view returns (string out) {
        SuperBlock sb = _fs.sb;
        (, , string file_system_OS_type, uint16 inode_count, uint16 block_count,
            uint16 free_inodes, uint16 free_blocks, uint16 block_size, , , , ,
            , , , uint16 inode_size) = sb.unpack();

//        bool all_file_systems = (flags & _a) > 0;
        bool human_readable = (flags & _h) > 0;
//        bool powers_of_1000 = (flags & _H) > 0;
        bool list_inodes = (flags & _i) > 0;
//        bool block_1k = (flags & _k) > 0;
//        bool local_file_systems = (flags & _l) > 0;
        bool posix_output = (flags & _P) > 0;

        string header_body;
        uint16 total = list_inodes ? inode_count + free_inodes : block_count + free_blocks;
        uint16 unit;
        if (list_inodes) {
            header_body = "Inodes\tIUsed\tIFree\tIUse%";
            unit = inode_size;
        } else if (human_readable) {
            header_body = "Size\tUsed\tAvail\tUse%";
            unit = block_size;
        } else if (posix_output) {
            header_body = "1024-blocks\tUsed\tAvailable\tCapacity%";
            unit = 1024;
        } else {
            header_body = "1K-blocks\tUsed\tAvailable\tUse%";
            unit = 1000;
        }
        uint32 size = uint32(total) * unit;
        uint16 used = list_inodes ? inode_count : block_count;
        uint16 free = list_inodes ? free_inodes : free_blocks;

        string header = "Filesystem\t" + header_body + "\tMounted on";
        string row0 = format("{}\t{}\t{}\t{}\t{}%\t/",
                    file_system_OS_type, _get_file_size(size, human_readable), used, free, used * 100 / total);
        string[] table;
        table.push(header);
        table.push(row0);
        out.append(_format_rows(table, " ", "\n", 1));
    }

    function _lsblk(uint flags, string[] args) private view returns (string out) {

        bool human_readable = (flags & _b) == 0;
        bool print_header = (flags & _n) == 0;
        bool all_columns = (flags & _O) > 0;
        bool fs_info = (flags & _f) > 0;
        bool full_path = (flags & _p) > 0;
        string[] table;
        string header;

        if (print_header) {
            header = fs_info ? "NAME\tFSTYPE\tLABEL\tUUID\tFSAVAIL\tFSUSE%\tMOUNTPOINT" : "NAME\tMAJ:MIN\tRM\tSIZE\tRO\tTYPE\tMOUNTPOINT";
            table.push(header);
        }
        if (args.empty())
            args.push("sda");

        uint16 block_size = _fs.sb.block_size;
        uint16 block_count = _fs.sb.block_count;
        for (string s: args) {
            string[] lines = _get_lines(_get_file_contents("/dev/" + s));
            if (!lines.empty()) {
                string[] fields0 = _read_entry(lines[0]);
                string name = (full_path ? "/dev/" : "") + fields0[2];
                if (!all_columns) {
                    string l;
                    if (fs_info) {
                        l = format("{}\t{}:{}\t{}\t{}\t{}\t{}\t{}", name, " ", " ", " ", _get_file_size(block_count * block_size, human_readable), 0, "disk", "/");
                    } else {
                        l = format("{}\t{}:{}\t{}\t{}\t{}\t{}\t{}", name, fields0[0], fields0[1], 0, _get_file_size(block_count * block_size, human_readable), 0, "disk", "/");
                    }
                    table.push(l);
                }
            }
            else
                out.append(s + ": not a block device\n");
        }
        out.append(_format_rows(table, " ", "\n", 2));
    }

    function _findmnt(uint flags, string[] /*args*/) private view returns (string out) {
        bool search_fstab_only = (flags & _s) > 0;
        bool search_mtab_only = (flags & _m) > 0;
//        bool search_kernel = (flags & _k) > 0;
//        bool print_all_fs = (flags & _A) > 0;
//        bool size_in_bytes = (flags & _b) > 0;
        bool like_df = (flags & _D) > 0;
        bool first_fs_only = (flags & _f) > 0;
        bool no_headings = (flags & _n) > 0;
//        bool no_truncate = (flags & _u) > 0;

        string[] table;

        string header = no_headings ? "" : like_df ? "SOURCE\tSIZE\tUSED\tAVAIL\tUSE%\tTARGET" : "TARGET\tSOURCE\tFSTYPE\tOPTIONS";
        if (!no_headings)
            table.push(header);

        if (!search_mtab_only) {
            string[] lines = _get_lines(_get_file_contents("/etc/fstab"));
            for (string line: lines) {
                string[] fields = _read_entry(line);
                string l = format("{}\t{}\t{}\t{}", fields[1], fields[0], fields[2], fields[3]);
                table.push(l);
                if (first_fs_only)
                    break;
            }
        }
        if (!search_fstab_only) {
            string[] lines = _get_lines(_get_file_contents("/etc/mtab"));
            for (string line: lines) {
                string[] fields = _read_entry(line);
                string l = format("{}\t{}\t{}\t{}", fields[1], fields[0], fields[2], fields[3]);
                table.push(l);
                if (first_fs_only)
                    break;
            }
        }
        out.append(_format_rows(table, " ", "\n", 2));
    }

    function _count_dir(uint flags, string dir_name, uint16 ino) private view returns (uint32[] counts, string[] outs) {
        uint32 cnt;
        bool count_files = (flags & _a) > 0;
        bool include_subdirs = (flags & _S) == 0;

        (uint16[] inodes, string[] names, uint8[] types) = _get_dir_contents(_fs.inodes[ino], true);
        for (uint j = 0; j < inodes.length; j++) {
            (uint32[] cnts, string[] nms) = _count_any(flags, dir_name + "/" + names[j], inodes[j], types[j]);
            for (uint i = 0; i < cnts.length; i++) {
                if (types[j] == FT_REG_FILE) {
                    if (count_files) {
                        counts.push(cnts[i]);
                        outs.push(nms[i]);
                    } else
                        cnt += cnts[i];
                }
                if (types[j] == FT_DIR) {
                    counts.push(cnts[i]);
                    outs.push(nms[i]);
                    if (include_subdirs)
                        cnt += cnts[i];
                }
            }
        }
        counts.push(_fs.inodes[ino].file_size + cnt);
        outs.push(dir_name);
    }

    function _count_any(uint flags, string dir_name, uint16 ino, uint8 ft) private view returns (uint32[] counts, string[] outs) {
        return ft == FT_REG_FILE ? _count_reg_file(dir_name, ino) : _count_dir(flags, dir_name, ino);
    }

    function _count_reg_file(string dir_name, uint16 ino) private view returns (uint32[] counts, string[] outs) {
        counts.push(_fs.inodes[ino].file_size);
        outs.push(dir_name);
    }

    function _get_file_size(uint32 file_size, bool human_readable) private pure returns (string) {
        return file_size == 0 ? "0" : human_readable ? _human_readable(file_size) : format("{:5}", file_size);
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
            out.append(_get_file_size(counts[i], human_readable) + "\t" + outs[i] + line_end);
    }

    function _stat(uint /*flags*/, string name, uint16 id, uint8 ft) private view returns (string out) {
        (uint8 device_type, uint16 device_n, , uint16 blk_size, ) = _dev[0].unpack();
        (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 accessed_at, uint32 modified_at, uint32 last_modified, , string text_data) = _fs.inodes[id].unpack();
        out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, file_size / blk_size, blk_size));
        out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty file" : _file_type_description(mode));
        uint16 device_id = (uint16(device_type) << 8) + device_n;
        out.append(format("\nDevice: {}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, id, n_links));   // TODO: fix {}h
        if (_is_char_dev(mode) || _is_block_dev(mode)) {
            (string major, string minor) = _get_device_version(text_data);
            out.append(format("\tDevice type: {},{}\n", major, minor));
        }
        out.append(format("\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nAccess: {}\nModify: {}\nChange: {}\n Birth: -\n",
            mode, _permissions(mode), owner_id, _get_user_name(owner_id), group_id, _get_group_name(group_id), _ts(accessed_at), _ts(modified_at), _ts(last_modified)));
    }

    function _file(uint flags, string name, INodeS inode, uint8 ft) private pure returns (string out) {
        if ((flags & _v) > 0)
            return "version 2.0\n";
        bool brief_mode = (flags & _b) > 0;
        bool dont_pad = (flags & _N) > 0;
        bool add_null = (flags & _0) > 0;

        uint16 mode = inode.mode;
        if (!brief_mode)
            out = _if(name, add_null, "\x00") + _if(": ", !dont_pad, "\t");
        if (ft == FT_REG_FILE) {
            uint32 fs = inode.file_size;
            out = _if(out, fs == 0, "empty");
            out = _if(out, fs == 1, "very short file (no magic)");
            out = _if(out, fs > 1, "ASCII text");
        } else
            out.append(_file_type_description(mode));
        if (_is_char_dev(mode) || _is_block_dev(mode)) {
            (string major, string minor) = _get_device_version(inode.text_data);
            out.append(" (" + major + "/" + minor + ")");
        }
    }

    function _human_readable(uint32 n) private pure returns (string) {
        if (n < 1024)
            return format("{}", n);
        (uint d, uint m) = math.divmod(n, 1024);
        return d > 10 ? format("{}K", d) : format("{}.{}K", d, m / 100);
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
            ds[_ls_sort_rating(f, id, _fs.inodes[id], use_ctime, use_atime)] = 0;
        } else if (ft == FT_DIR) {
            (inodes, names, types) = _get_dir_contents(_fs.inodes[id], skip_dots);
            for (uint16 j = 0; j < inodes.length; j++)
                ds[_ls_sort_rating(f, inodes[j], _fs.inodes[inodes[j]], use_ctime, use_atime)] = j;
        }
        optional (uint, uint16) p = ds.min();
        while (p.hasValue()) {
            (uint xk, uint16 j) = p.get();
            (uint16 i, string name, uint8 ftt) = (inodes[j], names[j], types[j]);
            out = _if(out, inode, format("{:3} ", i));
            if (long) {
                (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 accessed_at, uint32 modified_at, uint32 last_modified, , ) = _fs.inodes[i].unpack();
                out.append(format("{} {:2} ", _permissions(mode), n_links));
                out = _if(out, !no_owner, (num ? format("{:5}", owner_id) : format("{:5}", _get_user_name(owner_id))) + " ");
                out = _if(out, !no_group, num ? format("{:5}", group_id) : no_group_names ? "" : format("{:5}", _get_group_name(group_id)));
                out.append(" " + _get_file_size(file_size, human_readable) + " ");
                out.append(_ts(use_atime ? accessed_at : use_ctime ? modified_at : last_modified) + " ");
            }
            out = _if(out, double_quotes, "\"") + name;
            out = _if(out, double_quotes, "\"");
            out = _if(out, append_slash_to_dirs && ftt == FT_DIR, "/") + sp;
            p = ds.next(xk);
        }
    }

    function _ls_sort_rating(uint f, uint16 id, INodeS inode, bool use_ctime, bool use_atime) private pure returns (uint rating) {
       if ((f & _t) > 0)
            rating = use_atime ? inode.accessed_at : use_ctime ? inode.modified_at : inode.last_modified;
        if ((f & _U + _f) > 0) rating = 0;
        if ((f & _S) > 0) rating = 0xFFFFFFFF - inode.file_size;
        rating = (rating << 32) + id;
        if ((f & _r) > 0)
            rating = 0xFFFFFFFFFFFFFFFF - rating;
    }

    function _wc(uint flags, INodeS inode) private pure returns (string out) {
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
        (, , , uint32 bc, , , , , string file_name, string text) = inode.unpack();
        (uint16 lc, uint16 wc, uint32 cc, uint16 mw) = _line_and_word_count(text);

        out = _if("", print_lines, format("  {} ", lc));
        out = _if(out, print_words, format(" {} ", wc));
        out = _if(out, print_bytes, format(" {} ", bc));
        out = _if(out, print_chars, format(" {} ", cc));
        out = _if(out, print_max_width, format(" {} ", mw));
        out.append(file_name);
    }

    /******* Helpers ******************/
    function _permissions(uint16 p) internal pure returns (string) {
        return _inode_mode_sign(p) + _p_octet(p >> 6 & 0x0007) + _p_octet(p >> 3 & 0x0007) + _p_octet(p & 0x0007);
    }

    function _p_octet(uint16 p) internal pure returns (string out) {
        out = ((p & 4) > 0) ? "r" : "-";
        out.append(((p & 2) > 0) ? "w" : "-");
        out.append(((p & 1) > 0) ? "x" : "-");
    }

    function _to_date(uint32 t) internal pure returns (uint32 ds, uint32 hrs, uint32 mins, uint32 secs) {
        uint32 start_period = 1627776000; // Aug 1st
        if (t >= start_period) {
            uint32 t0 = t - start_period;
            ds = t0 / 86400 + 1;
            uint32 t1 = t0 % 86400;
            hrs = t1 / 3600;
            uint32 t2 = t1 % 3600;
            mins = t2 / 60;
            secs = t2 % 60;
        }
    }

    function _ts(uint32 t) internal pure returns (string) {
        (uint32 ds, uint32 hrs, uint32 mins, uint32 secs) = _to_date(t);
        return format("Aug {} {:02}:{:02}:{:02}", ds, hrs, mins, secs);
    }

    function _init() internal override accept {
        _sync_fs_cache();
    }

}
