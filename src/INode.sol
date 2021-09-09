pragma ton-solidity >= 0.49.0;

import "Base.sol";
import "String.sol";
import "IStat.sol";
import "FSTypes.sol";

/* Base contreact to work with index nodes */
abstract contract INode is Base, String, IStat {

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;

    /* Directory entry helpers */
    function _add_dir_entry(INodeS dir, uint16 ino, string file_name, uint8 file_type) internal pure returns (INodeS) {
        string dirent = _dir_entry_line(ino, file_name, file_type);
        dir.text_data.push(dirent);
        dir.file_size += uint32(dirent.byteLength());
        dir.n_links++;
        return dir;
    }

    function _read_dir_entry(string s) internal pure returns (string file_name, uint16 inode, uint8 file_type) {
        file_type = _file_type(s.substr(0, 1));
        uint16 p = _strchr(s, "\t");
        file_name = s.substr(1, p - 2);
        (uint inode_n, bool success) = stoi(s.substr(p, s.byteLength() - p));
        if (success)
            inode = uint16(inode_n);
    }

    function _dir_entry_line(uint16 inode, string file_name, uint8 file_type) internal pure returns (string) {
        return _file_type_sign(file_type) + file_name + format("\t{}", inode);
    }

    function _match_line(string s, string[] dir) internal pure returns (uint16 idx) {
        uint len = s.byteLength();
        for (uint16 i = 0; i < dir.length; i++) {
            string line = dir[i];
            if (line.byteLength() > len)
                if (line.substr(1, len) == s)
                    return i + 1;
        }
    }

    function _get_dir_contents(INodeS dir, bool skip_dots) internal pure returns (uint16[] inodes, string[] names, uint8[] types) {
        for (string s: dir.text_data) {
            if (s.empty())
                continue;
            (string file_name, uint16 inode, uint8 file_type) = _read_dir_entry(s);
            if (skip_dots && (file_name == "." || file_name == ".."))
                continue;
            inodes.push(inode);
            names.push(file_name);
            types.push(file_type);
        }
    }

    function _symlink_target(INodeS inode) internal pure returns (string, uint16, uint8) {
        return _read_dir_entry(inode.text_data[0]);
    }

    /* Index node, file and directory entry types helpers */
    function _is_block_dev(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFBLK;
    }

    function _is_char_dev(uint16 mode) internal pure returns (bool) {
        return (mode & S_IFMT) == S_IFCHR;
    }

    function _get_device_version(string[] text) internal pure returns (string major, string minor) {
        major = _element_at(1, 1, text, "\t");
        minor = _element_at(1, 2, text, "\t");
    }

    function _permissions(uint16 p) internal pure returns (string) {
        return _inode_mode_sign(p) + _p_octet(p >> 6 & 0x0007) + _p_octet(p >> 3 & 0x0007) + _p_octet(p & 0x0007);
    }

    function _p_octet(uint16 p) internal pure returns (string out) {
        out = ((p & 4) > 0) ? "r" : "-";
        out.append(((p & 2) > 0) ? "w" : "-");
        out.append(((p & 1) > 0) ? "x" : "-");
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

    /* Preparing a set of files to export */
    function _files(string[] files, string[][] contents) internal pure returns (INodeS[] inodes) {
        for (uint i = 0; i < files.length; i++)
            inodes.push(_get_file_node(SUPER_USER, SUPER_USER_GROUP, files[i], contents[i]));
    }

    /* Getting an index node of a particular type */
    function _get_file_node(uint16 owner, uint16 group, string file_name, string[] text_data) internal pure returns (INodeS) {
        uint file_size;
        for (string s: text_data)
            file_size += s.byteLength();
        return INodeS(DEF_REG_FILE_MODE, owner, group, uint32(file_size), 1, now, now, file_name, text_data);
    }

    function _get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, string dir_name) internal pure returns (INodeS) {
        return INodeS(DEF_DIR_MODE, owner, group, 13, 2, now, now, dir_name, [format("d.\t{}", this_dir), format("d..\t{}", parent_dir)]);
    }

    function _get_symlink_node(uint16 owner, uint16 group, string file_name, string target_dirent) internal pure returns (INodeS) {
        return INodeS(DEF_SYMLINK_MODE, owner, group, uint32(target_dirent.byteLength()), 1, now, now, file_name, [target_dirent]);
    }

    function _get_block_device_node(DeviceInfo dev) internal pure returns (INodeS) {
        (uint8 device_type, uint16 id, string name, uint16 blk_size, uint16 n_blocks, address addr) = dev.unpack();
        string dev_info_s = format("{}\t{}\t{}\t{}\t{}", device_type, id, name, blk_size, n_blocks);
        string dev_address = format("{}", addr);
        return INodeS(DEF_BLOCK_DEV_MODE, SUPER_USER, SUPER_USER_GROUP,
            uint32(dev_info_s.byteLength() + dev_address.byteLength()), 1, now, now, name, [dev_info_s, dev_address]);
    }

    function _get_character_device_node(DeviceInfo dev) internal pure returns (INodeS) {
        (uint8 device_type, uint16 id, string name, uint16 blk_size, uint16 n_blocks, address addr) = dev.unpack();
        string dev_info_s = format("{}\t{}\t{}\t{}\t{}", device_type, id, name, blk_size, n_blocks);
        string dev_address = format("{}", addr);
        return INodeS(DEF_CHAR_DEV_MODE, SUPER_USER, SUPER_USER_GROUP,
            uint32(dev_info_s.byteLength() + dev_address.byteLength()), 1, now, now, name, [dev_info_s, dev_address]);
    }

}
