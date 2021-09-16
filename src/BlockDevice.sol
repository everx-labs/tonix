pragma ton-solidity >= 0.49.0;

import "SyncFS.sol";
import "Base.sol";
import "ICache.sol";
import "ImportFS.sol";
/* Generic block device hosting a generic file system */
contract BlockDevice is Base, SyncFS, ImportFS, ISourceFS {

    uint16 constant STG_NONE    = 0;
    uint16 constant STG_PRIMARY = 1;
    uint16 constant STG_INODE   = 2;
    uint16 constant STG_ALT     = 4;
    uint16 constant STG_LOCAL   = 8;
    uint16 constant STG_SYNC    = 16;
    uint16 constant STG_TMP     = 32;
    uint16 constant STG_RO      = 64;

    address[5] _readers;

    DeviceInfo[] public _dev;

    mapping (uint16 => FileMapS) public _file_table;
    string[] public _blocks;
    mapping (uint16 => FileS) public _fd_table;
    uint16 _fdc;

    /* Common file system update routine */
    function update_nodes(SessionS session, IOEventS[] ios) external accept {
        for (IOEventS e: ios) {
            uint8 et = e.iotype;
            if (_is_add(et))
                _add_files(session, e.parent, et, e.args);
            if (_is_update(et))
                _change_attributes(session, e.parent, et, e.args);
        }
    }

    /* Write the text to a file at path */
    function write_to_file(SessionS session, string path, string text) external accept {
        (uint16 uid, uint16 gid, uint16 wd) = (session.uid, session.gid, session.wd);
        uint32 size = text.byteLength();
        uint16 n_blocks = uint16(size / _dev[0].blk_size) + 1;
        uint16 storage_type = STG_NONE;
        string[] text_data;
        text_data.push(text);
        INodeS inode = _get_file_node(uid, gid, path, text_data);
        inode.file_size = size;

        if (n_blocks > _fs.sb.free_blocks)
            return;

        storage_type |= STG_PRIMARY;
        (uint16 b_start, uint16 b_count) = _write_text(0, text);

        if (n_blocks == 1) {
            storage_type |= STG_INODE;
            inode.text_data.push(text);
        }

//        _add_reg_files(wd, [inode]);
        uint16 i_start = _fs.ic++;
        _fs.inodes[i_start] = inode;
        _append_dir_entry(wd, i_start, inode.file_name, FT_REG_FILE);

        _file_table[i_start] = FileMapS(storage_type, b_start, b_count);
        _update_inodes_set([wd, i_start]);
    }

    /* Write blocks of textual data to a file identified by descriptor */
    function write_fd(uint16 pid, uint16 fd, uint16 start, string[] blocks) external accept {
        FileS f = _proc[pid].fd_table[fd];
        uint16 inode = f.inode;
        FileMapS fm = _file_table[inode];
        uint16 len = uint16(blocks.length);

        for (uint16 i = 0; i < len; i++)
            _blocks[fm.start + start + i] = blocks[i];
        f.bc += len;

        if (f.bc >= f.n_blk) {
            _fs.inodes[inode].file_size = uint32(f.n_blk) * _fs.sb.block_size + blocks[len - 1].byteLength();
            delete _proc[pid].fd_table[fd];
            _update_inodes_set([inode]);
        } else
            _proc[pid].fd_table[fd] = f;
    }

    /* Read blocks of textual data fron the files specified by index */
    function read_indices(ArgS[] args) external view returns (string[][] texts) {
        return _read_indices(args);
    }

    /* next expected write for a file opened by the process */
    function next_write(uint16 pid, uint16 fdi) external view returns (uint16 start, uint16 count) {
        FileS f = _proc[pid].fd_table[fdi];
        start = f.bc;
        count = f.n_blk - f.bc;
        if (count > f.state)
            count = f.state;
    }

    /* Remove an expired index node */
    function remove_node(uint16 parent, uint16 victim) external accept {
        delete _fs.inodes[victim];

        if (_fs.inodes[parent].n_links < 2)
            delete _fs.inodes[parent];
        _update_inodes_set([parent, victim]);
    }

    function _create_subdirs(uint16 pino, string[] files) internal {
        uint16 len = uint16(files.length);
        uint16 counter = _fs.ic;
        for (uint16 i = 0; i < len; i++) {
            _fs.inodes[counter + i] = _get_dir_node(counter + i, pino, SUPER_USER, SUPER_USER_GROUP, files[i]);
            _append_dir_entry(pino, counter + i, files[i], FT_DIR);
        }
        _claim_inodes(len);
    }

    function _create_character_devices(uint16 parent, string[] names, address[] addresses) internal {
        uint16 counter = _fs.ic;
        uint8 dev_counter = _dc;
        uint16 len = uint16(names.length);
        for (uint8 i = 0; i < len; i++) {
            DeviceInfo dev = DeviceInfo(FT_CHRDEV, dev_counter + i, names[i], 0, 0, addresses[i]);
            _dev.push(dev);
            INodeS inode = _get_character_device_node(dev);
            _fs.inodes[counter + i] = inode;
            _append_dir_entry(parent, counter + i, dev.name, FT_CHRDEV);
        }
        _dc += uint8(len);
        _claim_inodes(len);
    }

    function _create_device(uint16 parent, DeviceInfo dev) internal {
        uint16 counter = _fs.ic++;
        _dev.push(dev);
        uint8 ft = dev.major_id;
        INodeS inode = ft == FT_BLKDEV ? _get_block_device_node(dev) : _get_character_device_node(dev);
        _fs.inodes[counter] = inode;
        _fs.inodes[parent] = _add_dir_entry(_fs.inodes[parent], counter, dev.name, FT_BLKDEV);
//        _append_dir_entry(parent, counter, dev.name, FT_BLKDEV);
    }

    function _read_indices(ArgS[] args) internal view returns (string[][] texts) {
        for (ArgS arg: args) {
            uint16 idx = arg.idx;
            FileMapS file = _file_table[idx];
            if ((file.storage_type & STG_PRIMARY) > 0) {
                string text;
                for (uint16 i = 0; i < file.count; i++)
                    text.append(_blocks[file.start + i]);
                texts.push([text]);
            } else
                texts.push(_fs.inodes[idx].text_data);
        }
    }

    function _change_attributes(SessionS session, uint16 pino, uint8 ft, ArgS[] args) internal {
        (, uint16 uid, uint16 gid, ) = session.unpack();
        uint16[] indices;
        uint16 len = uint16(args.length);
        INodeS parent_inode = _fs.inodes[pino];
        for (uint16 i = 0; i < len; i++) {
            (string path, , uint16 idx, uint16 parent, uint16 dir_idx) = args[i].unpack();
            if (ft == IO_CHATTR) {
                INodeS inode = _fs.inodes[idx];
                if (inode.owner_id == uid || inode.group_id == gid) {
                    _fs.inodes[idx].owner_id = parent_inode.owner_id;
                    _fs.inodes[idx].group_id = parent_inode.group_id;
                    indices.push(idx);
                }
            }
            if (ft == IO_PERMISSION) {
                _fs.inodes[idx].mode = parent_inode.mode;
                indices.push(idx);
            }
            if (ft == IO_UPDATE_TIME) {
                _fs.inodes[idx].modified_at = parent_inode.modified_at;
                _fs.inodes[idx].last_modified = parent_inode.last_modified;
                indices.push(idx);
            }
            if (ft == IO_UNLINK) {
                _fs.inodes[idx].n_links--;
                _fs.inodes[parent].n_links--;
                if (_fs.inodes[idx].n_links == 0) {
                    delete _fs.inodes[idx];
                    string[] text = _fs.inodes[parent].text_data;
                    for (uint16 j = dir_idx - 1; j < text.length - 1; j++)
                        text[j] = text[j + 1];
                    _fs.inodes[parent].text_data = text;
                }
                indices.push(parent);
            }
            if (ft == IO_HARDLINK) {
                _fs.inodes[pino].n_links++;
                _append_dir_entry(pino, idx, path, FT_REG_FILE);
            }
        }
        indices.push(pino);
        _fs.sb.last_write_time = now;
        _update_inodes_set(indices);
    }

    function _add_files(SessionS session, uint16 pino, uint8 et, ArgS[] args) internal {
        (uint16 pid, uint16 uid, uint16 gid, ) = session.unpack();
        uint16 len = uint16(args.length);
        uint16 counter = _fs.ic;
        bool copy_contents = et == IO_WR_COPY;
        bool allocate = et == IO_ALLOCATE;

        uint16[] inodes;
        uint16 symlink_target_idx;

        for (uint16 i = 0; i < len; i++) {
            (string s, , uint16 idx, uint16 parent, uint16 dir_idx) = args[i].unpack();
            uint16 ino = counter + i;
            if (et == IO_MKDIR) {
                _fs.inodes[ino] = _get_dir_node(ino, parent, uid, gid, s);
                _append_dir_entry(parent, ino, s, FT_DIR);
                inodes.push(idx);
            } else if (et == IO_MKFILE) {
                _fs.inodes[ino] = _get_file_node(uid, gid, s, [""]);
                _append_dir_entry(parent, ino, s, FT_REG_FILE);
                inodes.push(parent);
            } else if (et == IO_SYMLINK) {
                if (i == 0) {
                    symlink_target_idx = parent;
                    counter--;
                } else {
                    _fs.inodes[ino] = _get_symlink_node(uid, gid, s, _fs.inodes[parent].text_data[dir_idx - 1]);
                    _append_dir_entry(symlink_target_idx, ino, s, FT_SYMLINK);
                    inodes.push(ino);
                    inodes.push(symlink_target_idx);
                }
            } else if (et == IO_WR_COPY) {
                uint16 target_storage_type = STG_NONE;
                uint16 b_start;
                uint16 b_count;
                uint16 b_batch_size;
                string[] contents;

                if (idx > 0)
                    contents = _fs.inodes[idx].text_data;

                if (allocate) {
                    (b_start, b_count, b_batch_size) = _allocate_blocks(0, idx);
                    _proc[pid].fd_table[_fdc++] = FileS(0, ino, b_batch_size, 0, b_count, 0, b_count * idx, s);
                }
                if (copy_contents) {
                    FileMapS source = _file_table[idx];
                    if ((source.storage_type & STG_PRIMARY) > 0)
                        (b_start, b_count) = _copy_blocks(source.start, source.count);
                    else if (!contents.empty())
                        (b_start, b_count) = _write_text(0, _merge(contents));
                }
                if (b_start > 0 && b_count > 0) {
                    target_storage_type |= STG_PRIMARY;
                    SuperBlock sb = _fs.sb;
                    sb.block_count += b_count;
                    sb.free_blocks -= b_count;
                    sb.lifetime_writes++;
                    sb.last_write_time = now;
                    _fs.sb = sb;
                }
                _fs.inodes[ino] = _get_file_node(uid, gid, s, contents);
                _append_dir_entry(parent, ino, s, FT_REG_FILE);

                _file_table[ino] = FileMapS(target_storage_type, b_start, b_count);
            }
        }

        _claim_inodes(len);
        inodes.push(pino);
        for (uint16 i = counter; i < counter + len; i++)
            inodes.push(i);
        _update_inodes_set(inodes);
    }

    /* Index node operations helpers */
    function _is_add(uint8 t) internal pure returns (bool) {
        return t == IO_WR_COPY || t == IO_MKFILE || t == IO_ALLOCATE || t == IO_MKDIR || t == IO_SYMLINK;
    }

    function _is_update(uint8 t) internal pure returns (bool) {
        return t == IO_CHATTR || t == IO_ACCESS || t == IO_PERMISSION || t == IO_UPDATE_TIME || t == IO_UNLINK || t == IO_HARDLINK || t == IO_TRUNCATE;
    }

    /* Block operations helpers */
    function _copy_blocks(uint16 s_start, uint16 s_count) internal returns (uint16 start, uint16 count) {
        SuperBlock sb = _fs.sb;
        if (sb.file_system_state && sb.free_blocks > 0) {
            start = uint16(_blocks.length);
            count = uint16(math.min(sb.free_blocks, s_count));
            for (uint16 i = 0; i < count; i++)
                _blocks.push(_blocks[i + s_start]);
        }
    }

    function _allocate_blocks(uint16 device_id, uint16 kbytes) internal returns (uint16 start, uint16 count, uint16 batch_size) {
        SuperBlock sb = _fs.sb;
        uint16 blk_size = _dev[device_id].blk_size;
        count = uint16(uint32(kbytes) * 1024 / blk_size);
        batch_size = 16000 / blk_size;

        if (sb.file_system_state && sb.free_blocks > count)
            start = uint16(_blocks.length);
        string empty;
        for (uint16 i = 0; i < count; i++)
            _blocks.push(empty);
    }

    function _write_text(uint16 device_id, string text) internal returns (uint16 start, uint16 count) {
        uint16 blk_size = _dev[device_id].blk_size;
        uint32 len = uint32(text.byteLength());
        uint16 n_blocks = uint16(len / blk_size);
        start = uint16(_blocks.length);
        count = n_blocks + 1;

        for (uint16 i = 0; i < n_blocks; i++)
            _blocks.push(text.substr(i * blk_size, blk_size));
        _blocks.push(text.substr(n_blocks * blk_size, len - n_blocks * blk_size));
    }

    /* File system initialization */
    function _make_fs() internal {
        _fs = _get_fs(1, "sysfs", ["dev", "etc", "home", "mnt", "proc", "sys", "usr"]);
        _create_subdirs(ROOT_DIR + 3, ["boris", "guest", "ivan"]);
        _create_subdirs(ROOT_DIR + 6, ["dev"]);
        _create_subdirs(ROOT_DIR + 11, ["block", "char"]);
        _create_device(ROOT_DIR + 1, DeviceInfo(BLK_DEVICE, _dc++, "BlockDevice", 1024, 100, address(this)));
        _blocks.push(_write_sb());
    }

    function _write_sb() internal view returns (string) {
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = _fs.sb.unpack();

        return format("{}\t{}\t{}\n{}\t{}\t{}\t{}\n{}\n{}\t{}\t{}\t{}\t{}\n{}\t{}\t{}\n", file_system_state ? 1 : 0, errors_behavior ? 1 : 0,
            file_system_OS_type, inode_count, block_count++, free_inodes, free_blocks--, block_size, created_at, last_mount_time, last_write_time,
            mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
    }

    function _init() internal override {
        this.init();
    }

    function _mount_exports() internal pure {
        IExportFS(address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb)).
            rpc_mountd{value: 0.5 ton}(2, ROOT_DIR + 2);
    }

    function _get_fd_table() internal pure returns (mapping (uint16 => FileS) fd_table) {
        /*struct FileS {uint16 mode; uint16 inode; uint16 state; uint16 bc; uint16 n_blk; uint32 pos; uint32 fize; string name;} */
        fd_table[0] = FileS(0, 0, 0, 0, 0, 0, 0, "in");
        fd_table[1] = FileS(0, 0, 0, 0, 0, 0, 0, "out");
        fd_table[2] = FileS(0, 0, 0, 0, 0, 0, 0, "err");
    }

    function _spawn_processes() internal {
        _proc[SUPER_USER + 1] = ProcessInfo(SUPER_USER, SUPER_USER + 1, DEF_UMASK, ROOT);
        _proc[SUPER_USER + 2] = ProcessInfo(REG_USER, SUPER_USER + 2, DEF_UMASK, ROOT);
        _proc[SUPER_USER + 2].fd_table = _get_fd_table();
        _proc[SUPER_USER + 3] = ProcessInfo(REG_USER + 1, SUPER_USER + 3, DEF_UMASK, ROOT);
        _proc[SUPER_USER + 3].fd_table = _get_fd_table();
    }

    function _init_users() internal {
        _users[SUPER_USER] = UserInfo(SUPER_USER, SUPER_USER_GROUP, "root", "root", "/root");
        _users[REG_USER] = UserInfo(REG_USER, REG_USER_GROUP, "boris", "staff", "/home/boris");
        _users[REG_USER + 1] = UserInfo(REG_USER + 1, REG_USER_GROUP, "ivan", "staff", "/home/ivan");
        _users[GUEST_USER] = UserInfo(GUEST_USER, GUEST_USER_GROUP, "guest", "guest", "/home/guest");
    }

    function _create_config_files() internal {
    }

    function _init_readers() internal {
        address[5] readers = [
            address.makeAddrStd(0, 0x47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40),
            address.makeAddrStd(0, 0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9),
            address.makeAddrStd(0, 0x48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec),
            address.makeAddrStd(0, 0x4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d),
            address.makeAddrStd(0, 0x430dd570de5398dbc2319979f5ba4aa99d5254e5382d3c344b985733d141617b)];

        _create_character_devices(ROOT_DIR + 1, ["FileManager", "StatusReader", "PrintFormatted", "SessionManager", "DeviceManager"], readers);

//        for (address addr: readers)
//            Device(addr).flush_fs_cache{value: 0.02 ton}();
        _readers = readers;
        _update_inodes(_fs.inodes);
    }

    function init() external accept {
        _make_fs();
        _init_users();
        _spawn_processes();
        _mount_exports();
        this.init2();
    }

    function init2() external accept {
        _init_readers();
        _create_config_files();
    }

    /* Fully Update a file system information on a file system cache device */
    function query_fs_cache() external override view accept {
        uint64 val = uint64(_fs.sb.inode_count) * 0.01 ton + 0.1 ton;
        ICacheFS(msg.sender).update_fs_cache{value: val, flag: 1}(_fs.sb, _dev[0], _proc, _users, _fs.inodes);
    }

    function _update_inodes(mapping (uint16 => INodeS) inn) internal view {
        for (address addr: _readers)
            ICacheFS(addr).update_fs_cache{value: 0.1 ton, flag: 1}(_fs.sb, _dev[0], _proc, _users, inn);
    }

    function _update_inodes_set(uint16[] inodes) internal view {
        mapping (uint16 => INodeS) inn;
        uint count;
        for (uint16 i: inodes)
            if (_fs.inodes.exists(i)) {
                inn[i] = _fs.inodes[i];
                count++;
            }
        _update_inodes(inn);
    }
}
