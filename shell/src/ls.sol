pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract ls is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, string cwd) = arg.get_env(argv);
        if (params.empty())
            params.push(cwd);
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_ls(flags, Arg(s_arg, ft, index, parent, dir_index), inodes, data) + "\n");
            else {
                err.append("ls: failed to resolve relative path for " + s_arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _ls_sort_rating(string f, Inode inode, string name, uint16 dir_idx) private pure returns (uint rating) {
        (bool use_ctime, bool largest_first, bool unsorted, bool no_sort, bool newest_first, bool reverse_order, , ) = arg.flag_values("cSUftr", f);
        bool directory_order = unsorted || no_sort;
        uint rating_lo = directory_order ? dir_idx : str.alpha_rating(name, 8);
        uint rating_hi;

        if (newest_first)
            rating_hi = use_ctime ? inode.modified_at : inode.last_modified;
        else if (largest_first)
            rating_hi = 0xFFFFFFFF - inode.file_size;
        rating = (rating_hi << 64) + rating_lo;
        if (reverse_order)
            rating = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - rating;
    }

    function _ls_populate_line(string f, Inode ino, uint16 index, string name, uint8 file_type, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string[] l) {
        bool double_quotes = arg.flag_set("Q", f) && !arg.flag_set("N", f);
        bool append_slash_to_dirs = arg.flag_set("p", f) || arg.flag_set("F", f);
        bool use_ctime = arg.flag_set("c", f);

        (bool long_fmt, bool numeric, bool group_only, bool owner_only, bool print_allocated_size, bool print_index_node, bool no_group_names,
            bool human_readable) = arg.flag_values("lngosiGh", f);
        bool long_format = long_fmt || numeric || group_only || owner_only;

        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
        if (print_index_node)
            l = [str.toa(index)];
        if (print_allocated_size)
            l.push(str.toa(n_blocks));

        if (long_format) {
            l.push(inode.permissions(mode));
            l.push(str.toa(n_links));
            if (numeric) {
                if (!group_only)
                    l.push(str.toa(owner_id));
                if (!owner_only)
                    l.push(str.toa(group_id));
            } else {
                string s_owner = uadmin.user_name_by_id(owner_id, fs.get_file_contents_at_path("/etc/passwd", inodes, data));
                string s_group = uadmin.group_name_by_id(group_id, fs.get_file_contents_at_path("/etc/group", inodes, data));

                if (!group_only)
                    l.push(s_owner);
                if (!owner_only && !no_group_names)
                    l.push(s_group);
            }

            if (file_type == FT_CHRDEV || file_type == FT_BLKDEV) {
                (string major, string minor) = inode.get_device_version(device_id);
                l.push(format("{:4},{:4}", major, minor));
            } else
                l.push(fmt.scale(file_size, human_readable ? KILO : 1));

            l.push(fmt.ts(use_ctime ? modified_at : last_modified));
        }
        if (double_quotes)
            name = "\"" + name + "\"";
        if (append_slash_to_dirs && file_type == FT_DIR)
            name.append("/");
        l.push(name);
    }

    function _ls(string f, Arg ag, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
        (string s, uint8 ft, uint16 index, , ) = ag.unpack();
        Inode dir_inode = inodes[index];
        string[][] table;
        Arg[] sub_args;
        if (ft == FT_REG_FILE || ft == FT_DIR && arg.flag_set("d", f)) {
            if (!_ls_should_skip(f, s))
                table.push(_ls_populate_line(f, dir_inode, index, s, ft, inodes, data));
        } else if (ft == FT_DIR) {
            string ret;
            (ret, sub_args) = _list_dir(f, ag, dir_inode, inodes, data);
            out.append(ret);
        }

        for (Arg sub_arg: sub_args)
            out.append("\n" + sub_arg.path + ":\n" + _ls(f, sub_arg, inodes, data));
    }

    function _list_dir(string f, Arg ag, Inode inode, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Arg[] sub_args) {
        (string s, uint8 ft, uint16 index, , ) = ag.unpack();
        (bool recurse, bool long_fmt, bool numeric, bool group_only, bool owner_only, bool print_allocated_size,
            bool delim_newline, bool delim_comma) = arg.flag_values("Rlngos1m", f);
        bool long_format = long_fmt || numeric || group_only || owner_only;
        string sp = long_format || delim_newline ? "\n" : delim_comma ? ", " : "  ";
        string[][] table;

        mapping (uint => uint16) ds;
        bool count_totals = long_format || print_allocated_size;
        uint16 total_blocks;

        if (ft == FT_REG_FILE || ft == FT_DIR && arg.flag_set("d", f)) {
            if (!_ls_should_skip(f, s))
                table.push(_ls_populate_line(f, inode, index, s, ft, inodes, data));
        } else if (ft == FT_DIR) {
            (DirEntry[] contents, int16 status) = dirent.read_dir_data(data[index]);
            if (status < 0) {
                out.append(format("Error: {} \n", status));
                return (out, sub_args);
            }
            uint len = uint(status);

            for (uint16 j = 0; j < len; j++) {
                (uint8 sub_ft, string sub_name, uint16 sub_index) = contents[j].unpack();
                if (_ls_should_skip(f, sub_name) || sub_ft == FT_UNKNOWN)
                    continue;
                if (recurse && sub_ft == FT_DIR && j > 1)
                    sub_args.push(Arg(s + "/" + sub_name, sub_ft, sub_index, index, j));
                if (count_totals)
                    total_blocks += inodes[sub_index].n_blocks;
                ds[_ls_sort_rating(f, inodes[sub_index], sub_name, j)] = j;
            }

            optional(uint, uint16) p = ds.min();
            while (p.hasValue()) {
                (uint xk, uint16 j) = p.get();
                if (j >= len) {
                    out.append(format("Error: invalid entry {}\n", j));
                    continue;
                }
                (uint8 ftt, string name, uint16 i) = contents[j].unpack();

                table.push(_ls_populate_line(f, inodes[i], i, name, ftt, inodes, data));
                p = ds.next(xk);
            }
        }
        out = str.aif(out, count_totals, format("total {}\n", total_blocks));
        out.append(fmt.format_table(table, " ", sp, fmt.ALIGN_RIGHT));
    }

    /* Decides whether ls should skip this entry with the set of flags */
    function _ls_should_skip(string f, string name) private pure returns (bool) {
        bool print_dot_starters = arg.flag_set("a", f) || arg.flag_set("f", f);
        bool skip_dot_dots = arg.flag_set("A", f);
        bool ignore_blackups = arg.flag_set("B", f);

        uint len = name.byteLength();
        if (len == 0 || (skip_dot_dots && (name == "." || name == "..")))
            return true;
        if ((name.substr(0, 1) == "." && !print_dot_starters) ||
            (name.substr(len - 1, 1) == "~" && ignore_blackups))
            return true;
        return false;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"ls",
"[OPTION]... [FILE]...",
"list directory contents",
"List information about the FILE (the current directory by default).\n\
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.",
"-a      do not ignore entries starting with .\n\
-A      do not list implied . and ..\n\
-B      do not list implied entries ending with ~\n\
-c      with -lt: sort by, and show, ctime; with -l: show ctime and sort by name, otherwise: sort by ctime, newest first\n\
-C      list entries by columns\n\
-d      list directories themselves, not their contents\n\
-f      do not sort, enable -aU\n\
-F      append indicator (one of */=>@|) to entries\n\
-g      like -l, but do not list owner\n\
-G      in a long listing, don't print group names\n\
-h      with -l and -s, print sizes like 1K 234M 2G etc.\n\
-H      follow symbolic links listed on the command line\n\
-i      print the index number of each file\n\
-k      default to 1024-byte blocks for disk usage; used only with -s and per directory totals\n\
-L      for a symbolic link, show information for the file the link references rather than for the link itself\n\
-l      use a long listing format\n\
-m      fill width with a comma separated list of entries\n\
-n      like -l, but list numeric user and group IDs\n\
-N      print entry names without quoting\n\
-o      like -l, but do not list group information\n\
-p      append / indicator to directories\n\
-q      print ? instead of nongraphic characters\n\
-Q      enclose entry names in double quotes\n\
-r      reverse order while sorting\n\
-R      list subdirectories recursively\n\
-s      print the allocated size of each file, in blocks\n\
-S      sort by file size, largest first\n\
-t      sort by modification time, newest first\n\
-u      with -lt: sort by, and show, access time; with -l: show access time and sort by name; otherwise: sort by access time, newest first\n\
-U      do not sort; list entries in directory order\n\
-v      natural sort of (version) numbers within text\n\
-x      list entries by lines instead of by columns\n\
-X      sort alphabetically by entry extension\n\
-1      list one file per line. Avoid \'\\n\' with -q or -b",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}