pragma ton-solidity >= 0.49.0;

import "Base.sol";
import "String.sol";
import "IStat.sol";
import "FSTypes.sol";

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

    function _write_de(uint16 inode, string file_name, uint8 file_type) internal pure returns (string) {
        return file_name + _file_type_sign(file_type) + format("\t{}\n", inode);
    }

    function _read_de(string s) internal pure returns (string file_name, uint16 inode, uint8 file_type) {
        uint16 p = _strchr(s, "\t");
        uint16 len = uint16(s.byteLength());
        file_name = s.substr(0, p - 2);
        file_type = _file_type(s.substr(p - 2, 1));
        (uint inode_n, ) = stoi(s.substr(p, len - p));
        inode = uint16(inode_n);
    }

    function _get_dir_contents(INodeS dir, bool skip_dots) internal pure returns (uint16[] inodes, string[] names, uint8[] types) {
        for (string s: _get_lines(dir.text_data)) {
            (string file_name, uint16 inode, uint8 file_type) = _read_de(s);
            if (skip_dots && (file_name == "." || file_name == ".."))
                continue;
            inodes.push(inode);
            names.push(file_name);
            types.push(file_type);
        }
    }

    function _is_block_dev(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFBLK;
    }

    function _is_char_dev(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFCHR;
    }

    function _get_device_version(string text) internal pure returns (string major, string minor) {
        major = _element_at(1, 1, text, "\t");
        minor = _element_at(1, 2, text, "\t");
    }

    function _inode_mode_sign(uint16 mode) internal pure returns (string) {
        if ((mode & S_IFMT) == S_IFBLK)  return "b";
        if ((mode & S_IFMT) == S_IFCHR)  return "c";
        if ((mode & S_IFMT) == S_IFREG)  return "-";
        if ((mode & S_IFMT) == S_IFDIR)  return "d";
        if ((mode & S_IFMT) == S_IFLNK)  return "l";
        if ((mode & S_IFMT) == S_IFSOCK) return "s";
        if ((mode & S_IFMT) == S_IFIFO)  return "p";
    }

    function _file_type_sign(uint8 ft) internal pure returns (string) {
        if (ft == FT_BLKDEV)    return "b";
        if (ft == FT_CHRDEV)    return "c";
        if (ft == FT_REG_FILE)  return "-";
        if (ft == FT_DIR)       return "d";
        if (ft == FT_SYMLINK)   return "l";
        if (ft == FT_SOCK)      return "s";
        if (ft == FT_FIFO)      return "p";
    }

    function _file_type(string s) internal pure returns (uint8) {
        if (s == "b") return FT_BLKDEV;
        if (s == "c") return FT_CHRDEV;
        if (s == "-") return FT_REG_FILE;
        if (s == "d") return FT_DIR;
        if (s == "l") return FT_SYMLINK;
        if (s == "s") return FT_SOCK;
        if (s == "p") return FT_FIFO;
        return FT_UNKNOWN;
    }

    function _file_type_description(uint16 mode) internal pure returns (string) {
        if ((mode & S_IFMT) == S_IFBLK)  return "block special file";
        if ((mode & S_IFMT) == S_IFCHR)  return "character special file";
        if ((mode & S_IFMT) == S_IFREG)  return "regular file";
        if ((mode & S_IFMT) == S_IFDIR)  return "directory";
        if ((mode & S_IFMT) == S_IFLNK)  return "symbolic link";
        if ((mode & S_IFMT) == S_IFSOCK) return "socket";
        if ((mode & S_IFMT) == S_IFIFO)  return "fifo";
    }

    function _get_def_mode(uint8 file_type) internal pure returns (uint16) {
        if (file_type == FT_REG_FILE) return DEF_REG_FILE_MODE;
        if (file_type == FT_DIR) return DEF_DIR_MODE;
        if (file_type == FT_SYMLINK) return DEF_SYMLINK_MODE;
        if (file_type == FT_BLKDEV) return DEF_BLOCK_DEV_MODE;
        if (file_type == FT_CHRDEV) return DEF_CHAR_DEV_MODE;
        if (file_type == FT_FIFO) return DEF_FIFO_MODE;
        if (file_type == FT_SOCK) return DEF_SOCK_MODE;
    }

    function _files(string[] files, string[] contents) internal pure returns (INodeS[] inodes) {
        for (uint i = 0; i < files.length; i++)
            inodes.push(_get_reg_file_node(files[i], contents[i]));
    }

    function _get_file_node(uint16 owner, uint16 group, string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_REG_FILE_MODE, owner, group, uint32(text_data.byteLength()), 1, now, now, now, file_name, text_data);
    }

    function _get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, string dir_name) internal pure returns (INodeS, string) {
        string text = _get_dots(this_dir, parent_dir);
        return (INodeS(DEF_DIR_MODE, owner, group, uint32(text.byteLength()), 2, now, now, now, dir_name, text), _write_de(this_dir, dir_name, FT_DIR));
    }

    function _get_dots(uint16 this_dir, uint16 parent_dir) internal pure returns (string) {
        return format(".d\t{}\n..d\t{}\n", this_dir, parent_dir);
    }

    function _get_symlink_node(uint16 owner, uint16 group, string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_SYMLINK_MODE, owner, group, uint32(text_data.byteLength()), 1, now, now, now, file_name, text_data);
    }

    function _get_reg_file_node(string file_name, string text_data) internal pure returns (INodeS) {
        return INodeS(DEF_REG_FILE_MODE, SUPER_USER, SUPER_USER_GROUP, uint32(text_data.byteLength()), 1, now, now, now, file_name, text_data);
    }

    function _get_block_device_node(DeviceInfo dev) internal pure returns (INodeS) {
        (uint8 device_type, uint16 id, string name, uint16 blk_size, uint16 n_blocks) = dev.unpack();
        string dev_info_s = format("{}\t{}\t{}\t{}\t{}\n", device_type, id, name, blk_size, n_blocks);
        string char_dev_info_s = format("{}\t{}\t{}\n", 0, n_blocks, n_blocks);
        string text = dev_info_s + char_dev_info_s;
        return INodeS(DEF_BLOCK_DEV_MODE, SUPER_USER, SUPER_USER_GROUP, uint32(text.byteLength()), 1, now, now, now, name, text);
    }

}
