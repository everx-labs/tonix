pragma ton-solidity >= 0.48.0;

import "Base.sol";
import "String.sol";
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

abstract contract INode is Base, String, IStat {

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;

    function _add_dir_entry(INodeS dir, uint16 ino, string file_name, uint8 file_type) internal pure returns (INodeS) {
        dir.text_data.append(_write_de(ino, file_name, file_type));
        dir.file_size = uint32(dir.text_data.byteLength());
        dir.n_links++;
        return dir;
    }

    function _add_dirents(INodeS dir, uint16 ino_start, string[] file_names, uint8 file_type) internal pure returns (INodeS) {
        uint16 len = uint16(file_names.length);
        string text = dir.text_data;
        for (uint16 i = 0; i < len; i++)
            text.append(_write_de(ino_start + i, file_names[i], file_type));
        dir.text_data = text;
        dir.file_size = uint32(text.byteLength());
        dir.n_links += len;
        return dir;
    }

    function _write_de(uint16 inode, string file_name, uint8 file_type) internal pure returns (string) {
        return format("{}\t{}\n", _if(file_name, file_type == FT_DIR, "/"), inode);
    }

    function _read_de(string s) internal pure returns (string file_name, uint16 inode, uint8 file_type) {
        uint16 p = _strchr(s, "\t");
        uint16 q = _strchr(s, "/");
        uint16 len = uint16(s.byteLength());
        if (q > 0) {
            file_name = s.substr(0, q - 1);
            file_type = FT_DIR;
        } else {
            file_name = s.substr(0, p - 1);
            file_type = FT_REG_FILE;
        }
        string inode_s = s.substr(p, len - p);
        (uint inode_n, ) = stoi(inode_s);
        inode = uint16(inode_n);
    }

    function _lookup_inode(string name, string text) internal pure returns (uint16) {
        string[] lines = _get_lines(text);
        for (string s: lines) {
            (string file_name, uint16 inode, ) = _read_de(s);
            if (file_name == name)
                return inode;
        }
    }

    function _lookup_name(uint16 inode, string text) internal pure returns (string) {
        string[] lines = _get_lines(text);
        for (string s: lines) {
            (string file_name, uint16 file_inode, ) = _read_de(s);
            if (inode == file_inode)
                return file_name;
        }
    }

    function _get_dir_contents(INodeS dir, bool skip_dots) internal pure returns (uint16[] inodes, string[] names, uint8[] types) {
        string text = dir.text_data;
        string[] lines = _get_lines(text);
        string file_name;
        uint16 inode;
        uint8 file_type;
        for (string s: lines) {
            (file_name, inode, file_type) = _read_de(s);
            if (skip_dots && (file_name == "." || file_name == ".."))
                continue;
            inodes.push(inode);
            names.push(file_name);
            types.push(file_type);
        }
    }

    function _mode_is_reg(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFREG;
    }

    function _mode_is_dir(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFDIR;
    }

    function _mode_is_symlink(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFLNK;
    }

    function _files(string[] files, string[] contents) internal pure returns (INodeS[] inodes) {
        for (uint i = 0; i < files.length; i++)
            inodes.push(_get_reg_file_node(files[i], contents[i]));
    }

    function _get_file_node(uint16 owner, uint16 group, string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_FILE_MODE, owner, group, uint32(text_data.byteLength()), 1, file_name, text_data);
    }

    function _get_dir_node_bare(uint16 owner, uint16 group, string dir_name) internal pure returns (INodeS) {
        return INodeS(DEF_DIR_MODE, owner, group, 0, 2, dir_name, "");
    }

    function _get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, string dir_name) internal pure returns (INodeS, string) {
        string text = _get_dots(this_dir, parent_dir);
        return (INodeS(DEF_DIR_MODE, owner, group, uint32(text.byteLength()), 2, dir_name, text), _write_de(this_dir, dir_name, FT_DIR));
    }

    function _get_dots(uint16 this_dir, uint16 parent_dir) internal pure returns (string) {
        return format("./\t{}\n../\t{}\n", this_dir, parent_dir);
    }

    function _get_symlink_node(uint16 owner, uint16 group, string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_SYMLINK_MODE, owner, group, uint32(text_data.byteLength()), 1, file_name, text_data);
    }

    function _get_reg_file_node(string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_FILE_MODE, SUPER_USER, SUPER_USER_GROUP, uint32(text_data.byteLength()), 1, file_name, text_data);
    }

}
