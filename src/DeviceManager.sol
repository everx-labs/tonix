pragma ton-solidity >= 0.49.0;

import "Format.sol";
import "Commands.sol";
import "SyncFS.sol";
import "ExportFS.sol";
import "CacheFS.sol";

//contract DeviceManager is Format, Commands, INode {
contract DeviceManager is Format, SyncFS, ExportFS, CacheFS {

//    FileSystem _dev_fs;
    uint8 _devc;
    Mount[] _mnt;
    DeviceInfo[] public _dev;

    function _add_device_files(uint16 parent, string[] names, address[] addresses) internal {
        uint16 counter = _export_fs.ic;
        uint16 len = uint16(names.length);
        for (uint8 i = 0; i < len; i++) {
            string name = names[i];
            DeviceInfo dev = DeviceInfo(FT_CHRDEV, _devc++, name, 0, 0, addresses[i]);
            _dev.push(dev);
            uint8 ft = dev.major_id;
            INodeS inode = ft == FT_BLKDEV ? _get_block_device_node(dev) : _get_character_device_node(dev);
            _export_fs.inodes[counter] = inode;
            _append_dir_entry(parent, counter + i, name, ft);
        }
        _export_fs.ic += len;
    }

    /* Init routine */
    function _init() internal override accept {
        _export_fs = _get_fs(1, "dev_fs", ["block", "char"]);
        _create_device(ROOT_DIR, DeviceInfo(BLK_DEVICE, _dc++, "DeviceManager", 1024, 100, address(this)));

        _add_device_files(ROOT_DIR + 1, ["BlockDevice"], [address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5)]);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 3, 1, "block"));

        this.init2();
    }

    function init2() external accept {
        address[5] readers = [
            address.makeAddrStd(0, 0x47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40),
            address.makeAddrStd(0, 0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9),
            address.makeAddrStd(0, 0x48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec),
            address.makeAddrStd(0, 0x4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d),
            address.makeAddrStd(0, 0x430dd570de5398dbc2319979f5ba4aa99d5254e5382d3c344b985733d141617b)];

        _add_device_files(ROOT_DIR + 3 + 1, ["FileManager", "StatusReader", "PrintFormatted", "SessionManager", "DeviceManager"], readers);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 4, 5, "char"));

        _sync_fs_cache();
    }
    /* Query devices and file systems status */
    function dev_stat(SessionS session, InputS input, ArgS[] arg_list) external view returns (string out, uint16 action, ErrS[] errors) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        uint16 pid = session.pid;
        if (!arg_list.empty())
            pid = pid;
        /* File system status */
        if (_op_dev_stat(c))
            out = _dev_stat(c, flags, args);  // 3.5

        if (!errors.empty())
            action |= PRINT_ERRORS;
    }

    /* Query devices and file systems status */
    function dev_admin(SessionS session, InputS input, ArgS[] arg_list) external view returns (string out, uint16 action, ErrS[] errors) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        uint16 pid = session.pid;
        if (!arg_list.empty())
            pid = pid;
        /* File system status */
        if (_op_dev_admin(c))
            out = _dev_admin(c, flags, args);  // 3.5

        if (!errors.empty())
            action |= PRINT_ERRORS;
    }

    function _dev_stat(uint8 c, uint flags, string[] args) private view returns (string out) {
        if (c == df) out.append(_df(flags));      // 600
        if (c == findmnt) out.append(_findmnt(flags, args));// 500
        if (c == lsblk) out.append(_lsblk(flags, args));// 800
        if (c == ps) out.append(_ps(flags));
    }

    function _dev_admin(uint8 c, uint flags, string[] args) private view returns (string out) {
        if (c == losetup) out.append(_losetup(flags, args));      // 600
        if (c == mknod) out.append(_mknod(flags, args));// 500
        if (c == mount) out.append(_mount(flags, args));// 800
        if (c == udevadm) out.append(_udevadm(flags, args));
        if (c == umount) out.append(_umount(flags, args));// 800
    }

    function _umount(uint flags, string[] args) private view returns (string out) {
    }

    function _losetup(uint flags, string[] args) private view returns (string out) {
    }

    function _mount(uint flags, string[] args) private view returns (string out) {
        string[] names;
        address[] addresses;
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
                for (string s: _get_file_contents("/etc/fstab")) {
                    string[] fields = _get_tsv(s);
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

    function account_info(InputS input) external view returns (string[] host_names, address[] addresses) {
        (, string[] args, uint flags) = input.unpack();
        string[] text = _get_file_contents("/etc/hosts");
        if (!args.empty())
            for (string s: args) {
                if ((flags & _d) == 0) {
                    host_names.push(s);
                    addresses.push(_to_address(_lookup_pair_value(s, text)));
                }
            }
        else {
            for (string s: text) {
                string[] fields = _get_tsv(s);
                host_names.push(fields[1]);
                addresses.push(_to_address(fields[0]));
            }
        }
    }

    function _ping(uint flags, string[] args) private view returns (string[] names, address[] addresses) {
        string[] text = _get_file_contents("/etc/hosts");
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
            for (string s: text) {
                string[] fields = _get_tsv(s);
                names.push(fields[1]);
                addresses.push(_to_address(fields[0]));
            }
        }
    }


    /* udev management tool
       [--version] [--help]
       info [options] [devpath]
       trigger [options] [devpath]
       settle [options]
       control option
       monitor [options]
       test [options] devpath
       test-builtin [options] command devpath
       udevadm expects a command and command specific options. It controls the runtime behavior of systemd-udevd, requests kernel events,
       manages the event queue, and provides simple debugging mechanisms.*/
    function _udevadm(uint flags, string[] args) private view returns (string out) {
    }

    /*make block or character special files
    [OPTION]... NAME TYPE [MAJOR MINOR]
    Create the special file NAME of the given TYPE.*/
    function _mknod(uint flags, string[] args) private view returns (string out) {
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
                header = ["Filesystem", "1024-blocks", "Used", "Available", "Capacity%", "Mounted on   "];
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
//            uint16 dev_file_index;
//            uint8 dev_file_ft;
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

}

