pragma ton-solidity >= 0.49.0;

import "Device.sol";

abstract contract ExportFS is Device {
    function rpc_mountd_exports() external view {}
}

/* Base contract for the file system importing devices */
abstract contract ImportFS is Device {

    Mount[] _imports;

    /* Mount a file system separately from the primary file system */
    function mount_fs_as_import(string path, uint16 options, SuperBlock sb, DeviceInfo dev, mapping (uint16 => INodeS) inodes, uint16 target) external accept {
        FileSystem fs = FileSystem("Mounted " + sb.file_system_OS_type, TMPFS, sb, ROOT_DIR + 1);
        fs.inodes = inodes;
        _imports.push(Mount(fs, dev, path, options, target));
        _fs.inodes[target] = _add_dir_entry(_fs.inodes[target], sb.first_inode, sb.file_system_OS_type, FT_SYMLINK);
    }

    /* Print a debugging infomation about the imported file ssytems */
    function dump_imports() external view returns (string out) {
        for (Mount m: _imports)
            for (( , INodeS inode): m.fs.inodes) {
                out.append("=== " + inode.file_name + " ===\n");
                for (string s: inode.text_data)
                    out.append(s + "\n");
            }
    }

}


