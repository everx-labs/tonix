pragma ton-solidity >= 0.49.0;
import "INode.sol";
interface IImportFS {
    function mount_fs_as_import(string path, uint16 options, SuperBlock sb, DeviceInfo dev, mapping (uint16 => INodeS) inodes, uint16 target) external;
    function mount_dir(uint16 target, INodeS[] inodes) external;
}

interface IExportFS {
    function rpc_mountd_exports() external view;
    function rpc_mountd_all() external view;
    function rpc_mountd(uint16 export_id, uint16 mount_point) external view;
}

interface ICacheFS {
    function update_fs_cache(SuperBlock sb, DeviceInfo device, mapping (uint16 => ProcessInfo) processes, mapping (uint16 => UserInfo) users, mapping (uint16 => INodeS) inodes) external;
}

interface ISourceFS {
    function query_fs_cache() external view;
}
