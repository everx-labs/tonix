pragma ton-solidity >= 0.49.0;

import "Device.sol";
import "ICache.sol";

/* Base contract for the file system importing devices */
abstract contract ImportFS is IImportFS, Device {

//    Mount[] _imports;
    FileSystem _import_fs;

    /* Mount a set of index nodes to the specified mount point of the primary file system */
    function mount_dir_as_import(uint16 mount_point_index, INodeS[] inodes) external override accept {
        uint16 n_files = uint16(inodes.length);
        uint16 counter = _import_fs.ic;
        INodeS mount_point = _import_fs.inodes[mount_point_index];
        for (uint16 i = 0; i < n_files; i++) {
            INodeS inode = inodes[i];
            _import_fs.inodes[counter + i] = inode;
            mount_point = _add_dir_entry(mount_point, counter + i, inode.file_name, _mode_to_file_type(inode.mode));
        }
        _import_fs.inodes[mount_point_index] = mount_point;
        _import_fs.ic += n_files;
//        _claim_inodes(n_files);
//        _dir_mounted(mount_point_index, n_files);
    }

    /* Print a debugging infomation about the imported file ssytems */
    function dump_imports() external view returns (string out) {
        /*out.append(">>> MOUNTS <<<\n");
        for (Mount m: _imports)
            for (( , INodeS inode): m.fs.inodes) {
                out.append("=== " + inode.file_name + " ===\n");
                for (string s: inode.text_data)
                    out.append(s + "\n");
            }*/

        out.append(">>> IMPORT_FS <<<\n");
        for (( , INodeS inode): _import_fs.inodes) {
            out.append("=== " + inode.file_name + " ===\n");
            for (string s: inode.text_data)
                out.append(s + "\n");
        }

    }

}


