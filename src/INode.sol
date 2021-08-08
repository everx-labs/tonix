pragma ton-solidity >= 0.48.0;

import "Base.sol";
import "IStat.sol";

struct INodeS {
    uint16 mode;
    uint16 owner_id;
    uint16 group_id;
    uint32 file_size;
    uint16 n_links;
    string file_name;
    string text_data;
}

struct INodeTimeS {
    uint32 accessed_at;
    uint32 modified_at;
    uint32 last_modified;
}

abstract contract INode is Base, IStat {

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;

    function _mode_is_reg(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFREG;
    }

    function _mode_is_dir(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFDIR;
    }

    function _mode_is_symlink(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFLNK;
    }

    function _sub(string parent, string[] dirs) internal pure returns (INodeS[] inodes) {
        for (string s: dirs)
            inodes.push(_get_node(FT_DIR, SUPER_USER, ROOT_USER_GROUP, s, parent + "/" + s));
    }

    function _files(string[] files, string[] contents) internal pure returns (INodeS[] inodes) {
        for (uint i = 0; i < files.length; i++)
            inodes.push(_get_reg_file_node(files[i], contents[i]));
    }

    function _get_node(uint8 ft, uint16 owner, uint16 group, string path, string text) internal pure returns (INodeS) {
        bool d = ft == FT_DIR;
        return INodeS(d ? DEF_DIR_MODE : DEF_FILE_MODE, owner, group, uint32(text.byteLength()), d ? 2 : 1, path, text);
    }

    function _get_file_node(uint16 owner, uint16 group, string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_FILE_MODE, owner, group, uint32(text_data.byteLength()), 1, file_name, text_data);
    }

    function _get_reg_file_node(string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_FILE_MODE, SUPER_USER, ROOT_USER_GROUP, uint32(text_data.byteLength()), 1, file_name, text_data);
    }

}
