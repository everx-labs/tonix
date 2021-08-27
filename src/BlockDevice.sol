pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "SyncFS.sol";

contract BlockDevice is SyncFS {
    address[3] _readers;

    function _get_event_file_type(uint8 iotype) internal pure returns (uint8) {
        if (iotype == IO_WR_COPY) return FT_REG_FILE;
        if (iotype == IO_MKFILE) return FT_REG_FILE;
        if (iotype == IO_ALLOCATE) return FT_REG_FILE;
        if (iotype == IO_MKDIR) return FT_DIR;
        if (iotype == IO_SYMLINK) return FT_SYMLINK;
        return FT_UNKNOWN;
    }

    function _is_add(uint8 t) internal pure returns (bool) {
        return t == IO_WR_COPY || t == IO_MKFILE || t == IO_ALLOCATE || t == IO_MKDIR || t == IO_SYMLINK;
    }

    function _is_update(uint8 t) internal pure returns (bool) {
        return t == IO_CHATTR || t == IO_ACCESS || t == IO_PERMISSION || t == IO_UPDATE_TIME || t == IO_UNLINK || t == IO_HARDLINK;
    }

    function update_nodes(SessionS ses, IOEventS[] ios) external accept {
        for (IOEventS e: ios) {
            uint8 et = e.iotype;
            if (_is_add(et))
                _add_nodes(e.parent, _get_event_file_type(et), ses.uid, ses.gid, e.paths, e.indices);
            if (_is_update(et))
                _update_nodes(e.parent, et, ses.uid, ses.gid, e.paths, e.indices);
        }
    }

    function _update_nodes(uint16 pino, uint8 ft, uint16 /*uid*/, uint16 /*gid*/, string[] names, uint16[] indices) internal {
        uint16 len = uint16(indices.length);
        for (uint16 i = 0; i < len; i++) {
            if (ft == IO_CHATTR) {
                _fs.inodes[indices[i]].owner_id = _fs.inodes[pino].owner_id;
                _fs.inodes[indices[i]].group_id = _fs.inodes[pino].group_id;
            }
            if (ft == IO_ACCESS)
                _fs.inodes[indices[i]].accessed_at = _fs.inodes[pino].accessed_at;
            if (ft == IO_PERMISSION)
                _fs.inodes[indices[i]].mode = _fs.inodes[pino].mode;
            if (ft == IO_UPDATE_TIME) {
                _fs.inodes[indices[i]].accessed_at = _fs.inodes[pino].accessed_at;
                _fs.inodes[indices[i]].modified_at = _fs.inodes[pino].modified_at;
                _fs.inodes[indices[i]].last_modified = _fs.inodes[pino].last_modified;
            }
            if (ft == IO_UNLINK) {
                _fs.inodes[indices[i]].n_links--;
                _fs.inodes[pino].n_links--;
                if (_fs.inodes[indices[i]].n_links == 0) {
                    this.remove_node(pino, indices[i]);
                }
            }
            if (ft == IO_HARDLINK) {
                _fs.inodes[pino].n_links++;
                _fs.inodes[pino] = _add_dir_entry(_fs.inodes[pino], indices[i], names[i], FT_REG_FILE);
            }
        }
        indices.push(pino);
        _fs.sb.last_write_time = now;
        for (address addr: _readers)
            _update_inodes_set(addr, indices);
    }

    function remove_node(uint16 parent, uint16 victim) external accept {
        delete _fs.inodes[victim];
        if (_fs.inodes[parent].n_links < 2) {
            delete _fs.inodes[parent];
        }
        for (address addr: _readers)
            _update_inodes_chunk(addr, parent, victim, 1);
    }

    function _add_nodes(uint16 pino, uint8 ft, uint16 uid, uint16 gid, string[] names, uint16[] indices) internal {
        uint16 len = uint16(names.length);
        uint16 counter = _ic;
        string text;
        bool copy_contents = !indices.empty();

        for (uint16 i = 0; i < len; i++) {
            uint16 ino = counter + i;
            string s = names[i];
            if (ft == FT_DIR) {
                string dirent;
                (_fs.inodes[ino], dirent) = _get_dir_node(ino, pino, uid, gid, s);
                text.append(dirent);
            } else {
                string contents = copy_contents ? _fs.inodes[indices[i]].text_data : "";
                _fs.inodes[ino] = ft == FT_REG_FILE ? _get_file_node(uid, gid, s, contents) : _get_symlink_node(uid, gid, s, contents);
                text.append(_write_de(ino, s, ft));
            }
        }
        _add_dir_entries(pino, len, text);
        for (address addr: _readers)
            _update_inodes_chunk(addr, pino, counter, len);
    }

    function _add_reg_files_here(uint16 pino, INodeS[] inodes) internal {
        (uint16 start, uint16 count) = _add_reg_files(pino, inodes);
        for (address addr: _readers)
            this.update_inodes_chunk{value: 0.8 ton}(addr, pino, start, count);
    }

    /*function request_mount(SessionS ses, address[] addresses, string[] names) external pure accept {
        for (uint i = 0; i < addresses.length; i++)
            ExportFS(addresses[i]).export_all{value: 1 ton}(names[i], ses.wd);
    }*/

    function _write_text(uint16 id, string text) internal returns (uint16[] blocks) {
        DeviceInfo dev = _dev[id];
        DeviceFreeBlocks cdev = _char_dev[id];
        uint16 blk_size = dev.blk_size;
        uint32 len = uint32(text.byteLength());
        uint16 n_blocks = uint16(len / blk_size);
        uint16 start = cdev.next_free;
        for (uint16 i = 0; i < n_blocks; i++)
            _cdata[id].push(text.substr(i * blk_size, blk_size));
        _cdata[id].push(text.substr(n_blocks * blk_size, len - n_blocks * blk_size));
        cdev.next_free += n_blocks + 1;
        cdev.total_free -= n_blocks + 1;
        cdev.next_len -= n_blocks + 1;
        _char_dev[id] = cdev;
        for (uint16 i = start; i < start + n_blocks + 1; i++)
            blocks.push(i);
    }

    function _make_fs() internal {
        _create_fs("BlockDeviceFS", 1, ["dev", "etc", "home", "mnt", "proc", "sys", "usr"]);
        _create_subdirs(ROOT_DIR + 3, ["boris", "guest"]);
        uint16 usr_share = _create_subdirs(ROOT_DIR + 7, ["share"]);
        _create_subdirs(usr_share, ["commands", "errors"]);
        uint16 sys_dev = _create_subdirs(ROOT_DIR + 6, ["dev"]);
        _create_subdirs(sys_dev, ["block", "char"]);
        _add_primary_device("sdb", 1024, 100);
        _add_reg_files_here(ROOT_DIR + 2, _files(["fstab"], ["DataVolume\t/etc\t1\tdefaults\n"]));
//        _add_reg_files_here(ROOT_DIR + 16, _files(["1:2"], ["DataVolume\t/etc\t1\tdefaults\n"]));
    }

    function _init() internal override {
        this.init();
    }

    function init() external accept {
        _make_fs();
        address data_volume = address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb);
        Device(data_volume).rpc_mountd{value: 0.5 ton}(1, ROOT_DIR + 2);
        Device(data_volume).rpc_mountd{value: 0.3 ton}(2, ROOT_DIR + 12);
        address command_manual = address.makeAddrStd(0, 0x4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981);
        Device(command_manual).rpc_mountd{value: 1 ton}(1, ROOT_DIR + 11);
        address status_manual = address.makeAddrStd(0, 0x41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420);
        Device(status_manual).rpc_mountd{value: 1 ton}(1, ROOT_DIR + 11);
        address command_processor = address.makeAddrStd(0, 0x47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40);
        address status_reader = address.makeAddrStd(0, 0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9);
        address input_parser = address.makeAddrStd(0, 0x4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d);
        _readers = [input_parser, status_reader, command_processor /*, ISync(_file_reader)*/];
        SyncFS(input_parser).flush_fs_cache{value: 0.15 ton}();
        SyncFS(status_reader).flush_fs_cache{value: 0.15 ton}();
        SyncFS(command_processor).flush_fs_cache{value: 0.15 ton}();
    }

    function write_to_file(SessionS ses, string path, string text) external accept {
        (uint16 uid, uint16 gid, uint16 wd) = (ses.uid, ses.gid, ses.wd);
        INodeS[] inodes;
        inodes.push(_get_file_node(uid, gid, path, text));
//        _write_text(0, text);
        _add_reg_files_here(wd, inodes);
    }

    function _update_inodes_chunk(address addr, uint16 pino, uint16 start, uint16 count) internal view {
        mapping (uint16 => INodeS) inn;

        if (_fs.inodes.exists(pino))
            inn[pino] = _fs.inodes[pino];
        for (uint16 i = start; i < start + count; i++)
            if (_fs.inodes.exists(i))
                inn[i] = _fs.inodes[i];

        uint64 val = uint64(count) * 0.01 ton + 0.1 ton;
        Device(addr).update_fs_cache{value: val, flag: 1}(_fs.sb, _dev, _mnt, inn);
    }

    function _update_inodes_set(address addr, uint16[] inodes) internal view {
        mapping (uint16 => INodeS) inn;
        uint count;
        for (uint16 i: inodes)
            if (_fs.inodes.exists(i)) {
                inn[i] = _fs.inodes[i];
                count++;
            }

        uint64 val = uint64(count) * 0.01 ton + 0.1 ton;
        Device(addr).update_fs_cache{value: val, flag: 1}(_fs.sb, _dev, _mnt, inn);
    }

    function update_inodes_chunk(address addr, uint16 pino, uint16 start, uint16 count) external view accept {
        _update_inodes_chunk(addr, pino, start, count);
    }
}
