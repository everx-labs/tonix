pragma ton-solidity >= 0.49.0;

import "SyncFS.sol";
import "Base.sol";
import "ICache.sol";

/* Generic block device hosting a generic file system */
contract BlockDevice is Base, SyncFS, ISourceFS {

    uint16 constant STG_NONE    = 0;
    uint16 constant STG_PRIMARY = 1;
    uint16 constant STG_INODE   = 2;
    uint16 constant STG_ALT     = 4;
    uint16 constant STG_LOCAL   = 8;
    uint16 constant STG_SYNC    = 16;
    uint16 constant STG_TMP     = 32;
    uint16 constant STG_RO      = 64;

    address[5] _readers;

    DeviceInfo public _dev;

    mapping (uint16 => FileMapS) public _file_table;
    string[] public _blocks;
    mapping (uint16 => FileS) public _fd_table;
    uint16 _fdc;

    /* Mount a set of index nodes to the specified mount point of the primary file system */
    function mount_dir(uint16 mount_point_index, Inode[] inodes) external override accept {
        uint n_files = inodes.length;
        uint counter = _fs.ic;
        Inode mount_point = _fs.inodes[mount_point_index];
        uint16[] indices;
        for (uint i = 0; i < n_files; i++) {
            Inode inode = inodes[i];
            uint16 index = uint16(counter + i);
            _fs.inodes[index] = inode;
            mount_point = _add_dir_entry(mount_point, index, inode.file_name, _mode_to_file_type(inode.mode));
        }
        _fs.inodes[mount_point_index] = mount_point;
        _claim_inodes(n_files, n_files);

        indices.push(mount_point_index);
        for (uint i = counter; i < counter + n_files; i++)
            indices.push(uint16(i));
        _update_inodes_set(indices);
    }

    function request_mount(address source, uint16 export_id, uint16 mount_point, uint16 options) external view override accept {
        if ((options & MOUNT_DIR) > 0)
            IExportFS(source).rpc_mountd{value: 0.1 ton}(export_id, ROOT_DIR + mount_point);
    }

    /* Common file system update routine */
    function update_nodes(Session session, IOEvent[] ios) external override accept {
        for (IOEvent e: ios) {
            uint8 et = e.iotype;
            if (_is_add(et))
                _add_files(session, e.parent, et, e.args);
            if (_is_update(et))
                _change_attributes(session, e.parent, et, e.args);
        }
    }

    function update_user_info(Session session, UserEvent[] ues) external override accept {
        uint16 reg_u;
        uint16 sys_u;
        uint16 reg_g;
        uint16 sys_g;

        for (UserEvent e: ues) {
            (uint8 et, uint16 user_id, uint16 group_id, uint16 options, string user_name, string group_name, ) = e.unpack();

            bool is_system_account = (options & UAO_SYSTEM) > 0;
            bool create_home_dir = (options & UAO_CREATE_HOME_DIR) > 0;
            bool create_user_group = (options & UAO_CREATE_USER_GROUP) > 0;

            if (et == UA_ADD_USER) {
                if (create_user_group) {
                    _groups[group_id] = GroupInfo(group_name, is_system_account);
                    if (is_system_account)
                        sys_g++;
                    else
                        reg_g++;
                    _change_attributes(session, ROOT_DIR + 3, IO_UPDATE_TEXT_DATA, [Arg(format("{}\t{}", group_name, group_id), FT_REG_FILE, 30, ROOT_DIR + 3, 0)]);
                }
                if (create_home_dir)
                    _add_files(session, ROOT_DIR + 4, IO_MKDIR, [Arg("/home/" + user_name, FT_DIR, ENOENT, ROOT_DIR + 4, 0)]);
                _users[user_id] = UserInfo(group_id, user_name, group_name);
                if (is_system_account)
                    sys_u++;
                else
                    reg_u++;
                _change_attributes(session, ROOT_DIR + 4, IO_UPDATE_TEXT_DATA, [Arg(format("{}\t{}\t{}\t{}\t{}", user_name, user_id, group_id, group_name, "/home/" + user_name), FT_REG_FILE, 36, ROOT_DIR + 3, 0)]);
            } else if (et == UA_ADD_GROUP) {
                _groups[group_id] = GroupInfo(group_name, is_system_account);
                if (is_system_account)
                    sys_g++;
                else
                    reg_g++;
                _change_attributes(session, ROOT_DIR + 3, IO_UPDATE_TEXT_DATA, [Arg(format("{}\t{}", group_name, group_id), FT_REG_FILE, 30, ROOT_DIR + 3, 0)]);
            } else if (et == UA_DELETE_USER) {
                delete _users[user_id];
            } else if (et == UA_DELETE_GROUP) {
                delete _groups[group_id];
            } else if (et == UA_UPDATE_USER) {
                _users[user_id] = UserInfo(group_id, user_name, group_name);
            } else if (et == UA_UPDATE_GROUP) {
                _groups[group_id].group_name = group_name;
            } else if (et == UA_RENAME_GROUP) {
                _groups[group_id].group_name = group_name;
            } else if (et == UA_CHANGE_GROUP_ID) {
                _groups[group_id] = _groups[user_id];
                delete _groups[user_id];
            }
        }
        IUserTables(msg.sender).update_tables{value: 0.1 ton, flag: 1}(_users, _groups, reg_u, sys_u, reg_g, sys_g);
    }
    /* Write the text to a file at path */
    function write_to_file(Session session, string path, string text) external accept {
        (uint16 uid, uint16 gid, uint16 wd) = (session.uid, session.gid, session.wd);
        uint32 size = text.byteLength();
        uint16 n_blocks = uint16(size / _dev.blk_size) + 1;
        uint16 storage_type = STG_NONE;

        if (n_blocks > _fs.sb.free_blocks)
            return;

        storage_type |= STG_PRIMARY;
        (uint16 b_start, uint16 b_count) = _write_text(text);

        string[] text_data;

        if (n_blocks == 1) {
            storage_type |= STG_INODE;
            text_data = [text];
        }

        uint16 counter = _fs.ic++;
        _fs.inodes[counter] = _get_any_node(FT_REG_FILE, uid, gid, path, text_data);
        _append_dir_entry(wd, counter, path, FT_REG_FILE);

        _file_table[counter] = FileMapS(storage_type, b_start, b_count);
        _claim_inodes(1, b_count);
        _update_inodes_set([wd, counter]);
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
    function read_indices(Arg[] args) external view returns (string[][] texts) {
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

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _fs);
    }

    /*function _create_subdirs(uint16 pino, string[] files) internal {
        uint n_subdirs = files.length;
        uint counter = _fs.ic;
        for (uint i = 0; i < n_subdirs; i++) {
            uint16 index = uint16(counter + i);
            string file_name = files[i];
            Inode dir_node = _get_dir_node(index, pino, SUPER_USER, SUPER_USER_GROUP, file_name);
            _fs.inodes[index] = dir_node;
            _append_dir_entry(pino, index, file_name, FT_DIR);
        }
        _claim_inodes(n_subdirs, n_subdirs);
    }*/

    function _create_subdirs(Session session, uint16 pino, string[] files) internal {
        Arg[] args_create;
        for (string s: files)
            args_create.push(Arg(s, FT_DIR, 0, pino, 0));
        _add_files(session, pino, IO_MKDIR, args_create);
    }

    /* Directory entry helpers */
    function _append_dir_entry(uint16 dir_idx, uint16 ino, string file_name, uint8 file_type) internal {
        Inode inode_dir = _fs.inodes[dir_idx];
        string dirent = _dir_entry_line(ino, file_name, file_type);
        inode_dir.text_data.push(dirent);
        inode_dir.file_size += uint32(dirent.byteLength());
        inode_dir.n_links++;
//        _update_blocks(dir_idx, dirent);
        _fs.inodes[dir_idx] = inode_dir;
    }

    function _read_indices(Arg[] args) internal view returns (string[][] texts) {
        for (Arg arg: args) {
            uint16 idx = arg.idx;
            FileMapS file = _file_table[idx];
            if ((file.storage_type & STG_PRIMARY) > 0) {
                string text;
                for (uint i = 0; i < file.count; i++)
                    text.append(_blocks[file.start + i]);
                texts.push([text]);
            } else
                texts.push(_fs.inodes[idx].text_data);
        }
    }

    function _change_attributes(Session session, uint16 pino, uint8 et, Arg[] args) internal {
        (, uint16 uid, uint16 gid, ) = session.unpack();
        uint16[] indices;
        uint len = args.length;
        Inode parent_inode = _fs.inodes[pino];
        for (uint i = 0; i < len; i++) {
            (string path, , uint16 idx, uint16 parent, uint16 dir_idx) = args[i].unpack();
            if (et == IO_CHATTR) {
                Inode inode = _fs.inodes[idx];
                if (inode.owner_id == uid || inode.group_id == gid) {
                    _fs.inodes[idx].owner_id = parent_inode.owner_id;
                    _fs.inodes[idx].group_id = parent_inode.group_id;
                    indices.push(idx);
                }
            }
            if (et == IO_PERMISSION) {
                _fs.inodes[idx].mode = parent_inode.mode;
                indices.push(idx);
            }
            if (et == IO_UPDATE_TIME) {
                _fs.inodes[idx].modified_at = parent_inode.modified_at;
                _fs.inodes[idx].last_modified = parent_inode.last_modified;
                indices.push(idx);
            }
            if (et == IO_UNLINK) {
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
            if (et == IO_HARDLINK) {
                _fs.inodes[pino].n_links++;
                _append_dir_entry(pino, idx, path, FT_REG_FILE);
            }
            if (et == IO_UPDATE_TEXT_DATA) {
                Inode inode = _fs.inodes[idx];
                inode.text_data.push(path);
                inode.file_size += uint32(path.byteLength());
                inode.modified_at = now;
                _fs.inodes[idx] = inode;
                indices.push(idx);
            }
        }
        indices.push(pino);
        _fs.sb.last_write_time = now;
        _update_inodes_set(indices);
    }

    function _add_files(Session session, uint16 pino, uint8 et, Arg[] args) internal {
        (uint16 pid, uint16 uid, uint16 gid, ) = session.unpack();
        uint n_files = args.length;
        uint16 counter = _fs.ic;
        uint total_blocks;
        bool copy_contents = et == IO_WR_COPY;
        bool allocate = et == IO_ALLOCATE;

        uint16[] inodes;
        uint16 symlink_target_idx;

        for (uint i = 0; i < n_files; i++) {
            (string s, , uint16 idx, uint16 parent, uint16 dir_idx) = args[i].unpack();
            uint16 ino = uint16(counter + i);
            if (et == IO_MKDIR) {
                _fs.inodes[ino] = _get_dir_node(ino, parent, uid, gid, s);
                _append_dir_entry(parent, ino, s, FT_DIR);
                inodes.push(idx);
            } else if (et == IO_MKFILE) {
//                _fs.inodes[ino] = _get_file_node(uid, gid, s, [""]);
                string[] empty;
                _fs.inodes[ino] = _get_any_node(FT_REG_FILE, uid, gid, s, empty);
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
                uint b_start;
                uint b_count;
                uint b_batch_size;
                string[] contents;

                if (idx > 0)
                    contents = _fs.inodes[idx].text_data;

                if (allocate) {
                    (b_start, b_count, b_batch_size) = _allocate_blocks(idx);
                    _proc[pid].fd_table[_fdc++] = FileS(0, ino, uint16(b_batch_size), 0, uint16(b_count), 0, uint16(b_count) * idx, s);
                }
                if (copy_contents) {
                    FileMapS source = _file_table[idx];
                    if ((source.storage_type & STG_PRIMARY) > 0)
                        (b_start, b_count) = _copy_blocks(source.start, source.count);
                    else if (!contents.empty())
//                        (b_start, b_count) = _write_text(_merge(contents));
                        (b_start, b_count) = _update_blocks(ino, _merge(contents));
                }
                if (b_start > 0 && b_count > 0)
                    target_storage_type |= STG_PRIMARY;
                _fs.inodes[ino] = _get_any_node(FT_REG_FILE, uid, gid, s, contents);
                _append_dir_entry(parent, ino, s, FT_REG_FILE);
                _file_table[ino] = FileMapS(target_storage_type, uint16(b_start), uint16(b_count));
                total_blocks += b_count;
            }
        }

        _claim_inodes(n_files, math.max(total_blocks, n_files));
        inodes.push(pino);
        for (uint16 i = counter; i < counter + n_files; i++)
            inodes.push(i);
        _update_inodes_set(inodes);
    }

    /* Index node operations helpers */
    function _is_add(uint8 t) internal pure returns (bool) {
        return t == IO_WR_COPY || t == IO_MKFILE || t == IO_ALLOCATE || t == IO_MKDIR || t == IO_SYMLINK;
    }

    function _is_update(uint8 t) internal pure returns (bool) {
        return t == IO_CHATTR || t == IO_ACCESS || t == IO_PERMISSION || t == IO_UPDATE_TIME || t == IO_UNLINK || t == IO_HARDLINK || t == IO_TRUNCATE || t == IO_UPDATE_TEXT_DATA;
    }

    /* Block operations helpers */
    function _copy_blocks(uint s_start, uint s_count) internal returns (uint start, uint count) {
        SuperBlock sb = _fs.sb;
        if (sb.file_system_state && sb.free_blocks > 0) {
            start = _blocks.length;
            count = math.min(sb.free_blocks, s_count);
            for (uint i = 0; i < count; i++)
                _blocks.push(_blocks[i + s_start]);
        }
    }

    function _allocate_blocks(uint kbytes) internal returns (uint start, uint count, uint batch_size) {
        SuperBlock sb = _fs.sb;
        uint blk_size = _dev.blk_size;
        count = kbytes * 1024 / blk_size;
        batch_size = 16000 / blk_size;

        if (sb.file_system_state && sb.free_blocks > count)
            start = _blocks.length;
        string empty;
        for (uint i = 0; i < count; i++)
            _blocks.push(empty);
    }

    function _write_text(string text) internal returns (uint16, uint16) {
        uint blk_size = _dev.blk_size;
        uint len = text.byteLength();
        uint n_blocks = len / blk_size;

        for (uint i = 0; i < n_blocks; i++)
            _blocks.push(text.substr(i * blk_size, blk_size));
        _blocks.push(text.substr(n_blocks * blk_size, len - n_blocks * blk_size));
        return (uint16(_blocks.length), uint16(n_blocks + 1));
    }

    function _update_blocks(uint16 index, string text) internal returns (uint16 b_start, uint16 b_count) {
        uint16 storage_type;

        uint blk_size = _dev.blk_size;
        uint len = text.byteLength();
        uint n_blocks = len / blk_size + 1;
        uint16 blocks_len = uint16(_blocks.length);

        if (_file_table.exists(index)) {
            FileMapS fm = _file_table[index];
            (storage_type, b_start, b_count) = fm.unpack();
        } else {
            b_start = blocks_len;
        }

        if (b_count == 0)
            b_count = uint16(n_blocks);
        else
            if (n_blocks > b_count) {
                b_start = blocks_len;
                b_count = uint16(n_blocks);
            }

        for (uint i = 0; i < n_blocks; i++) {
            uint idx = b_start + i;
            string text_chunk = text.substr(i * blk_size, i + 1 < n_blocks ? blk_size : len - i * blk_size);
            if (idx < blocks_len)
                _blocks[idx] = text_chunk;
            else
                _blocks.push(text_chunk);
        }
//        storage_type |= STG_PRIMARY;
    }

    /* File system initialization */
    function _make_fs() internal {
        _fs = _get_fs(1, "sysfs", ["bin", "dev", "etc", "home", "mnt", "proc", "sys", "usr"]);
        Session session = Session(1, SUPER_USER, SUPER_USER_GROUP, ROOT_DIR);
        _create_subdirs(session, ROOT_DIR + 4, ["boris", "guest", "ivan"]);
        _create_subdirs(session, ROOT_DIR + 7, ["dev"]);
        _create_subdirs(session, ROOT_DIR + 12, ["block", "char"]);
        _dev = DeviceInfo(FT_BLKDEV, 1, "BlockDevice", 1024, 100, address(this));
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

    function _get_fd_table() internal pure returns (mapping (uint16 => FileS) fd_table) {
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
        _users[SUPER_USER] = UserInfo(SUPER_USER_GROUP, "root", "root");
        _users[REG_USER] = UserInfo(REG_USER_GROUP, "boris", "staff");
        _users[REG_USER + 1] = UserInfo(REG_USER_GROUP, "ivan", "staff");
        _users[GUEST_USER] = UserInfo(GUEST_USER_GROUP, "guest", "guest");
    }

    function _init_readers() internal {
        _readers = [
            address.makeAddrStd(0, 0x47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40),
            address.makeAddrStd(0, 0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9),
            address.makeAddrStd(0, 0x48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec),
            address.makeAddrStd(0, 0x4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d),
            address.makeAddrStd(0, 0x430dd570de5398dbc2319979f5ba4aa99d5254e5382d3c344b985733d141617b)];
        for (address addr: _readers)
            ICacheFS(addr).flush_fs_cache{value: 0.02 ton, flag: 1}();
    }

    function init() external accept {
        _make_fs();
        _init_users();
        _spawn_processes();
        this.init2();
    }

    function init2() external accept {
        _init_readers();
    }

    /* Fully update a file system information on a file system cache device */
    function query_fs_cache() external override view accept {
        ICacheFS(msg.sender).update_fs_cache{value: 0.1 ton, flag: 1}(_fs.sb, _dev, _proc, _users, _groups, _fs.inodes);
    }

    function _update_inodes(mapping (uint16 => Inode) inn) internal view {
        for (address addr: _readers)
            ICacheFS(addr).update_fs_cache{value: 0.1 ton, flag: 1}(_fs.sb, _dev, _proc, _users, _groups, inn);
    }

    function _update_inodes_set(uint16[] indices) internal view {
        mapping (uint16 => Inode) inn;
        uint count;
        for (uint16 i: indices)
            if (_fs.inodes.exists(i)) {
                inn[i] = _fs.inodes[i];
                count++;
            }
        _update_inodes(inn);
    }

    /* Superblock and index node housekeeping helpers */
    function _claim_inodes(uint inode_count, uint block_count) internal {
        uint16 n_inodes = uint16(inode_count);
        uint16 n_blocks = uint16(block_count);
        _fs.ic += n_inodes;
        SuperBlock sb = _fs.sb;
        sb.inode_count += n_inodes;
        sb.block_count += n_blocks;
        sb.free_blocks -= n_blocks;
        sb.free_inodes -= n_inodes;
        sb.last_write_time = now;
        sb.lifetime_writes++;
        _fs.sb = sb;
    }

}
