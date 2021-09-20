pragma ton-solidity >= 0.49.0;

import "INode.sol";

/* Base device contract */
abstract contract Device is INode {

    uint16 constant MOUNT_NONE          = 0;
    uint16 constant MOUNT_DIR           = 1;
    uint16 constant MOUNT_DIR_AS_IMPORT = 2;
    uint16 constant MOUNT_FS_AS_IMPORT  = 3;
    uint16 constant MOUNT_OVERLAY       = 4;
    uint16 constant QUERY_FS_CACHE      = 5;

    uint8 constant ROOTFS   = 1;
    uint8 constant SYSFS    = 2;
    uint8 constant TMPFS    = 3;
    uint8 constant PROCFS   = 4;
    uint8 constant EXT4     = 5;
    uint8 constant OVERLAY  = 6;
    uint8 constant CGROUP   = 7;
    uint8 constant _9P      = 8;
    uint8 constant DEVTMPFS = 9;
    uint8 constant DEVPTS   = 10;

    FileSystem _fs;

    mapping (uint16 => ProcessInfo) public _proc;
    mapping (uint16 => UserInfo) public _users;

    /* Superblock and index node housekeeping helpers */
    function _claim_inodes(uint16 n) internal {
        _fs.ic += n;
        SuperBlock sb = _fs.sb;
        sb.inode_count += n;
        sb.block_count += n;
        sb.free_blocks -= n;
        sb.free_inodes -= n;
        sb.last_write_time = now;
        sb.lifetime_writes++;
        _fs.sb = sb;
    }

}
