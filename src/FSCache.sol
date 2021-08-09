pragma ton-solidity >= 0.48.0;

import "Errors.sol";
import "SyncFS.sol";

abstract contract FSCache is Errors, SyncFS {

    function _get_group_id(uint16 uid) internal view returns (uint16) {
        User u = _users.exists(uid) ? _users[uid] : _users[_init_ids[11]];
        return _ugroups.exists(u.group_id) ? u.group_id : 0;
    }

    function _get_root_dir() internal view returns (uint16, uint16) {
        return (_init_ids[2], _init_ids[1]);
    }

    function _get_home_dir() internal view returns (uint16, uint16) {
        return (_init_ids[13], _init_ids[14]);
    }

    function _get_this_dir(uint16 dir) internal view returns (uint16, uint16) {
        if (_dc.exists(dir) && _dc[dir].length > 1) {
            uint16 dot = _dc[dir][0];
            if (_de.exists(dot))
                return (dir, dot);
        }
    }

    function _get_parent_dir(uint16 dir) internal view returns (uint16, uint16) {
        if (_dc.exists(dir) && _dc[dir].length > 1) {
            uint16 dotdot = _dc[dir][1];
            if (_de.exists(dotdot))
                return (_de[dotdot].inode, dotdot);
        }
    }

    function _get_symlink_target(uint16 lnk) internal view returns (uint16) {
        if (_dc.exists(lnk) && _dc[lnk].length == 1) {
            uint16 target = _dc[lnk][0];
            if (_inodes.exists(target))
                return target;
        }
    }

    function _is_special_dir(string s) internal pure returns (bool) {
        return s == "" || s == "/" || s == "~" || s == "." || s == "..";
    }

    function _get_special_dir(string s, uint16 dir) internal view returns (uint16, uint16) {
        if (s == "/") return _get_root_dir();
        if (s == "~") return _get_home_dir();
        if (s == ".") return _get_this_dir(dir);
        if (s == "..") return _get_parent_dir(dir);
        if (s == "") return _get_this_dir(dir);
    }

    function _resolve_abs_path(string dir_name) internal view returns (uint16) {
        for (uint16 i = 0; i < _ino_counter; i++)
            if (_is_dir(i) && _inodes[i].text_data == dir_name)
                return i;
    }

    function _lookup_in_dir(string path, uint16 dir) internal view returns (uint16, uint16) {
        if (_is_special_dir(path))
            return _get_special_dir(path, dir);
        string name = path;
        uint16 p = _strchr(path, "/");
        if (p > 0) {
            uint16 q = _strrchr(path, "/");
            if (p == 1) {
                dir = q == 1 ? _init_ids[2] : _resolve_abs_path(_dir(path));
                name = _not_dir(path);
            }
        }

        for (uint16 j: _dc[dir]) {
            if (j == 0) continue;
            if (_de[j].name == name)
                return (_de[j].inode, j);
        }
        return (ENOENT, ENOENT);
    }

    function _lookup_opnd_deref(string s, uint16 dir, uint8 mode) internal view returns (uint16, uint16) {
        (uint16 i, uint16 d) = _lookup_in_dir(s, dir);
        if (mode == 0)
            return (i, d);
        if (mode == 1) {
            if (_is_symlink(i))
                return (_get_symlink_target(i), 0);
        }
        if (mode == 2) {
            if (_is_symlink(i))
                return (i, d);
        }
    }
}
