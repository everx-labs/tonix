pragma ton-solidity >= 0.49.0;

import "Device.sol";
import "ICache.sol";

/* Base contract for the file system importing devices */
abstract contract CacheFS is ICacheFS, Device {

    DeviceInfo _source_device;

    /* Store the file system cache information provided by a host device */
    function update_fs_cache(SuperBlock sb, DeviceInfo device, mapping (uint16 => ProcessInfo) processes, mapping (uint16 => UserInfo) users,
                            mapping (uint16 => INodeS) inodes) external override accept {
        for ((uint16 i, INodeS inode): inodes)
            _fs.inodes[i] = inode;

        _source_device = device;
        _proc = processes;
        _users = users;
        _fs.sb = sb;
    }

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _fs);
    }

    function _sync_fs_cache() internal {
        delete _fs;
        address bdev = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
        ISourceFS(bdev).query_fs_cache();
    }

}


