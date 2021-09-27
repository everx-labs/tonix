pragma ton-solidity >= 0.49.0;

import "Internal.sol";

interface IExportFS {
    function rpc_mountd(uint16 export_id, uint16 mount_point) external;
    function query_export_node(string export_volume, string file_name) external;
}

interface ICacheFS {
    function flush_fs_cache() external;
    function update_fs_cache(SuperBlock sb, DeviceInfo device, mapping (uint16 => ProcessInfo) processes, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups, mapping (uint16 => Inode) inodes) external;
}

interface IImport {
    function update_node(Inode inode) external;
}

interface ISourceFS {
    function query_fs_cache() external view;
    function update_nodes(Session session, IOEvent[] ios) external;
//    function update_user_info(Session session, IOEvent[] ios, uint16 options, mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups) external;
    function update_user_info(Session session, UserEvent[] ues) external;
    function mount_dir(uint16 target, Inode[] inodes) external;
    function request_mount(address source, uint16 export_id, uint16 mount_point, uint16 options) external view;
}

interface IUserTables {
    function update_tables(mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups,
        uint16 reg_u, uint16 sys_u, uint16 reg_g, uint16 sys_g) external;
}
