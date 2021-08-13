pragma ton-solidity >= 0.48.0;

import "INode.sol";

struct UserGroup {
    uint16 file_permissions;
    uint16 dir_permissions;
    string name;
}

struct User {
    uint16 group_id;
    string name;
    uint16 home_dir;
}

interface ISync {
    function update_users(uint16[] init_ids, mapping (uint16 => UserGroup) ugroups, mapping (uint16 => User) users, uint16 ino_counter) external;
    function update_inodes(mapping (uint16 => INodeS) inodes, mapping (uint16 => INodeTimeS) ino_ts) external;
    function update_children(mapping (uint16 => uint16[]) children) external;
    function add(uint16 pino, INodeS[] inodes) external;
    function update(uint16 pino, INodeS[] inodes) external;
    function rem_dirents(uint16 pino_rem, uint16[] rem) external;
    function change_attrs(uint16[] ids, INodeS[] inodes) external;
    function update_time(uint16[] ids, INodeTimeS[] ino_tss) external;
}
