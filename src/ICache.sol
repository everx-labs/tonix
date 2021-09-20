pragma ton-solidity >= 0.49.0;
import "INode.sol";
interface IImportFS {
    function mount_dir_as_import(uint16 mount_point_index, INodeS[] inodes) external;
}

interface IExportFS {
    function rpc_mountd_exports() external view;
    function rpc_mountd(uint16 export_id, uint16 mount_point) external view;
}

interface ICacheFS {
    function update_fs_cache(SuperBlock sb, DeviceInfo device, mapping (uint16 => ProcessInfo) processes, mapping (uint16 => UserInfo) users, mapping (uint16 => INodeS) inodes) external;
}

interface ISourceFS {
    function query_fs_cache() external view;
    function mount_dir(uint16 target, INodeS[] inodes) external;
    function request_mount(address source, uint16 export_id, uint16 mount_point, uint16 options) external view;
}
