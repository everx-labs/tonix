pragma ton-solidity >= 0.48.0;

import "Commands.sol";
import "ISync.sol";
import "IBlockDevice.sol";
import "INode.sol";

abstract contract SyncFS is Commands, ISync, INode {
    uint16 _user_counter = USERS;
    uint16 _ino_counter = INODES;
    uint16 _de_counter = DIRENTS;

    uint16[] public _init_ids;

    mapping (uint16 => INodeS) public _inodes;
    mapping (uint16 => INodeTimeS) public _ino_ts;
    mapping (uint16 => UserGroup) public _ugroups;
    mapping (uint16 => User) public _users;
    mapping (uint16 => DirEntry) public _de;
    mapping (uint16 => uint16[]) public _dc;

    uint8 constant IO_WR_NEW        = 1;
    uint8 constant IO_WR_APPEND     = 2;
    uint8 constant IO_WR_OVERWRITE  = 3;
    uint8 constant IO_WR_COPY       = 4;
    uint8 constant IO_READ_TEXT     = 5;
    uint8 constant IO_READ_INODE    = 6;
    uint8 constant IO_READ_ATTRS    = 7;
    uint8 constant IO_READ_PARAMS   = 8;
    uint8 constant IO_READ_STATUS   = 9;
    uint8 constant IO_TRUNCATE      = 10;
    uint8 constant IO_ALLOCATE      = 11;
    uint8 constant IO_ERASE         = 12;
    uint8 constant IO_MKFILE        = 13;
    uint8 constant IO_MKDIR         = 14;
    uint8 constant IO_HARDLINK      = 15;
    uint8 constant IO_SYMLINK       = 16;
    uint8 constant IO_UNLINK        = 17;

    uint8 constant READ_ANY     = 1;
    uint8 constant READ_INDEX   = 2;
    uint8 constant READ_ALL     = 3;
    uint8 constant READ_MERGE   = 4;
    uint8 constant READ_TEXT    = 5;
    uint8 constant READ_INODE   = 6;
    uint8 constant READ_ATTRS   = 7;
    uint8 constant READ_PARAMS  = 8;
    uint8 constant READ_STATUS  = 9;
    uint8 constant READ_TEXT_BLK= 10;
    uint8 constant READ_FULL    = 11;
    uint8 constant READ_FIRST   = 12;
    uint8 constant READ_SECOND  = 13;
    uint8 constant READ_THIRD   = 14;

    uint8 constant INO_CREATE   = 1;
    uint8 constant INO_COPY     = 2;
    uint8 constant INO_REMOVE   = 3;
    uint8 constant INO_CHATTR   = 4;
    uint8 constant INO_ACCESS   = 5;
    uint8 constant INO_LINK     = 6;
    uint8 constant INO_UNLINK   = 7;
    uint8 constant INO_SYNC     = 8;
    uint8 constant INO_PERMISSION = 9;
    uint8 constant INO_UPDATE_TIME = 10;
    uint8 constant INO_STORE    = 11;
    uint8 constant INO_OTHER    = 12;

    /*function deploy_inodes(uint16 ino_counter, uint16 pino, mapping (uint16 => INode) inodes, mapping (uint16 => INodeTime) ino_ts) external override accept {
        for ((uint16 i, INode inode): inodes) {
            if ((inode.mode & S_IFMT) == S_IFDIR)
                _expand_inode_dir(pino, i, inode);
        }
        for ((uint16 i, INodeTime ino_t): ino_ts)
            _ino_ts[i] = ino_t;
        _ino_counter = ino_counter;
    }*/


    function _expand_inode_dir(uint16 pino, uint16 ino, INodeS inode) internal {
        _inodes[ino] = inode;
        _expand_dir_inode_dirents(pino, ino, _de_counter, inode.file_name);
        _de_counter += 3;
        _the_time_is_now(ino);
        _inodes[pino].n_links++;
    }
    function _expand_inode_reg(uint16 pino, uint16 ino, INodeS inode) internal {
        _inodes[ino] = inode;
        _expand_reg_inode_dirent(pino, ino, _de_counter++, inode.file_name);
        _the_time_is_now(ino);
        _inodes[pino].n_links++;
    }

    function _expand_dir_inode_dirents(uint16 pino, uint16 i, uint16 dei, string file_name) internal {
        (DirEntry de, DirEntry dot, DirEntry dotdot) = _get_dirents(pino, i, file_name);
        _de[dei] = de;
        _de[dei + 1] = dot;
        _de[dei + 2] = dotdot;
        _dc[pino].push(dei);
        _dc[i].push(dei + 1);
        _dc[i].push(dei + 2);
    }
    function _expand_reg_inode_dirent(uint16 pino, uint16 i, uint16 dei, string file_name) internal {
        _de[dei] = _get_dirent(pino, i, file_name);
        _dc[pino].push(dei);
    }
    function _the_time_is_now(uint16 ino) internal {
        _ino_ts[ino] = INodeTimeS(now, now, now);
    }

    function _get_dirents(uint16 pino, uint16 ino, string name) internal pure returns (DirEntry de, DirEntry dot, DirEntry dotdot) {
        de = DirEntry(ino, pino, name, FT_DIR);
        dot = DirEntry(ino, ino, ".", FT_DIR);
        dotdot = DirEntry(pino, ino, "..", FT_DIR);
    }

    function _get_dirent(uint16 pino, uint16 ino, string name) internal pure returns (DirEntry de) {
        de = DirEntry(ino, pino, name, FT_REG_FILE);
    }

    function _is_reg(uint16 id) internal view returns (bool) {
        return _inodes.exists(id) && _mode_is_reg(_inodes[id].mode);
    }

    function _is_dir(uint16 id) internal view returns (bool) {
        return _inodes.exists(id) && _mode_is_dir(_inodes[id].mode);
    }

    function _is_symlink(uint16 id) internal view returns (bool) {
        return _inodes.exists(id) && _mode_is_symlink(_inodes[id].mode);
    }

    function update_users(uint16[] init_ids, mapping (uint16 => UserGroup) ugroups, mapping (uint16 => User) users, uint16 ino_counter, uint16 de_counter) external override accept {
        _init_ids = init_ids;
        _ino_counter = ino_counter;
        _de_counter = de_counter;
        for ((uint16 i, UserGroup ug): ugroups)
            _ugroups[i] = ug;
        for ((uint16 i, User u): users)
            _users[i] = u;
    }

    function update_dirents(mapping (uint16 => DirEntry) dirents) external override accept {
        for ((uint16 i, DirEntry de): dirents)
            _de[i] = de;
    }

    function update_children(mapping (uint16 => uint16[]) children) external override accept {
        for ((uint16 i, uint16[] dc): children)
            _dc[i] = dc;
    }

    function update_inodes(mapping (uint16 => INodeS) inodes, mapping (uint16 => INodeTimeS) ino_ts) external override accept {
        for ((uint16 i, INodeS inode): inodes)
            _inodes[i] = inode;
        for ((uint16 i, INodeTimeS ino_t): ino_ts)
            _ino_ts[i] = ino_t;
    }

    function add_dirents(uint16 pino, DirEntry[] add) external override accept {
        for (DirEntry d: add) {
            uint16 dei = ++_de_counter;
            _de[dei] = d;
            _dc[pino].push(dei);
            _inodes[pino].n_links++;
            _inodes[d.inode].n_links++;
        }
    }
    function rem_dirents(uint16 pino, uint16[] rem) external override accept {
        INodeTimeS it = INodeTimeS(now, now, now);
        uint16[] pd = _dc[pino];
        for (uint i = 0; i < pd.length; i++) {
            for (uint16 dei: rem) {
                if (pd[i] == dei) {
                    _dc[pino][i] = 0;
                    _inodes[_de[dei].inode].n_links--;
                    _inodes[pino].n_links--;
                    delete _de[dei];
                    if (_inodes[pino].n_links == 0) {
                        delete _inodes[pino];
                        break;
                    }
                    continue;
                }
            }
        }
        _ino_ts[pino] = it;
    }

    function add_inodes(uint16 pino, INodeS[] inodes) external override accept {
        INodeTimeS it = INodeTimeS(now, now, now);
        for (INodeS i: inodes) {
            uint16 ino = ++_ino_counter;
            uint16 mode = i.mode;
            _inodes[ino] = i;
            uint16 dei = ++_de_counter;
            uint8 ft = _mode_is_reg(mode) ? FT_REG_FILE : _mode_is_dir(mode) ? FT_DIR : _mode_is_symlink(mode) ? FT_SYMLINK : FT_UNKNOWN;
            DirEntry d = DirEntry(ino, pino, i.file_name, ft);
            _de[dei] = d;
            _dc[pino].push(dei);
            _ino_ts[ino] = it;

            if (_mode_is_dir(mode)) {
                _de[dei + 1] = DirEntry(ino, ino, ".", FT_DIR);
                _de[dei + 2] = DirEntry(pino, ino, "..", FT_DIR);
                _dc[ino].push(dei + 1);
                _dc[ino].push(dei + 2);
                _de_counter += 2;
            }
            _inodes[pino].n_links++;
        }
        _ino_ts[pino] = it;
    }

    function change_attrs(uint16[] ids, INodeS[] inodes) external override accept {
        for (uint16 i = 0; i < uint16(ids.length); i++)
            _inodes[ids[i]] = inodes[ids[i]];
    }

    function update_time(uint16[] ids, INodeTimeS[] ino_tss) external override accept {
        for (uint16 i = 0; i < uint16(ids.length); i++)
            _ino_ts[ids[i]] = ino_tss[ids[i]];
    }

    function import_text_inodes(uint16 pino, INodeS[] inodes) external accept pure {
        this.add_inodes{value: 1 ton}(pino, inodes);
    }

    address _bdev;
    function _sync_fs_cache() internal {
        delete _inodes;
        delete _ino_ts;
        delete _de;
        delete _dc;
        _bdev = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
        IBlockDevice(_bdev).query_fs_cache();
    }

}
