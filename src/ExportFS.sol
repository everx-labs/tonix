pragma ton-solidity >= 0.49.0;

import "Internal.sol";
import "Commands.sol";
import "ICache.sol";

/* Base contract for the file system exporting devices */
abstract contract ExportFS is Internal, Commands, IExportFS {

    SuperBlock[] public _sb_exports;
    FileSystem _export_fs;

    uint16 constant MAX_EXPORT_INODES = 100;
    uint16 constant MAX_EXPORT_BLOCKS = 200;

    /* Respond to a request to export a set of index nodes to the specified mount point directory at the primary file system */
    function rpc_mountd(uint16 export_id, uint16 mount_point) external override accept {
        if (export_id <= _sb_exports.length) {
            SuperBlock esb = _sb_exports[export_id - 1];
            Inode[] inodes;
            for (uint16 i = esb.first_inode; i < esb.first_inode + esb.inode_count; i++)
                inodes.push(_export_fs.inodes[i]);
            ISourceFS(msg.sender).mount_dir{value: 0.1 ton, flag: 1}(mount_point, inodes);
            esb.mount_count++;
            esb.last_mount_time = now;
            _sb_exports[export_id - 1] = esb;
        }
    }

    function query_export_node(string s_export, string s_file_name) external override accept {
        for (SuperBlock sb: _sb_exports)
            if (sb.file_system_OS_type == s_export)
                for (uint16 i = 0; i < sb.inode_count; i++)
                    if (_export_fs.inodes[sb.first_inode + i].file_name == s_file_name) {
                        IImport(msg.sender).update_node{value: 0.02 ton, flag: 1}(_export_fs.inodes[sb.first_inode + i]);
                        break;
                    }
    }

    /* Print an internal debugging information about the exported file system state */
    function dump_export_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _export_fs);
    }

    function _get_export_sb(uint16 first_inode, uint16 inode_count, string path) internal pure returns (SuperBlock) {
        return SuperBlock(true, true, path, inode_count, inode_count, MAX_EXPORT_INODES - inode_count, MAX_EXPORT_BLOCKS - inode_count, DEF_BLOCK_SIZE, now, 0, now, 0, MAX_MOUNT_COUNT, 1, first_inode, DEF_INODE_SIZE);
    }
}


