pragma ton-solidity >= 0.49.0;

import "Device.sol";

abstract contract ImportFS {
    function mount_fs_as_import(string path, uint16 options, SuperBlock sb, DeviceInfo dev, mapping (uint16 => INodeS) inodes, uint16 target) external {}
}

/* Base contract for the file system exporting devices */
abstract contract ExportFS is Device {

    SuperBlock[] public _sb_exports;

    /* Mount a set of index nodes to the specified mount point of the primary file system */
    function mount_dir(uint16 pino, INodeS[] inodes) external accept {
        _add_reg_files(pino, inodes);
    }

    /* Respond to a request to export a set of index nodes to the specified mount point directory at the primary file system */
    function rpc_mountd(uint16 export_id, uint16 mount_point) external view accept {
        if (export_id <= _sb_exports.length) {
            SuperBlock esb = _sb_exports[export_id - 1];
            INodeS[] inodes;
            for (uint16 i = esb.first_inode; i < esb.first_inode + esb.inode_count; i++)
                inodes.push(_fs.inodes[i]);
            ExportFS(msg.sender).mount_dir{value: 0.1 ton}(mount_point, inodes);
        }
    }

    /* Respond to the specific request to export a particular file system as a distinct entity */
    function rpc_mountd_exports() external view {
        for (uint i = 0; i < _sb_exports.length; i++) {
            SuperBlock sb = _sb_exports[i];
            uint16 start = sb.first_inode;
            uint16 count = sb.inode_count;
            mapping (uint16 => INodeS) inodes;
            for (uint16 j = start; j < start + count; j++)
                inodes[j] = _fs.inodes[j];
            ImportFS(msg.sender).mount_fs_as_import{value: 0.1 ton, flag: 1}("/mnt", 0, sb, _dev[0], inodes, ROOT_DIR + 3);
        }
    }

    /* Respond to a request to export all relevant the file system as a distinct entity */
    function rpc_mountd_all() external view {
        ImportFS(msg.sender).mount_fs_as_import{value: 0.1 ton, flag: 1}("/mnt", 0, _fs.sb, _dev[0], _fs.inodes, ROOT_DIR + 3);
    }

    function _add_reg_files(uint16 pino, INodeS[] inodes) internal {
        uint16 len = uint16(inodes.length);
        uint16 counter = _fs.ic;
        for (uint16 i = 0; i < len; i++) {
            _fs.inodes[counter + i] = inodes[i];
            _append_dir_entry(pino, counter + i, inodes[i].file_name, FT_REG_FILE);
        }
        _claim_inodes(len);
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

    function _get_fs(uint8 fs_type, string fs_uuid, string[] root_subdirs) internal pure returns (FileSystem fs) {
        SuperBlock sb = SuperBlock(true, true, fs_uuid, 0, 0, MAX_INODES, MAX_BLOCKS, DEF_BLOCK_SIZE, now, now, now, 0, MAX_MOUNT_COUNT, 1, INODES + 1, DEF_INODE_SIZE);
        uint16 root_subdirs_count = uint16(root_subdirs.length);

        fs = FileSystem(fs_uuid, fs_type, sb, ROOT_DIR + 1);
        INodeS root_dir = _get_dir_node(ROOT_DIR, ROOT_DIR, SUPER_USER, SUPER_USER_GROUP, "");

        uint16 len = uint16(root_subdirs.length);
        for (uint16 i = 0; i < len; i++) {
            fs.inodes[ROOT_DIR + 1 + i] = _get_dir_node(ROOT_DIR + 1 + i, ROOT_DIR, SUPER_USER, SUPER_USER_GROUP, root_subdirs[i]);
            root_dir = _add_dir_entry(root_dir, ROOT_DIR + 1 + i, root_subdirs[i], FT_DIR);
        }
        fs.inodes[ROOT_DIR] = root_dir;
        fs.ic += root_subdirs_count;
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
        _append_dir_entry(parent, counter, dev.name, FT_BLKDEV);
    }

    function _get_export_sb(uint16 first_inode, uint16 inode_count, string path) internal pure returns (SuperBlock) {
        return SuperBlock(true, true, path, inode_count, 0, 0, 0, DEF_BLOCK_SIZE, now, now, now, 0, MAX_MOUNT_COUNT, 0, first_inode, DEF_INODE_SIZE);
    }


}


