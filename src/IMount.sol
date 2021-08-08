pragma ton-solidity >= 0.48.0;

import "INode.sol";
interface IMount {
    function mount_dir(uint16 mount_point, INodeS[] inodes) external;
}
