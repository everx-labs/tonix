pragma ton-solidity >= 0.48.0;

import "Commands.sol";
import "ISync.sol";
import "IBlockDevice.sol";
import "INode.sol";
import "String.sol";

abstract contract SyncFS is String, Commands, ISync, INode {
    uint16 _ino_counter;

    mapping (uint16 => INodeS) public _inodes;
    mapping (uint16 => INodeTimeS) public _ino_ts;
    mapping (uint16 => UserGroup) public _ugroups;
    mapping (uint16 => User) public _users;
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

    function _the_time_is_now() internal pure returns (INodeTimeS) {
        return INodeTimeS(now, now, now);
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

    function update_users(mapping (uint16 => UserGroup) ugroups, mapping (uint16 => User) users, uint16 ino_counter) external override accept {
        _ino_counter = ino_counter;
        for ((uint16 i, UserGroup ug): ugroups)
            _ugroups[i] = ug;
        for ((uint16 i, User u): users)
            _users[i] = u;
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

    function update(uint16 pino, INodeS[] inodes) external override accept {
        for (INodeS i: inodes) {
            _inodes[pino] = i;
        }
    }
    function rem_dirents(uint16 pino, uint16[] rem) external override accept {
        INodeTimeS it = _the_time_is_now();
        uint16[] pd = _dc[pino];
        for (uint i = 0; i < pd.length; i++) {
            for (uint16 dei: rem) {
                if (pd[i] == dei) {
                    _dc[pino][i] = 0;
                    _inodes[pino].n_links--;
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

    function add(uint16 pino, INodeS[] inodes) external override accept {
        INodeTimeS it = _the_time_is_now();
        for (INodeS i: inodes) {
            uint16 ino = ++_ino_counter;
            uint16 mode = i.mode;
            _inodes[ino] = i;
            uint8 file_type = _mode_is_reg(mode) ? FT_REG_FILE : _mode_is_dir(mode) ? FT_DIR : _mode_is_symlink(mode) ? FT_SYMLINK : FT_UNKNOWN;
            _ino_ts[ino] = it;
            _inodes[pino] = _add_dir_entry(_inodes[pino], ino, i.file_name, file_type);

            if (_mode_is_dir(mode)) {
                string dots = _get_dots(ino, pino);
                _inodes[ino].text_data = dots;
                _inodes[ino].file_size = uint32(dots.byteLength());
            }
        }
        _ino_ts[pino] = it;
    }

    function _add_reg_files(uint16 pino, INodeS[] inodes) internal {
        INodeTimeS it = _the_time_is_now();
        uint16 len = uint16(inodes.length);
        uint16 counter = _ino_counter;
        INodeS dir = _inodes[pino];
        string text = dir.text_data;
        for (uint16 i = 0; i < len; i++) {
            _inodes[counter + i] = inodes[i];
            _ino_ts[counter + i] = it;
            text.append(_write_de(counter + i, inodes[i].file_name, FT_REG_FILE));
        }
        dir.text_data = text;
        dir.file_size = uint32(text.byteLength());
        dir.n_links += len;
        _inodes[pino] = dir;
        _ino_counter += len;
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

    address _bdev;
    function _sync_fs_cache() internal {
        delete _inodes;
        delete _ino_ts;
        delete _dc;
        _bdev = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
        IBlockDevice(_bdev).query_fs_cache();
    }

}
