pragma ton-solidity >= 0.49.0;

import "SyncFS.sol";
import "Format.sol";

contract StatusReader is Format, SyncFS {

    /* Query file tree and file system status */
    function fstat(SessionS session, InputS input, ArgS[] arg_list) external view returns (string out, uint16 action, ErrS[] errors) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        uint16 pid = session.pid;
        pid = pid;
        if (c == cksum) out = _dump_fs(1, _fs); // 250

        /* File system status */
        if (_op_dev_stat(c))
            out = _dev_stat(c, flags, args);  // 2.3
        /* File tree status */
        if (_op_fs_status(c))
            (out, errors) = _fs_status(c, flags, arg_list);

        if (!errors.empty()) action |= PRINT_ERRORS;
    }

    function _fs_status(uint8 c, uint flags, ArgS[] arg_list) private view returns (string out, ErrS[] errors) {
        for (ArgS arg: arg_list) {
            (string s, , uint16 ino, , ) = arg.unpack();
            if (ino > 0 && _fs.inodes.exists(ino)) {
                if (c == du) out.append(_du(flags, arg));    // 800
                if (c == file) out.append(_file(flags, arg));// 500
                if (c == ls) out.append(_ls(flags, arg));    // 1.3
                if (c == namei) out.append(_namei(flags, arg));
                if (c == stat) out.append(_stat(flags, arg));// 800
                out.append("\n");
            } else
                errors.push(ErrS(0, ino, s));
        }
    }

    function _dev_stat(uint8 c, uint flags, string[] args) private view returns (string out) {
        if (c == df) out.append(_df(flags));      // 600
        if (c == findmnt) out.append(_findmnt(flags, args));// 500
        if (c == lsblk) out.append(_lsblk(flags, args));// 800
        if (c == ps) out.append(_ps(flags));
    }

    /********************** File system and device status query *************************/
    function _df(uint flags) private view returns (string out) {
        (, , , uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size,
        , , , ,, , ,) = _fs.sb.unpack();

        bool human_readable = (flags & _h) > 0;
        bool powers_of_1000 = (flags & _H) > 0;
        bool list_inodes = (flags & _i) > 0;
        bool block_1k = (flags & _k) > 0;
        bool posix_output = (flags & _P) > 0;

        string fs_name = "/dev/" + _dev[0].name;
        uint32 total = uint32(block_count + free_blocks);
        uint32 factor = 1;
        string[] header;
        string[] row0;

        if (list_inodes) {
            header = ["Filesystem", "Inodes", "IUsed", "IFree", "IUse%", "Mounted on"];
            row0 = [fs_name,
                    format("{}", inode_count + free_inodes),
                    format("{}", inode_count),
                    format("{}", free_inodes),
                    format("{}%", uint32(inode_count) * 100 / (inode_count + free_inodes)),
                    "/"];
        } else {
            if (human_readable) {
                header = ["Filesystem", "Size", "Used", "Avail", "Use%", "Mounted on"];
                factor = 1024;
            } else if (posix_output) {
                header = ["Filesystem", "1024-blocks", "Used", "Available", "Capacity%", "Mounted on"];
                factor = 1024;
            } else {
                header = ["Filesystem", "1K-blocks", "Used", "Available", "Use%", "Mounted on"];
                if (block_1k)
                    factor = 1;
            }
            if (powers_of_1000)
                factor = 1000;

            row0 = [fs_name,
                    format("{}", _scale(total * block_size / factor, factor)),
                    format("{}", _scale(uint32(block_count) * block_size / factor, factor)),
                    format("{}", _scale(uint32(free_blocks) * block_size / factor, factor)),
                    format("{}%", uint32(block_count) * 100 / total),
                    "/"];
        }
        out.append(_format_table([header, row0], " ", "\n", ALIGN_RIGHT));
    }

    function _findmnt(uint flags, string[] /*args*/) private view returns (string out) {
        bool search_fstab_only = (flags & _s) > 0;
        bool search_mtab_only = (flags & _m) > 0;
        bool like_df = (flags & _D) > 0;
        bool first_fs_only = (flags & _f) > 0;
        bool no_headings = (flags & _n) > 0;

        string[][] table;

        string[] header = no_headings ? [""] : like_df ? ["SOURCE", "SIZE", "USED", "AVAIL", "USE%", "TARGET"] : ["TARGET", "SOURCE", "FSTYPE", "OPTIONS"];
        if (!no_headings)
            table = [header];

        if (!search_mtab_only) {
            string[] lines = _get_file_contents("/etc/fstab");
            for (string line: lines) {
                string[] fields = _read_entry(line);
                table.push([fields[1], fields[0], fields[2], fields[3]]);
                if (first_fs_only)
                    break;
            }
        }
        if (!search_fstab_only) {
            string[] lines = _get_file_contents("/etc/mtab");
            for (string line: lines) {
                string[] fields = _read_entry(line);
                table.push([fields[1], fields[0], fields[2], fields[3]]);
                if (first_fs_only)
                    break;
            }
        }
        out.append(_format_table(table, " ", "\n", ALIGN_LEFT));
    }

    function _lsblk(uint flags, string[] args) private view returns (string out) {
        bool human_readable = (flags & _b) == 0;
        bool print_header = (flags & _n) == 0;
        bool all_columns = (flags & _O) > 0;
        bool fs_info = (flags & _f) > 0;
        bool full_path = (flags & _p) > 0;
        string[][] table;
        string[] header;

        if (print_header) {
            header = fs_info ? ["NAME", "FSTYPE", "LABEL", "UUID", "FSAVAIL", "FSUSE%", "MOUNTPOINT"] :
                ["NAME", "MAJ:MIN", "RM", "SIZE", "RO", "TYPE", "MOUNTPOINT"];
            table = [header];
        }
        if (args.empty())
            args = ["BlockDevice"];

        uint16 block_size = _fs.sb.block_size;
        uint16 block_count = _fs.sb.block_count;
        for (string s: args) {
            string[] lines = _get_file_contents("/dev/" + s);
            if (!lines.empty()) {
                string[] fields0 = _read_entry(lines[0]);
                string name = (full_path ? "/dev/" : "") + fields0[2];
                if (!all_columns) {
                    string[] l;
                    if (fs_info) {
                        l = [name,
                            " ",
                            " ",
                            " ",
                            _scale(block_count * block_size, human_readable ? 1024 : 1),
                            "0",
                            "disk",
                            ROOT];
                    } else {
                        l = [name,
                            fields0[0],
                            fields0[1],
                            "0",
                            _scale(block_count * block_size, human_readable ? 1024 : 1),
                            "0",
                            "disk",
                            ROOT];
                    }
                    table.push(l);
                }
            } else
                out.append(s + ": not a block device\n");
        }
        out.append(_format_table(table, " ", "\n", ALIGN_LEFT));
    }

    /* Does not really belong here */
    function _ps(uint flags) internal view returns (string out) {
        bool format_full = (flags & _f) > 0;
        bool format_extra_full = (flags & _F) > 0;
        string[][] table = [format_extra_full ? ["UID", "PID", "PPID", "CWD"] : format_full ? ["UID", "PID", "PPID"] : ["UID", "PID"]];
        for ((uint16 pid, ProcessInfo proc): _proc) {
            (uint16 owner_id, uint16 self_id, , , string cwd) = proc.unpack();
            string[] line = [format("{}", owner_id), format("{}", pid)];
            if (format_full || format_extra_full) line.push(format("{}", self_id));
            if (format_extra_full) line.push(cwd);
            table.push(line);
        }
        out.append(_format_table(table, " ", "\n", ALIGN_LEFT));
    }

    /* File tree status commands */
    function _du(uint flags, ArgS arg) private view returns (string out) {
        (string path, uint8 ft, uint16 ino, , ) = arg.unpack();
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
            out.append(_scale(counts[i], human_readable ? 1024 : 1) + "\t" + outs[i] + line_end);
    }

    function _file(uint flags, ArgS arg) private view returns (string out) {
        bool brief_mode = (flags & _b) > 0;
        bool dont_pad = (flags & _N) > 0;
        bool add_null = (flags & _0) > 0;
        bool follow_symlinks = (flags & _L) > 0;
        if ((flags & _v) > 0)
            return "version 2.0\n";

        (string name, uint8 ft, uint16 id, , ) = arg.unpack();
        INodeS inode = _fs.inodes[id];

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
        if (ft == FT_CHRDEV || ft == FT_BLKDEV) {
            (string major, string minor) = _get_device_version(inode.text_data);
            out.append(" (" + major + "/" + minor + ")");
        }
        if (ft == FT_SYMLINK && !follow_symlinks) {
            (string target, , ) = _symlink_target(inode);
            out.append(" to " + target);
        }
    }

    function _ls(uint f, ArgS arg) private view returns (string out) {
        (string s, uint8 ft, uint16 id, , ) = arg.unpack();

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

        // record separator: newline for long format or -1, comma for -m, tabulation otherwise (should be columns)
        string sp = long || (f & _1) > 0 ? "\n" : (f & _m) > 0 ? ", " : "\t";
        string[][] table;

        mapping (uint => uint16) ds;
        uint16[] inodes;
        string[] names;
        uint8[] types;
        if (ft == FT_REG_FILE || ft == FT_DIR && ((f & _d) > 0)) {
            inodes.push(id);
            names.push(s);
            types.push(ft);
            ds[_ls_sort_rating(f, id, _fs.inodes[id], use_ctime)] = 0;
        } else if (ft == FT_DIR) {
            (inodes, names, types) = _get_dir_contents(_fs.inodes[id], skip_dots);
            for (uint16 j = 0; j < inodes.length; j++)
                ds[_ls_sort_rating(f, inodes[j], _fs.inodes[inodes[j]], use_ctime)] = j;
        }
        optional (uint, uint16) p = ds.min();

        while (p.hasValue()) {
            (uint xk, uint16 j) = p.get();
            (uint16 i, string name, uint8 ftt) = (inodes[j], names[j], types[j]);
            string[] l;
            if (inode) l = [format("{}", i)];
            if (long) {
                (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 modified_at, uint32 last_modified, , ) = _fs.inodes[i].unpack();
                l.push(_permissions(mode));
                l.push(format("{}", n_links));
                if (!num) {
                    (, , string s_owner, string s_group, ) = _users[owner_id].unpack();
                    if (!no_owner) l.push(s_owner);
                    if (!no_group && !no_group_names) l.push(s_group);
                } else {
                    if (!no_owner) l.push(format("{}", owner_id));
                    if (!no_group) l.push(format("{}", group_id));
                }
                l.push(_scale(file_size, human_readable ? 1024 : 1));
                l.push(_ts(use_ctime ? modified_at : last_modified));
            }
            if (append_slash_to_dirs && ftt == FT_DIR) name.append("/");
            if (double_quotes) name = "\"" + name + "\"";
            l.push(name);
            table.push(l);
            p = ds.next(xk);
        }
        out = _if(out, !table.empty(), _format_table(table, " ", sp, ALIGN_RIGHT));
    }

    function _ls_sort_rating(uint f, uint16 id, INodeS inode, bool use_ctime) private pure returns (uint rating) {
       if ((f & _t) > 0)
            rating = use_ctime ? inode.modified_at : inode.last_modified;
        if ((f & _U + _f) > 0) rating = 0;
        if ((f & _S) > 0) rating = 0xFFFFFFFF - inode.file_size;
        rating = (rating << 32) + id;
        if ((f & _r) > 0)
            rating = 0xFFFFFFFFFFFFFFFF - rating;
    }

    function _namei(uint flags, ArgS arg) internal view returns (string out) {
        (string path, , , uint16 parent, ) = arg.unpack();
//        bool mountpoints = (flags & _x) > 0;
        bool modes = (flags & _m + _l) > 0;
        bool owners = (flags & _o + _l) > 0;
//        bool nosymlinks = (flags & _n) > 0;
//        bool vertical = (flags & _v + _l) > 0;

        string[] etc_passwd_contents;
        if (owners) {
            etc_passwd_contents = _get_file_contents("/etc/passwd");
        }

        out.append("f: " + path + "\n");
        string[] parts = _disassemble_path(path);
        uint len = parts.length;
        uint16 cur_dir = parent;
        for (uint i = len; i > 0; i--) {
            (uint16 ino, uint8 ft) = _fetch_dir_entry(parts[i - 1], cur_dir);
            (uint16 mode, uint16 owner_id, , , , , , , ) = _fs.inodes[ino].unpack();
            (, , string s_owner, string s_group, ) = _users[owner_id].unpack();
            out.append(" " + (modes ? _permissions(mode) : _file_type_sign(ft)) + " " + (owners ? s_owner + " "  + s_group + " " : "") + parts[i - 1] + "\n");
            cur_dir = ino;
        }
    }

    function _stat(uint flags, ArgS arg) private view returns (string out) {
        (string name, uint8 ft, uint16 id, , ) = arg.unpack();
        bool terse = (flags & _t) > 0;
        bool fs_info = (flags & _f) > 0;

        (uint8 device_type, uint16 device_n, , uint16 blk_size, ,) = _dev[0].unpack();
        INodeS inode = _fs.inodes[id];
        (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 modified_at, uint32 last_modified, , string[] text_data) = inode.unpack();
        uint16 device_id = (uint16(device_type) << 8) + device_n;
        ( , , string s_owner, string s_group, ) = _users[owner_id].unpack();
        (string major, string minor) = _is_char_dev(mode) || _is_block_dev(mode) ? _get_device_version(text_data) : ("0", "0");
        uint16 n_blocks = uint16(file_size / blk_size);

        if (fs_info) {
            SuperBlock sb = _fs.sb;
            (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size,, , , , ,, ,) = sb.unpack();

            out = terse ? format("{} {} {} {} {} {} {} {} {} {} {}\n", name, id, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes) :
                format("  File: \"{}\"\n    ID: {} Namelen: {}\tType: {}\nBlock size: {}\tFundamental block size: {}\nBlocks: Total: {}\tFree: {}\tAvailable: {}\nInodes: Total: {}\tFree: {}\n",
                    name, id, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes);
        } else {
            if (terse)
                out.append(format("{} {} {} {} {} {} {} {} {} {} {} {} {} {} {}\n",
                    name, file_size, n_blocks, mode, owner_id, group_id, device_id, id, n_links, major, minor, modified_at, last_modified, 0, blk_size));
            else {
                if (ft == FT_SYMLINK) {
                    (string tgt, , ) = _symlink_target(inode);
                    name.append(" -> " + tgt);
                }
                out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, n_blocks, blk_size));
                out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty file" : _file_type_description(mode));
                out.append(format("\nDevice: {}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, id, n_links));   // TODO: fix {}h
                if (_is_char_dev(mode) || _is_block_dev(mode))
                    out.append(format("\tDevice type: {},{}\n", major, minor));
                out.append(format("\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nModify: {}\nChange: {}\n Birth: -\n",
                    mode, _permissions(mode), owner_id, s_owner, group_id, s_group, _ts(modified_at), _ts(last_modified)));
            }
        }
    }

    /* File tree walk helpers (du) */
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
        if (ft == FT_REG_FILE) {
            counts.push(_fs.inodes[ino].file_size);
            outs.push(dir_name);
        }
        if (ft == FT_DIR)
            return _count_dir(flags, dir_name, ino);
    }

    /* File size display helpers */
    function _scale(uint32 n, uint32 factor) private pure returns (string) {
        if (n < factor || factor == 1)
            return format("{}", n);
        (uint d, uint m) = math.divmod(n, factor);
        return d > 10 ? format("{}K", d) : format("{}.{}K", d, m / 100);
    }

    /* Time display helpers */
    function _to_date(uint32 t) internal pure returns (string month, uint32 day, uint32 hour, uint32 minute, uint32 second) {
        uint32 Aug_1st = 1627776000; // Aug 1st
        uint32 Sep_1st = 1630454400; // Aug 1st
        bool past_Aug = t >= Sep_1st;
        if (t >= Aug_1st) {
            month = past_Aug ? "Sep" : "Aug";
            uint32 t0 = t - (past_Aug ? Sep_1st : Aug_1st);
            day = t0 / 86400 + 1;
            uint32 t1 = t0 % 86400;
            hour = t1 / 3600;
            uint32 t2 = t1 % 3600;
            minute = t2 / 60;
            second = t2 % 60;
        }
    }

    function _ts(uint32 t) internal pure returns (string) {
        (string month, uint32 day, uint32 hour, uint32 minute, uint32 second) = _to_date(t);
        return format("{} {} {:02}:{:02}:{:02}", month, day, hour, minute, second);
    }

    /* Init routine */
    function _init() internal override accept {
        _sync_fs_cache();
    }

}
