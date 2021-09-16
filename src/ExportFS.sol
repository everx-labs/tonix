pragma ton-solidity >= 0.49.0;

import "INode.sol";
import "Commands.sol";
import "ICache.sol";

/*abstract contract ImportFS {
    function mount_fs_as_import(string path, uint16 options, SuperBlock sb, DeviceInfo dev, mapping (uint16 => INodeS) inodes, uint16 target) external {}
    function mount_dir(uint16 target, INodeS[] inodes) external {}
}*/

/* Base contract for the file system exporting devices */
abstract contract ExportFS is INode, Commands, IExportFS {

    SuperBlock[] public _sb_exports;
    FileSystem _export_fs;
    DeviceInfo _export_dev;

    /* Respond to a request to export a set of index nodes to the specified mount point directory at the primary file system */
    function rpc_mountd(uint16 export_id, uint16 mount_point) external override view accept {
        if (export_id <= _sb_exports.length) {
            SuperBlock esb = _sb_exports[export_id - 1];
            INodeS[] inodes;
            for (uint16 i = esb.first_inode; i < esb.first_inode + esb.inode_count; i++)
                inodes.push(_export_fs.inodes[i]);
//            ExportFS(msg.sender).mount_dir{value: 0.1 ton}(mount_point, inodes);
            IImportFS(msg.sender).mount_dir{value: 0.1 ton}(mount_point, inodes);
        }
    }

    /* Respond to the specific request to export a particular file system as a distinct entity */
    function rpc_mountd_exports() external override view accept {
        for (uint i = 0; i < _sb_exports.length; i++) {
            SuperBlock sb = _sb_exports[i];
            uint16 start = sb.first_inode;
            uint16 count = sb.inode_count;
            mapping (uint16 => INodeS) inodes;
            for (uint16 j = start; j < start + count; j++)
                inodes[j] = _export_fs.inodes[j];
            IImportFS(msg.sender).mount_fs_as_import{value: 0.1 ton, flag: 1}("/mnt", 0, sb, _export_dev, inodes, ROOT_DIR + 3);
        }
    }

    /* Respond to a request to export all relevant the file system as a distinct entity */
    function rpc_mountd_all() external override view accept {
        IImportFS(msg.sender).mount_fs_as_import{value: 0.1 ton, flag: 1}("/mnt", 0, _export_fs.sb, _export_dev, _export_fs.inodes, ROOT_DIR + 3);
    }

    function _add_reg_files(uint16 pino, INodeS[] inodes) internal {
        uint16 len = uint16(inodes.length);
        uint16 counter = _export_fs.ic;
        for (uint16 i = 0; i < len; i++) {
            INodeS inode = inodes[i];
            _export_fs.inodes[counter + i] = inode;
//            _export_fs.inodes[pino] = _add_dir_entry(_export_fs.inodes[pino], counter + i, inodes[i].file_name, FT_REG_FILE);
//            _export_fs.inodes[pino] = _add_dir_entry(_export_fs.inodes[pino], counter + i, inodes[i].file_name, FT_REG_FILE);
        }
        _export_fs.ic += len;
    }

    function _add_export_files(INodeS[] inodes) internal {
        for (INodeS inode: inodes)
            _export_fs.inodes[_export_fs.ic++] = inode;
    }

    function _add_export_file(uint8 ft, string name, string[] contents) internal {
        _export_fs.inodes[_export_fs.ic++] = _get_any_node(ft, name, contents);
    }

    function _create_device(uint16 parent, DeviceInfo dev) internal {
        uint16 counter = _export_fs.ic++;
        _export_dev = dev;
        uint8 ft = dev.major_id;
        INodeS inode = ft == FT_BLKDEV ? _get_block_device_node(dev) : _get_character_device_node(dev);
        _export_fs.inodes[counter] = inode;
        _export_fs.inodes[parent] = _add_dir_entry(_export_fs.inodes[parent], counter, dev.name, FT_BLKDEV);
    }

    function _get_export_sb(uint16 first_inode, uint16 inode_count, string path) internal pure returns (SuperBlock) {
        return SuperBlock(true, true, path, inode_count, 0, 0, 0, DEF_BLOCK_SIZE, now, now, now, 0, MAX_MOUNT_COUNT, 0, first_inode, DEF_INODE_SIZE);
    }


}


