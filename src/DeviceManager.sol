pragma ton-solidity >= 0.49.0;

import "Format.sol";
import "Commands.sol";
import "SyncFS.sol";
import "ExportFS.sol";
import "CacheFS.sol";

contract DeviceManager is Format, SyncFS, ExportFS, CacheFS {

    uint8 _bdevc;
    uint8 _cdevc;
    uint8 _devc;
    MountInfo[] _boot_mounts;
    MountInfo[] public _static_mounts;
    MountInfo[] public _current_mounts;
    DeviceInfo[] public _devices;

    /* Query devices and file systems status */
    function dev_stat(Session session, InputS input, Arg[] arg_list) external view returns (string out, uint16 action, Err[] errors) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        uint16 pid = session.pid;
        pid = pid;
        /* File system status */
        if (_op_dev_stat(c))
            (out, errors) = _dev_stat(c, flags, args, arg_list);  // 4.6

        if (!errors.empty())
            action |= ACT_PRINT_ERRORS;
    }

    /* Query devices and file systems status */
    function dev_admin(Session session, InputS input, Arg[] arg_list) external accept {
        (uint8 c, string[] args, uint flags) = input.unpack();
        uint16 pid = session.pid;
        if (!arg_list.empty())
            pid = pid;
        /* File system status */
        if (_op_dev_admin(c))
            _dev_admin(c, flags, args);  // 700
    }

    function account_info(InputS input) external view returns (string[] host_names, address[] addresses) {  // 500
        (, string[] args, uint flags) = input.unpack();
        string[] text = _get_file_contents("/etc/hosts");
        if (!args.empty())
            for (string s: args) {
                if ((flags & _d) == 0) {
                    host_names.push(s);
                    addresses.push(_to_address(_lookup_pair_value(s, text)));
                }
            }
        else
            for (string s: text) {
                string[] fields = _get_tsv(s);
                host_names.push(fields[1]);
                addresses.push(_to_address(fields[0]));
            }
    }

    function _dev_stat(uint8 c, uint flags, string[] args, Arg[] arg_list) private view returns (string out, Err[] errors) {
        if (c == df) out = _df(flags);      // 1k
        if (c == findmnt) out = _findmnt(flags, args);// 600
        if (c == lsblk) (out, errors) = _lsblk(flags, args);// 1800
        if (c == mountpoint) (out, errors) = _mountpoint(flags, args, arg_list);// 1800
        if (c == ps) out = _ps(flags); //400
    }

    function _dev_admin(uint8 c, uint flags, string[] args) private returns (string out) {
        if (c == losetup) out.append(_losetup(flags, args));      // 0
        if (c == mknod) out.append(_mknod(flags, args));// 0
        if (c == mount) _mount(flags, args);// 200
        if (c == udevadm) out.append(_udevadm(flags, args)); //0
        if (c == umount) out.append(_umount(flags, args));// 300
    }

    function _umount(uint flags, string[] args) private returns (string/* out*/) {
        bool unmount_all = (flags & _a) > 0;

        string s_source;
        string s_target;
        if (!args.empty()) {
            s_source = args[0];
            if (args.length > 1)
                s_target = args[1];
        }

        if (unmount_all) {
            for (MountInfo mnt: _current_mounts)
                _try_unmount(mnt);
        } else {
            uint8 index = _device_index(s_source);
            if (index > 0)
                _try_unmount(MountInfo(_devices[index - 1].minor_id, 1, _resolve_absolute_path(s_target), s_target, MOUNT_DIR));
        }
    }

    function _losetup(uint flags, string[] args) private view returns (string out) {
    }

    function _mount(uint flags, string[] args) private {
        bool mount_all = (flags & _a) > 0;
//        bool canonicalize_paths = (flags & _c) == 0;
//        bool dry_run = (flags & _f) > 0;
//        bool show_labels = (flags & _l) > 0;
//        bool no_mtab = (flags & _n) > 0;
//        bool verbose = (flags & _v) > 0;
//        bool read_write = (flags & _w) > 0;
        bool alt_fstab = (flags & _T) > 0;
//        bool read_only = (flags & _r) > 0;
//        bool another_namespace = (flags & _N) > 0;
//        bool bind_subtree = (flags & _B) > 0;
//        bool move_subtree = (flags & _M) > 0;

        string s_source;
        string s_target;
        if (!args.empty()) {
            s_source = args[0];
            if (args.length > 1)
                s_target = args[1];
        }

        if (mount_all) {
            for (MountInfo mnt: _static_mounts)
                _try_mount(mnt);
        } else if (alt_fstab) {
            for (MountInfo mnt: _boot_mounts)
                _try_mount(mnt);
        } else {
            uint8 index = _device_index(s_source);
            if (index > 0) {
                MountInfo mnt = MountInfo(_devices[index - 1].minor_id, 1, _resolve_absolute_path(s_target) - ROOT_DIR, s_target, MOUNT_DIR);
                if (_try_mount(mnt))
                    _current_mounts.push(mnt);
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

        string fs_name = "/dev/" + _devices[0].name;
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
//        bool search_mtab_only = (flags & _m) > 0;
//        bool search_kernel = (flags & _k) > 0;
        bool like_df = (flags & _D) > 0;
        bool first_fs_only = (flags & _f) > 0;
        bool no_headings = (flags & _n) > 0;

        string[][] table;

        string[] header = no_headings ? [""] : like_df ? ["SOURCE", "SIZE", "USED", "AVAIL", "USE%", "TARGET"] : ["TARGET", "SOURCE", "FSTYPE", "OPTIONS"];
        if (!no_headings)
            table = [header];

        if (search_fstab_only) {
            for (MountInfo mnt: _static_mounts) {
                (uint8 source_dev_id, uint16 source_export_id, , string target_path, uint16 options) = mnt.unpack();
                table.push([target_path, _devices[source_dev_id - 1].name, format("{}", source_export_id), format("{}", options)]);
            }
        } else {
            for (MountInfo mnt: _current_mounts) {
                (uint8 source_dev_id, uint16 source_export_id, , string target_path, uint16 options) = mnt.unpack();
                table.push([target_path, _devices[source_dev_id - 1].name, format("{}", source_export_id), format("{}", options)]);
                if (first_fs_only)
                    break;
            }
        }
        out.append(_format_table(table, " ", "\n", ALIGN_LEFT));
    }

    function _mountpoint(uint flags, string[] args, Arg[] arg_list) private view returns (string out, Err[] errors) {
        bool mounted_device = (flags & _d) > 0;
        bool quiet = (flags & _q) > 0;
        bool arg_device = (flags & _x) > 0;

        string arg = args[0];
        Arg x_arg = arg_list[0];
        (string path, uint8 ft, uint16 index, , ) = x_arg.unpack();

        if (arg_device) {
            if (ft != FT_BLKDEV)
                errors = [Err(not_a_block_device, 0, path)];
            else {
                (string major_id, string minor_id) = _get_device_version(_fs.inodes[index].text_data);
                out = major_id + ":" + minor_id;
            }
        }

        for (MountInfo m: _current_mounts) {
            (uint8 source_dev_id, , , string target_path,) = m.unpack();
            if (target_path == arg)
                out = mounted_device ? format("{}:{}", FT_BLKDEV, source_dev_id) : (path + " is a mountpoint");
        }

        _if(out, out.empty(), path + " is not a mountpoint");
        if (quiet)
            out = "";
    }

    function _lsblk(uint flags, string[] args) private view returns (string out, Err[] errors) {
        bool print_all_devices = (flags & _a) > 0;
        bool human_readable = (flags & _b) == 0;
        bool print_header = (flags & _n) == 0;
        bool print_fs_info = (flags & _f) > 0;
        bool print_permissions = (flags & _m) > 0;
        bool print_device_info = !print_fs_info && !print_permissions;
        bool full_path = (flags & _p) > 0;
        string[][] table;

        uint16 dev_dir = _resolve_absolute_path("/sys/dev");
        (uint16 block_dev_dir, uint8 block_dev_dir_ft) = _fetch_dir_entry("block", dev_dir);
        (uint16 char_dev_dir, uint8 char_dev_dir_ft) = _fetch_dir_entry("char", dev_dir);
        if (block_dev_dir_ft != FT_DIR || char_dev_dir_ft != FT_DIR)
            return ("Error: could not open /sys/dev/\n", errors);

        string[] header = print_device_info ? ["NAME", "MAJ:MIN", "SIZE", "RM", "TYPE", "MOUNTPOINT"] :
                            print_fs_info ? ["NAME", "FSTYPE", "LABEL", "UUID", "FSAVAIL", "FSUSE%", "MOUNTPOINT"] :
                                print_permissions ? ["NAME", "SIZE", "OWNER", "GROUP", "MODE"] : [""];
        if (print_header)
            table = [header];
        if (args.empty()) {
            for (DeviceInfo di: _devices)
                if (di.major_id == FT_BLKDEV || print_all_devices)
                    args.push(di.name);
        }

        (, , , , uint16 block_count, , uint16 free_blocks, uint16 block_size,
        , , , , , , , ) = _fs.sb.unpack();

        for (string s: args) {
            (uint16 dev_file_index, uint8 dev_file_ft) = _fetch_dir_entry(s, block_dev_dir);
            if (dev_file_ft != FT_BLKDEV && print_all_devices)
                (dev_file_index, dev_file_ft) = _fetch_dir_entry(s, char_dev_dir);
            if (dev_file_ft == FT_BLKDEV || dev_file_ft == FT_CHRDEV) {
                (uint16 mode, uint16 owner_id, , , , , , , string[] lines) = _fs.inodes[dev_file_index].unpack();
                string[] fields0 = _get_tsv(lines[0]);
                if (fields0.length < 4) {
                    continue;
                }
                string name = (full_path ? "/dev/" : "") + fields0[2];
                string mount_path = dev_file_ft == FT_BLKDEV ? ROOT : "";
                string[] l;
                if (print_device_info)
                    l = [name,
                         format("{}:{}", fields0[0], fields0[1]),
                         _scale(uint32(block_count) * block_size, human_readable ? 1024 : 1),
                         "0",
                         "disk",
                         mount_path];
                else if (print_fs_info)
                    l = [name,
                        " ",
                        " ",
                        " ",
                        _scale(uint32(free_blocks) * block_size, human_readable ? 1024 : 1),
                        format("{}%", uint32(block_count) * 100 / (block_count + free_blocks)),
                        mount_path];
                else if (print_permissions) {
                    (, string s_owner, string s_group) = _users[owner_id].unpack();
                    l = [name,
                        _scale(uint32(block_count) * block_size, human_readable ? 1024 : 1),
                        s_owner,
                        s_group,
                        _permissions(mode)];
                }
                table.push(l);
            } else
                errors.push(Err(not_a_block_device, 0, s));
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

    /* mount helpers */
    function _try_mount(MountInfo mnt) internal view returns (bool) {
        (uint8 source_dev_id, uint16 source_export_id, uint16 target_mount_point, , uint16 options) = mnt.unpack();
        for (MountInfo m: _current_mounts) {
            (uint8 cur_source_dev_id, uint16 cur_source_export_id, uint16 cur_target_mount_point, ,) = m.unpack();
            if (cur_source_dev_id == source_dev_id && cur_source_export_id == source_export_id && cur_target_mount_point == target_mount_point)
                return false;
        }
        address source_address;
        for (DeviceInfo di: _devices) {
            (uint8 major_id, uint8 minor_id, , , , address device_address) = di.unpack();
            if (major_id == FT_BLKDEV && minor_id == source_dev_id)
                source_address = device_address;
        }
        if (!source_address.isStdZero()) {
            ISourceFS(_source_device.device_address).request_mount{value: 0.1 ton}(source_address, source_export_id, target_mount_point, options);
            return true;
        }
        return false;
    }

    function _try_unmount(MountInfo mnt) internal returns (bool) {
        (uint8 source_dev_id, uint16 source_export_id, uint16 target_mount_point, , ) = mnt.unpack();
        for (uint16 i = 0; i < _current_mounts.length; i++) {
            (uint8 cur_source_dev_id, uint16 cur_source_export_id, uint16 cur_target_mount_point, ,) = _current_mounts[i].unpack();
            if (cur_source_dev_id == source_dev_id && cur_source_export_id == source_export_id && cur_target_mount_point == target_mount_point) {
                _current_mounts[i] = MountInfo(0, 0, 0, "", MOUNT_NONE);
                return true;
            }
        }
        return false;
    }

    /* Device helpers */
    function _device_index(string name) internal view returns (uint8 index) {
        for (uint8 i = 0; i < _devices.length; i++)
            if (_devices[i].name == name)
                return i + 1;
    }

    function _add_device_files(uint8 major_id, string[] names, uint[] addresses) internal { // 1k
        uint16 counter = _export_fs.ic;
        bool bd = major_id == FT_BLKDEV;
        uint8 n_devices = uint8(names.length);
        uint16 blk_size = bd ? DEF_BLOCK_SIZE : 0;
        uint16 n_blocks = bd ? MAX_BLOCKS : 0;
        uint8 dev_counter = bd ? _bdevc : _cdevc;

        for (uint8 i = 0; i < n_devices; i++) {
            string name = names[i];
            address addr = address.makeAddrStd(0, addresses[i]);
            _devices.push(DeviceInfo(major_id, dev_counter + i, name, blk_size, n_blocks, addr));
            _export_fs.inodes[counter + i] = _get_any_node(major_id, SUPER_USER, SUPER_USER_GROUP, name,
                [format("{}\t{}\t{}\t{}\t{}", major_id, dev_counter + i, name, blk_size, n_blocks), format("{}", addr)]);
        }
        _export_fs.ic += n_devices;
        _devc += n_devices;
        if (bd)
            _bdevc += n_devices;
        else
            _cdevc += n_devices;
    }

    /* Init routine */
    function _init() internal override accept {
        _export_fs = _get_fs(1, "dev_fs", ["block", "char"]);  // 600
        _bdevc = 1;
        _cdevc = 1;
        _static_mounts = [
            MountInfo(2, 2, 3, "/etc", MOUNT_DIR),
            MountInfo(3, 1, 13, "/sys/dev/block", MOUNT_DIR),
            MountInfo(3, 2, 14, "/sys/dev/char", MOUNT_DIR),
            MountInfo(2, 1, 8, "/usr", MOUNT_DIR),
            MountInfo(5, 1, 1, "/bin", MOUNT_DIR),
            MountInfo(6, 1, 1, "/bin", MOUNT_DIR),
            MountInfo(7, 1, 1, "/bin", MOUNT_DIR),
            MountInfo(8, 1, 1, "/bin", MOUNT_DIR),
            MountInfo(9, 1, 1, "/bin", MOUNT_DIR)];
        this.init2();
    }

    function init2() external accept {
        _add_device_files(FT_BLKDEV,
            ["BlockDevice", "DataVolume", "DeviceManager", "AccessManager"], [
            0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5,
            0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb,
            0x430dd570de5398dbc2319979f5ba4aa99d5254e5382d3c344b985733d141617b,
            0x4a7cd37ce66473c7b383a245891502e5d05c626a69ca764165e2c7d6edd9e317]);
        this.init3(); //450
    }

    function init3() external accept {
        _add_device_files(FT_BLKDEV,
            ["ManualCommands", "ManualStatus", "ManualSession", "ManualUtility", "ManualAdmin"], [
            0x4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981,
            0x41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420,
            0x41e37889496dce38efdeb5764cf088287171d72c523c370b37bb6b3621d1f93e,
            0x4e5561b275d060ff0d0919ccc7e485d08c8e1fe9abd92af6cdf19ebfb2dd5421,
            0x650627a3165cea5c12558aaf9d38f791a33660792d41136e1a6dba48549ce89b]);
        this.init4();   // 600
    }

    function init4() external accept {
        _sb_exports.push(_get_export_sb(ROOT_DIR + 3, 9, "block"));
        _add_device_files(FT_CHRDEV,
            ["FileManager", "StatusReader", "PrintFormatted", "SessionManager"], [
            0x47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40,
            0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9,
            0x48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec,
            0x4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d]);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 3 + 9, 4, "char"));

        _sync_fs_cache();
    }

}

