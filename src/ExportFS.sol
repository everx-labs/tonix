pragma ton-solidity >= 0.49.0;

import "INode.sol";
import "Commands.sol";
import "ICache.sol";

/* Base contract for the file system exporting devices */
abstract contract ExportFS is INode, Commands, IExportFS {

    SuperBlock[] public _sb_exports;
    FileSystem _export_fs;

    /* Respond to a request to export a set of index nodes to the specified mount point directory at the primary file system */
    function rpc_mountd(uint16 export_id, uint16 mount_point) external override view accept {
        if (export_id <= _sb_exports.length) {
            SuperBlock esb = _sb_exports[export_id - 1];
            INodeS[] inodes;
            for (uint16 i = esb.first_inode; i < esb.first_inode + esb.inode_count; i++)
                inodes.push(_export_fs.inodes[i]);
            ISourceFS(msg.sender).mount_dir{value: 0.1 ton, flag: 1}(mount_point, inodes);
        }
    }

    /* Respond to the specific request to export a particular file system as a distinct entity */
    function rpc_mountd_exports() external override view accept {
        for (uint i = 0; i < _sb_exports.length; i++) {
            SuperBlock sb = _sb_exports[i];
            uint16 start = sb.first_inode;
            uint16 count = sb.inode_count;
            INodeS[] inodes;
            for (uint16 j = start; j < start + count; j++)
                inodes.push(_export_fs.inodes[j]);
//            IImportFS(msg.sender).mount_fs_as_import{value: 0.1 ton, flag: 1}("/mnt", 0, sb, inodes, ROOT_DIR + 3);
            IImportFS(msg.sender).mount_dir_as_import{value: 0.1 ton, flag: 1}(ROOT_DIR + 4, inodes);
        }
    }

    /* Print an internal debugging information about the exported file system state */
    function dump_export_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _export_fs);
    }

    function _add_export_file(uint8 ft, string name, string[] contents) internal {
        uint16 counter = _export_fs.ic++;
        _export_fs.inodes[counter] = _get_any_node(ft, SUPER_USER, SUPER_USER_GROUP, name, contents);
    }

    function _get_export_sb(uint16 first_inode, uint16 inode_count, string path) internal pure returns (SuperBlock) {
        return SuperBlock(true, true, path, inode_count, 0, 0, 0, DEF_BLOCK_SIZE, now, now, now, 0, MAX_MOUNT_COUNT, 0, first_inode, DEF_INODE_SIZE);
    }
}


