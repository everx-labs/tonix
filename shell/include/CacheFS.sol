pragma ton-solidity >= 0.51.0;

import "ICache.sol";
import "SyncFS.sol";

/* Base contract for the file system importing devices */
abstract contract CacheFS is ICacheFS, SyncFS {

    /* Store the file system cache information provided by a host device */
    function update_fs_cache(mapping (uint16 => ProcessInfo) processes, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups,
                                mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external override accept {
        for ((uint16 i, Inode inode): inodes)
            _inodes[i] = inode;
        for ((uint16 i, bytes bts): data)
            _data[i] = bts;

        _proc = processes;
        _users = users;
        _groups = groups;
    }

    function update_cache(uint8 mode, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external override accept {
        if (mode == 1) {
            mapping (uint16 => Inode) l_inodes = _inodes;
            for ((uint16 i, Inode inode): inodes)
                l_inodes[i] = inode;
            _inodes = l_inodes;
        } else if (mode == 2) {
            for ((uint16 i, Inode inode): inodes)
                _inodes[i] = inode;
        } else if (mode == 3) {
            for ((uint16 i, Inode inode): inodes)
                _inodes[i] = inode;
            for ((uint16 i, bytes bts): data)
                _data[i] = bts;
        }
    }

    function _init() internal override accept {
        _sync_fs_cache();
    }

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _inodes);
    }

    function flush_fs_cache() external override accept {
        _sync_fs_cache();
    }

    function _sync_fs_cache() internal {
        delete _inodes;
        ISourceFS(_source).query_fs_cache();
    }

}


