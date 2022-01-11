pragma ton-solidity >= 0.51.0;

import "../include/Internal.sol";

interface IExportFS {
    function rpc_mountd(uint16 mount_point) external;
}

interface ISourceFS {
    function mount_dir(uint16 mount_point_index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external;
    function request_mount(address source, uint16 mount_point, uint16 options) external view;
}
