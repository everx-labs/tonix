pragma ton-solidity >= 0.49.0;

import "INode.sol";

/* Base device contract */
abstract contract Device is INode {

    uint8 constant BLK_DEVICE = 1;

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

    uint8 _dc;

    mapping (uint16 => ProcessInfo) public _proc;
    mapping (uint16 => UserInfo) public _users;

    /* Store the file system cache information provided by a host device */
    /*function update_fs_cache(SuperBlock sb, DeviceInfo[] devices, mapping (uint16 => ProcessInfo) processes, mapping (uint16 => UserInfo) users, mapping (uint16 => INodeS) inodes) external accept {
        for ((uint16 i, INodeS inode): inodes)
            _fs.inodes[i] = inode;
        _dev = devices;
        _proc = processes;
        _users = users;
        _fs.sb = sb;
    }*/

    /* Drop an existing file system cache and request a fresh one from the host device */
    /*function flush_fs_cache() external accept {
        _sync_fs_cache();
    }*/

    /* Mount file system */
    /*function mount_fs(string path, uint16 options, SuperBlock sb, DeviceInfo dev, mapping (uint16 => INodeS) inodes, uint16 target) external accept {
        FileSystem fs = FileSystem("Mounted " + sb.file_system_OS_type, TMPFS, sb, ROOT_DIR + 1);
        fs.inodes = inodes;
//        _mnt.push(Mount(fs, dev, path, options, target));
        _fs.inodes[target] = _add_dir_entry(_fs.inodes[target], sb.first_inode, sb.file_system_OS_type, FT_SYMLINK);
    }*/

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _fs);
    }

    /* File system helpers */
    function _dump_fs(uint8 level, FileSystem fs) internal pure returns (string out) {
        for ((uint16 i, INodeS ino): fs.inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint32 file_size, uint16 n_links, , , string file_name, string[] text_data) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} SZ {} NL {}\n", i, file_name, mode, owner_id, group_id, file_size, n_links));
            if (level > 0 && ((mode & S_IFMT) == S_IFDIR || (mode & S_IFMT) == S_IFLNK) || level > 1)
                for (string s: text_data)
                    out.append(s + "\n");
        }
    }

    /*function _mount_fs(FileSystem fs, DeviceInfo dev, string path, uint16 options, uint16 target) internal {
        _mnt.push(Mount(fs, dev, path, options, target));
    }*/

    /*function _sync_fs_cache() internal {
        delete _fs;
//        delete _mnt;
        address bdev = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
        Device(bdev).query_fs_cache();
    }*/

    /* Superblock and index node housekeeping helpers */
    function _claim_inodes(uint16 n) internal {
        _fs.ic += n;
        SuperBlock sb = _fs.sb;
        sb.inode_count += n;
        sb.free_inodes -= n;
        sb.last_write_time = now;
        sb.lifetime_writes++;
        _fs.sb = sb;
    }

    /* Directory entry helpers */
    function _append_dir_entry(uint16 dir_idx, uint16 ino, string file_name, uint8 file_type) internal {
        INodeS inode_dir = _fs.inodes[dir_idx];
        string dirent = _dir_entry_line(ino, file_name, file_type);
        inode_dir.text_data.push(dirent);
        inode_dir.file_size += uint32(dirent.byteLength());
        inode_dir.n_links++;
        _fs.inodes[dir_idx] = inode_dir;
    }
}
