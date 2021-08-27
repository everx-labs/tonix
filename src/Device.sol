pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "INode.sol";

abstract contract Device is INode {

    uint16 constant DEF_TEXT_BLOCK_SIZE = 1024;
    uint16 constant DEF_BIN_BLOCK_SIZE = 4096;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 128;
    uint16 constant MAX_BLOCKS = 10000;
    uint16 constant MAX_INODES = 10000;

    uint8 constant BLK_DEVICE = 1;

    FileSystem public _fs;
    Mount[] public _mnt;
    SuperBlock[] public _sb_exports;
    uint16 _ic;
    uint16 _dc;

    DeviceInfo[] public _dev;
    mapping (uint16 => string[]) public _cdata;

    DeviceFreeBlocks[] public _char_dev;

    function _get_export_sb(uint16 first_inode, uint16 inode_count) internal pure returns (SuperBlock sb) {
        sb = SuperBlock(true, true, "Tonix", inode_count, 0, 0, 0, DEF_TEXT_BLOCK_SIZE,
            now, now, now, 0, MAX_MOUNT_COUNT, 0, first_inode, DEF_INODE_SIZE);
    }

    function rpc_mountd(uint16 export_id, uint16 mount_point) external view accept {
        if (export_id <= _sb_exports.length) {
            SuperBlock esb = _sb_exports[export_id - 1];
            uint64 val = uint64(esb.inode_count) * 0.01 ton + 0.1 ton;
            INodeS[] inodes;
            for (uint16 i = esb.first_inode; i < esb.first_inode + esb.inode_count; i++)
                inodes.push(_fs.inodes[i]);
            Device(msg.sender).mount_dir{value: val}(mount_point, inodes);
        }
    }

    function mount_dir(uint16 pino, INodeS[] inodes) external accept {
        _add_reg_files(pino, inodes);
    }

    function rpc_mountd_all() external view {
        uint64 val = uint64(_fs.sb.inode_count) * 0.01 ton + 0.1 ton;
        Device(msg.sender).mount_fs{value: val, flag: 1}(_fs.sb, _dev[0], _fs.inodes);
    }

    function mount_fs(SuperBlock sb, DeviceInfo dev, mapping (uint16 => INodeS) inodes) external accept {
        FileSystem fs = FileSystem("Mounted " + dev.name, dev.device_type, sb);
        fs.inodes = inodes;
        _mnt.push(Mount(fs, dev));
    }

    function update_fs_cache(SuperBlock sb, DeviceInfo[] devices, Mount[] mounts, mapping (uint16 => INodeS) inodes) external accept {
        for ((uint16 i, INodeS inode): inodes)
            _fs.inodes[i] = inode;
        _dev = devices;
        _mnt = mounts;
        _fs.sb = sb;
    }

    function query_fs_cache() external view accept {
        uint64 val = uint64(_fs.sb.inode_count) * 0.01 ton + 0.1 ton;
        Device(msg.sender).update_fs_cache{value: val, flag: 1}(_fs.sb, _dev, _mnt, _fs.inodes);
    }

    function flush_fs_cache() external accept {
        _sync_fs_cache();
    }

    function _sync_fs_cache() internal {
        delete _ic;
        delete _fs;
        delete _mnt;
        delete _dev;
        address bdev = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
        Device(bdev).query_fs_cache();
    }

    function _get_device_info(uint8 device_type, uint16 id, string name, uint16 blk_size, uint16 n_blocks) internal pure returns (DeviceInfo) {
        return DeviceInfo(device_type, id, name, blk_size, n_blocks);
    }

    function _create_fs(string uuid, uint8 fs_type, string[] root_subdirs) internal {
        SuperBlock sb = SuperBlock(true, true, "Tonix", 0, 0, MAX_INODES, MAX_BLOCKS, DEF_TEXT_BLOCK_SIZE,
            now, now, now, 0, 0, 0, INODES, DEF_INODE_SIZE);
        _fs = FileSystem(uuid, fs_type, sb);
        (INodeS root_dir, ) = _get_dir_node(ROOT_DIR, ROOT_DIR, SUPER_USER, SUPER_USER_GROUP, "");
        _fs.inodes[ROOT_DIR] = root_dir;
        _ic = ROOT_DIR + 1;
        _create_subdirs(ROOT_DIR, root_subdirs);
    }

    function _add_primary_device(string name, uint16 blk_size, uint16 n_blocks) internal {
        _create_device(ROOT_DIR + 1, _get_device_info(BLK_DEVICE, _dc++, name, blk_size, n_blocks));
    }

    function _add_dir_entries(uint16 pino, uint16 n, string text) internal {
        INodeS res = _fs.inodes[pino];
        res.text_data.append(text);
        res.file_size = uint32(res.text_data.byteLength());
        res.n_links += n;
        _fs.inodes[pino] = res;

        _ic += n;

        SuperBlock sb = _fs.sb;
        sb.inode_count += n;
        sb.free_inodes -= n;
        sb.last_write_time = now;
        sb.lifetime_writes++;
        _fs.sb = sb;
    }

    function _create_subdirs(uint16 pino, string[] files) internal returns (uint16) {
        uint16 len = uint16(files.length);
        uint16 counter = _ic;
        string text;
        string dirent;
        for (uint16 i = 0; i < len; i++) {
            (_fs.inodes[counter + i], dirent) = _get_dir_node(counter + i, pino, SUPER_USER, SUPER_USER_GROUP, files[i]);
            text.append(dirent);
        }
        _add_dir_entries(pino, len, text);
        return _ic - 1;
    }

    function _create_device(uint16 pino, DeviceInfo dev) internal returns (uint16 counter) {
        counter = _ic;
        _dev.push(dev);
        _char_dev.push(DeviceFreeBlocks(0, dev.n_blocks, dev.n_blocks));
        _fs.inodes[counter] = _get_block_device_node(dev);
        string text = format("{}\t{}\n", dev.name, counter);
        _add_dir_entries(pino, 1, text);
        return _ic - 1;
    }

    function _add_reg_files(uint16 pino, INodeS[] inodes) internal returns (uint16 start, uint16 count) {
        start = _ic;
        count = uint16(inodes.length);
        string text;
        for (uint16 i = 0; i < count; i++) {
            _fs.inodes[start + i] = inodes[i];
            text.append(_write_de(start + i, inodes[i].file_name, FT_REG_FILE));
        }
        _add_dir_entries(pino, count, text);
    }

}
