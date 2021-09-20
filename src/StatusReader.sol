pragma ton-solidity >= 0.49.0;

import "SyncFS.sol";
import "Format.sol";
import "CacheFS.sol";

contract StatusReader is Format, SyncFS, CacheFS {

    /* Query file tree and file system status */
    function fstat(SessionS session, InputS input, ArgS[] arg_list) external view returns (string out, uint16 action, ErrS[] errors) {
        (uint8 c, , uint flags) = input.unpack();
        uint16 pid = session.pid;
        pid = pid;
        if (c == cksum) out = _dump_fs(1, _fs); // 250

        /* File tree status */
        for (ArgS arg: arg_list) {
            if (c == du) out.append(_du(flags, arg));    // 900
            if (c == file) out.append(_file(flags, arg));// 500
            if (c == ls) out.append(_ls(flags, arg));    // 2.1
            if (c == namei) out.append(_namei(flags, arg)); // 500
            if (c == stat) out.append(_stat(flags, arg));// 1.8
            out.append("\n");
        }

        if (!errors.empty())
            action |= PRINT_ERRORS;
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

        (string name, uint8 ft, uint16 index, , ) = arg.unpack();
        (uint16 mode, , , uint32 file_size, , , , , string[] text_data) = _fs.inodes[index].unpack();

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
        (string s, uint8 ft, uint16 index, , ) = arg.unpack();

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

        INodeS inode = _fs.inodes[index];
        if (ft == FT_REG_FILE || ft == FT_DIR && ((f & _d) > 0)) {
            if (!_ls_should_skip(f, s))
                table.push(_ls_populate_line(f, index, s, ft, block_size));
        } else if (ft == FT_DIR) {
            string[] text_data = inode.text_data;
            uint len = text_data.length;

            for (uint16 j = 1; j <= len; j++) {
                (string sub_name, uint16 sub_index, uint8 sub_ft) = _read_dir_entry(text_data[j - 1]);
                if (_ls_should_skip(f, sub_name) || sub_ft == FT_UNKNOWN)
                    continue;
                if (recurse && sub_ft == FT_DIR && j > 2) {
                    sub_name = s + "/" + sub_name;
                    ArgS sub_arg = ArgS(sub_name, sub_ft, sub_index, index, j);
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

    function _ls_sort_rating(uint f, string name, uint16 index, uint16 dir_index) private view returns (uint rating) {
        bool use_ctime = (f & _c) > 0;
        bool largest_first = (f & _S) > 0;
        bool directory_order = (f & _U + _f) > 0;
        bool newest_first = (f & _t) > 0;
        bool reverse_order = (f & _r) > 0;
        uint rating_lo = directory_order ? dir_index : _alpha_rating(name, 8);
        uint rating_hi;

        INodeS inode = _fs.inodes[index];
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
        (string name, uint8 ft, uint16 index, , ) = arg.unpack();
        bool terse = (flags & _t) > 0;
        bool fs_info = (flags & _f) > 0;

        (uint8 device_type, uint16 device_n, , uint16 blk_size, ,) = _source_device.unpack();
        (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, uint32 modified_at, uint32 last_modified, , string[] text_data) = _fs.inodes[index].unpack();
        uint16 device_id = (uint16(device_type) << 8) + device_n;
        ( , , string s_owner, string s_group, ) = _users[owner_id].unpack();
        (string major, string minor) = ft == FT_BLKDEV || ft == FT_CHRDEV  ? _get_device_version(text_data) : ("0", "0");
        uint16 n_blocks = uint16(file_size / blk_size);

        if (fs_info) {
            SuperBlock sb = _fs.sb;
            (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size,, , , , ,, ,) = sb.unpack();

            out = terse ? format("{} {} {} {} {} {} {} {} {} {} {}\n", name, index, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes) :
                format("  File: \"{}\"\n    ID: {} Namelen: {}\tType: {}\nBlock size: {}\tFundamental block size: {}\nBlocks: Total: {}\tFree: {}\tAvailable: {}\nInodes: Total: {}\tFree: {}\n",
                    name, index, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes);
        } else {
            if (terse)
                out.append(format("{} {} {} {} {} {} {} {} {} {} {} {} {} {} {}\n",
                    name, file_size, n_blocks, mode, owner_id, group_id, device_id, index, n_links, major, minor, modified_at, last_modified, 0, blk_size));
            else {
                if (ft == FT_SYMLINK) {
                    (string tgt, , ) = _read_dir_entry(text_data[0]);
                    name.append(" -> " + tgt);
                }
                out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, n_blocks, blk_size));
                out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty file" : _file_type_description(mode));
                out.append(format("\nDevice: {}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, index, n_links));   // TODO: fix {}h
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

    /* Init routine */
    function _init() internal override accept {
        _sync_fs_cache();
    }

}
