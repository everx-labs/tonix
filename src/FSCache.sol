pragma ton-solidity >= 0.48.0;

import "Errors.sol";
import "SyncFS.sol";

abstract contract FSCache is SyncFS, Errors {

    function _get_group_id(uint16 uid) internal view returns (uint16) {
        User u = _users[_users.exists(uid) ? uid : REG_USER];
        return _ugroups.exists(u.group_id) ? u.group_id : 0;
    }

    function _get_symlink_target(uint16 lnk) internal view returns (uint16) {
        if (_dc.exists(lnk) && _dc[lnk].length == 1) {
            uint16 target = _dc[lnk][0];
            if (_inodes.exists(target))
                return target;
        }
    }

    function _get_etc_dir() internal view returns (uint16) {
        return _lookup_inode_in_dir("etc", ROOT_DIR);
    }

    function _is_special_dir(string s) internal pure returns (bool) {
        return s == "/" || s == "~";
    }

    function _get_special_dir(string s) internal view returns (uint16) {
        if (s == "/") return ROOT_DIR;
        if (s == "~") return _lookup_inode_in_dir("home", ROOT_DIR);
    }

    function _get_parent_dir(uint16 dir) internal view returns (uint16) {
        return _lookup_inode_in_dir("..", dir);
    }

    function _resolve_abs_path(string dir_name) internal view returns (uint16) {
        if (dir_name == "/")
            return ROOT_DIR;
        string dir = _dir(dir_name);
        string not_dir = _not_dir(dir_name);
        uint16 ino;
        if (dir == "/")
            ino = _lookup_inode_in_dir(not_dir, ROOT_DIR);
        else
            ino = _lookup_inode_in_dir(not_dir, _resolve_abs_path(dir));
        return ino;
    }

    function _lookup_inode_in_dir(string path, uint16 dir) internal view returns (uint16 inode) {
        (inode, ) = _lookup_inode_and_type(path, dir);
    }

    function _lookup_inode_and_type(string path, uint16 dir) internal view returns (uint16 inode, uint8 file_type) {
        if (_is_special_dir(path)) {
            inode= _get_special_dir(path);
            return (inode, FT_DIR);
        }
        string name = path;
        uint16 p = _strchr(path, "/");
        if (p > 0) {
            uint16 q = _strrchr(path, "/");
            if (p == 1) {
                dir = q == 1 ? ROOT_DIR : _resolve_abs_path(_dir(path));
                name = _not_dir(path);
            }
        }

        inode = _lookup_inode(name, _inodes[dir].text_data);
        if (inode > INODES) {
            uint16 mode = _inodes[inode].mode;
            file_type = _mode_is_reg(mode) ? FT_REG_FILE : _mode_is_dir(mode) ? FT_DIR : _mode_is_symlink(mode) ? FT_SYMLINK : FT_UNKNOWN;
        }
    }

    function _lookup_opnd_deref(string s, uint16 dir, uint8 mode) internal view returns (uint16, uint16) {
        uint16 i = _lookup_inode_in_dir(s, dir);
        if (mode == 0)
            return (i, 0);
        if (mode == 1) {
            if (_is_symlink(i))
                return (_get_symlink_target(i), 0);
        }
        if (mode == 2) {
            if (_is_symlink(i))
                return (i, 0);
        }
    }
}
