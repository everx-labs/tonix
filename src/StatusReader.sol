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
            out = _dev_stat(c, flags, args);  // 3.5
        /* File tree status */
        if (_op_fs_status(c))
            (out, errors) = _fs_status(c, flags, arg_list); // 6.6

        if (!errors.empty())
            action |= PRINT_ERRORS;
    }

    function _fs_status(uint8 c, uint flags, ArgS[] arg_list) private view returns (string out, ErrS[] errors) {
        for (ArgS arg: arg_list) {
            (string s, , uint16 ino, , ) = arg.unpack();
            if (ino > 0 && _fs.inodes.exists(ino)) {
                if (c == du) out.append(_du(flags, arg));    // 900
                if (c == file) out.append(_file(flags, arg));// 500
                if (c == ls) out.append(_ls(flags, arg));    // 2.1
                if (c == namei) out.append(_namei(flags, arg)); // 500
                if (c == stat) out.append(_stat(flags, arg));// 1.8
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
        , , , , , , , ) = _fs.sb.unpack();

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
                string[] fields = _get_tsv(line);
                table.push([fields[1], fields[0], fields[2], fields[3]]);
                if (first_fs_only)
                    break;
            }
        }
        if (!search_fstab_only) {
            string[] lines = _get_file_contents("/etc/mtab");
            for (string line: lines) {
                string[] fields = _get_tsv(line);
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
        bool print_fs_info = (flags & _f) > 0;
        bool print_permissions = (flags & _m) > 0;
        bool print_device_info = !print_fs_info && !print_permissions;
        bool full_path = (flags & _p) > 0;
        string[][] table;

        (uint16 dev_dir, uint8 dev_dir_ft) = _fetch_dir_entry("dev", ROOT_DIR);
        if (dev_dir_ft != FT_DIR)
            return "Error: could not open /dev\n";

        if (print_header) {
            if (print_device_info)
                table = [["NAME", "MAJ:MIN", "SIZE", "RO", "TYPE", "MOUNTPOINT"]];
            else if (print_fs_info)
                table = [["NAME", "FSTYPE", "LABEL", "UUID", "FSAVAIL", "FSUSE%", "MOUNTPOINT"]];
            else if (print_permissions)
                table = [["NAME", "SIZE", "OWNER", "GROUP", "MODE"]];
        }
        if (args.empty())
            args = ["BlockDevice"];

        (, , , , uint16 block_count, , uint16 free_blocks, uint16 block_size,
        , , , , , , , ) = _fs.sb.unpack();

        for (string s: args) {
            (uint16 dev_file_index, uint8 dev_file_ft) = _fetch_dir_entry(s, dev_dir);
            if (dev_file_ft == FT_BLKDEV || dev_file_ft == FT_CHRDEV) {
                (uint16 mode, uint16 owner_id, , , , , , , string[] lines) = _fs.inodes[dev_file_index].unpack();
                string[] fields0 = _get_tsv(lines[0]);
                if (fields0.length < 4) {
                    out.append("error reading data from " + s + "\n" + lines[0]);
                    continue;
                }
                string name = (full_path ? "/dev/" : "") + fields0[2];
                string[] l;
                if (print_device_info)
                    l = [name,
                         format("{}:{}", fields0[0], fields0[1]),
                         _scale(uint32(block_count) * block_size, human_readable ? 1024 : 1),
                         "0",
                         "disk",
                         ROOT];
                else if (print_fs_info)
                    l = [name,
                        " ",
                        " ",
                        " ",
                        _scale(uint32(free_blocks) * block_size, human_readable ? 1024 : 1),
                        format("{}%", uint32(block_count) * 100 / (block_count + free_blocks)),
                        ROOT];
                else if (print_permissions) {
                    (, , string s_owner, string s_group, ) = _users[owner_id].unpack();
                    l = [name,
                        _scale(uint32(block_count) * block_size, human_readable ? 1024 : 1),
                        s_owner,
                        s_group,
                        _permissions(mode)];
                }
                table.push(l);
            } else
                out.append(s + ": not a block device\n");
        }
        out.append(_format_table(table, " ", "\n", ALIGN_CENTER));
    }

    /* Does not really belong here */
    function _ps(uint flags) internal view returns (string out) {
        bool format_full = (flags & _f) > 0;
        bool format_extra_full = (flags & _F) > 0;
        string[][] table = [format_extra_full ? ["UID", "PID", "PPID", "CWD"] : format_full ? ["UID", "PID", "PPID"] : ["UID", "PID"]];
        for ((uint16 pid, ProcessInfo proc): _proc) {
            (uint16 owner_id, uint16 self_id, , , string cwd) = proc.unpack();
            string[] line = [format("{}", owner_id), format("{}", pid)];
            if (format_full || format_extra_full)
                line.push(format("{}", self_id));
            if (format_extra_full)
                line.push(cwd);
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
        uint32 file_size = _fs.inodes[ino].file_size;

        (string[][] table, uint32 total) = ft == FT_DIR ? _count_dir(flags, path, ino) :
            ([[_scale(file_size, human_readable ? 1024 : 1), path]], file_size);

        if (produce_total)
            table.push([format("{}", total), "total"]);

        out = _format_table(table, "\t", line_end, ALIGN_LEFT);
    }

    function _file(uint flags, ArgS arg) private view returns (string out) {
        bool brief_mode = (flags & _b) > 0;
        bool dont_pad = (flags & _N) > 0;
        bool add_null = (flags & _0) > 0;
        bool follow_symlinks = (flags & _L) > 0;
        if ((flags & _v) > 0)
            return "version 2.0\n";

        (string name, uint8 ft, uint16 id, , ) = arg.unpack();
        (uint16 mode, , , uint32 file_size, , , , , string[] text_data) = _fs.inodes[id].unpack();

        if (!brief_mode)
            out = _if(name, add_null, "\x00") + _if(": ", !dont_pad, "\t");
        if (ft == FT_REG_FILE) {
            out = _if(out, file_size == 0, "empty");
            out = _if(out, file_size == 1, "very short file (no magic)");
            out = _if(out, file_size > 1, "ASCII text");
        } else
            out.append(_file_type_description(mode));
        if (ft == FT_CHRDEV || ft == FT_BLKDEV) {
            (string major, string minor) = _get_device_version(text_data);
            out.append(" (" + major + "/" + minor + ")");
        }
        if (ft == FT_SYMLINK && !follow_symlinks) {
            (string target, , ) = _read_dir_entry(text_data[0]);
            out.append(" to " + target);
        }
    }

    function _ls(uint f, ArgS arg) private view returns (string out) {
        (string s, uint8 ft, uint16 id, , ) = arg.unpack();

        bool recurse = (f & _R) > 0;
        bool long_format = (f & _l + _n + _g + _o) > 0;    // any of -l, -n, -g, -o
        bool print_allocated_size = (f & _s) > 0;

        // record separator: newline for long format or -1, comma for -m, tabulation otherwise (should be columns)
        string sp = long_format || (f & _1) > 0 ? "\n" : (f & _m) > 0 ? ", " : "  ";
        string[][] table;
        ArgS[] sub_args;

        mapping (uint => uint16) ds;
        uint16 block_size = _fs.sb.block_size;
        bool count_totals = long_format || print_allocated_size;
        uint16 total_blocks;

        INodeS inode = _fs.inodes[id];
        if (ft == FT_REG_FILE || ft == FT_DIR && ((f & _d) > 0)) {
            if (!_ls_should_skip(f, s))
                table.push(_ls_populate_line(f, id, s, ft, block_size));
        } else if (ft == FT_DIR) {
            string[] text_data = inode.text_data;
            uint len = text_data.length;

            for (uint16 j = 1; j <= len; j++) {
                (string sub_name, uint16 sub_index, uint8 sub_ft) = _read_dir_entry(text_data[j - 1]);
                if (_ls_should_skip(f, sub_name) || sub_ft == FT_UNKNOWN)
                    continue;
                if (recurse && sub_ft == FT_DIR && j > 2) {
                    sub_name = s + "/" + sub_name;
                    ArgS sub_arg = ArgS(sub_name, sub_ft, sub_index, id, j);
                    sub_args.push(sub_arg);
                }
                if (count_totals)
                    total_blocks += uint16(_fs.inodes[sub_index].file_size / block_size) + 1;
                ds[_ls_sort_rating(f, sub_name, sub_index, j)] = j;
            }

            optional(uint, uint16) p = ds.min();
            while (p.hasValue()) {
                (uint xk, uint16 j) = p.get();
                if (j == 0 || j > len) {
                    out.append(format("Error: invalid entry {}\n", j));
                    continue;
                }
                (string name, uint16 i, uint8 ftt) = _read_dir_entry(text_data[j - 1]);
                table.push(_ls_populate_line(f, i, name, ftt, block_size));
                p = ds.next(xk);
            }
        }
        out = _if(out, count_totals, format("total {}\n", total_blocks));
        if (!table.empty())
            out.append(_format_table(table, " ", sp, ALIGN_RIGHT));

        for (ArgS sub_arg: sub_args)
            out.append("\n" + sub_arg.path + ":\n" + _ls(f, sub_arg));
    }

    function _alpha_rating(string s, uint len) internal pure returns (uint rating) {
        bytes bts = bytes(s);
        uint lim = math.min(len, bts.length);
        for (uint i = 0; i < lim; i++)
            rating += uint(uint8(bts[i])) << ((len - i - 1) * 8);
    }

    function _ls_sort_rating(uint f, string name, uint16 id, uint16 dir_index) private view returns (uint rating) {
        bool use_ctime = (f & _c) > 0;
        bool largest_first = (f & _S) > 0;
        bool directory_order = (f & _U + _f) > 0;
        bool newest_first = (f & _t) > 0;
        bool reverse_order = (f & _r) > 0;
        uint rating_lo = directory_order ? dir_index : _alpha_rating(name, 8);
        uint rating_hi;

        INodeS inode = _fs.inodes[id];
        if (newest_first)
            rating_hi = use_ctime ? inode.modified_at : inode.last_modified;
        else if (largest_first)
            rating_hi = 0xFFFFFFFF - inode.file_size;
        rating = (rating_hi << 64) + rating_lo;
        if (reverse_order)
            rating = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - rating;
    }

    function _ls_should_skip(uint f, string name) private pure returns (bool) {
        bool print_dot_starters = (f & _a + _f) > 0;
        bool skip_dot_dots = (f & _A) > 0;
        bool ignore_blackups = (f & _B) > 0;

        uint len = name.byteLength();
        if (len == 0 || (skip_dot_dots && (name == "." || name == "..")))
            return true;
        if ((name.substr(0, 1) == "." && !print_dot_starters) ||
            (name.substr(len - 1, 1) == "~" && ignore_blackups))
            return true;
        return false;
    }

    function _ls_populate_line(uint f, uint16 index, string name, uint8 file_type, uint16 block_size) private view returns (string[] l) {
        bool long_format = (f & _l + _n + _g + _o) > 0;    // any of -l, -n, -g, -o
        bool print_index_node = (f & _i) > 0;
        bool no_owner = (f & _g) > 0;
        bool no_group = (f & _o) > 0;
        bool no_group_names = (f & _G) > 0;
        bool numeric = (f & _n) > 0;
        bool human_readable = (f & _h) > 0;
        bool print_allocated_size = (f & _s) > 0;
        bool double_quotes = (f & _Q) > 0 && (f & _N) == 0; // -Q is set, -N is not
        bool append_slash_to_dirs = (f & _p + _F) > 0;
        bool use_ctime = (f & _c) > 0;

        (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 modified_at, uint32 last_modified, , ) = _fs.inodes[index].unpack();
        if (print_index_node)
            l = [format("{}", index)];
        if (print_allocated_size)
            l.push(format("{}", uint16(file_size / block_size) + 1));
        if (long_format) {
            l.push(_permissions(mode));
            l.push(format("{}", n_links));
            if (numeric) {
                if (!no_owner)
                    l.push(format("{}", owner_id));
                if (!no_group)
                    l.push(format("{}", group_id));
            } else {
                (, , string s_owner, string s_group, ) = _users[owner_id].unpack();
                if (!no_owner)
                    l.push(s_owner);
                if (!no_group && !no_group_names)
                    l.push(s_group);
            }
            l.push(_scale(file_size, human_readable ? 1024 : 1));
            l.push(_ts(use_ctime ? modified_at : last_modified));
        }
        if (double_quotes)
            name = "\"" + name + "\"";
        if (append_slash_to_dirs && file_type == FT_DIR)
            name.append("/");
        l.push(name);
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
        (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 modified_at, uint32 last_modified, , string[] text_data) = _fs.inodes[id].unpack();
        uint16 device_id = (uint16(device_type) << 8) + device_n;
        ( , , string s_owner, string s_group, ) = _users[owner_id].unpack();
        (string major, string minor) = ft == FT_BLKDEV || ft == FT_CHRDEV  ? _get_device_version(text_data) : ("0", "0");
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
                    (string tgt, , ) = _read_dir_entry(text_data[0]);
                    name.append(" -> " + tgt);
                }
                out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, n_blocks, blk_size));
                out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty file" : _file_type_description(mode));
                out.append(format("\nDevice: {}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, id, n_links));   // TODO: fix {}h
                if (ft == FT_BLKDEV || ft == FT_CHRDEV)
                    out.append(format("\tDevice type: {},{}\n", major, minor));
                out.append(format("\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nModify: {}\nChange: {}\n Birth: -\n",
                    mode & 0x01FF, _permissions(mode), owner_id, s_owner, group_id, s_group, _ts(modified_at), _ts(last_modified)));
            }
        }
    }

    /* File tree walk helpers (du) */
    function _count_dir(uint flags, string dir_name, uint16 ino) private view returns (string[][] lines, uint32 total) {
        bool count_files = (flags & _a) > 0;
        bool include_subdirs = (flags & _S) == 0;
        bool human_readable = (flags & _h) > 0;

        INodeS inode = _fs.inodes[ino];
        string[] text_data = inode.text_data;
        uint len = text_data.length;

        for (uint16 j = 3; j <= len; j++) {
            (string sub_name, uint16 sub_index, uint8 sub_ft) = _read_dir_entry(text_data[j - 1]);
            sub_name = dir_name + "/" + sub_name;
            if (sub_ft == FT_DIR) {
                (string[][] sub_lines, uint32 sub_total) = _count_dir(flags, sub_name, sub_index);
                for (string[] sub_line: sub_lines)
                    lines.push(sub_line);
                if (include_subdirs)
                    total += sub_total;
            }
            else {
                uint32 file_size = _fs.inodes[sub_index].file_size;
                total += file_size;
                if (count_files)
                    lines.push([_scale(file_size, human_readable ? 1024 : 1), sub_name]);
            }
        }
        total += inode.file_size;
        lines.push([_scale(total, human_readable ? 1024 : 1), dir_name]);
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
