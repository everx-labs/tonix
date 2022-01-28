pragma ton-solidity >= 0.55.0;

import "../include/fs_types.sol";
import "../lib/stdio.sol";

library dirent {

    uint16 constant S_IXOTH = 1 << 0;
    uint16 constant S_IWOTH = 1 << 1;
    uint16 constant S_IROTH = 1 << 2;
    uint16 constant S_IRWXO = S_IROTH + S_IWOTH + S_IXOTH;

    uint16 constant S_IXGRP = 1 << 3;
    uint16 constant S_IWGRP = 1 << 4;
    uint16 constant S_IRGRP = 1 << 5;
    uint16 constant S_IRWXG = S_IRGRP + S_IWGRP + S_IXGRP;

    uint16 constant S_IXUSR = 1 << 6;
    uint16 constant S_IWUSR = 1 << 7;
    uint16 constant S_IRUSR = 1 << 8;
    uint16 constant S_IRWXU = S_IRUSR + S_IWUSR + S_IXUSR;

    uint16 constant S_ISVTX = 1 << 9;  //   sticky bit
    uint16 constant S_ISGID = 1 << 10; //   set-group-ID bit
    uint16 constant S_ISUID = 1 << 11; //   set-user-ID bit

    uint16 constant S_IFIFO = 1 << 12;
    uint16 constant S_IFCHR = 1 << 13;
    uint16 constant S_IFDIR = 1 << 14;
    uint16 constant S_IFBLK = S_IFDIR + S_IFCHR;
    uint16 constant S_IFREG = 1 << 15;
    uint16 constant S_IFLNK = S_IFREG + S_IFCHR;
    uint16 constant S_IFSOCK = S_IFREG + S_IFDIR;
    uint16 constant S_IFMT  = 0xF000; //   bit mask for the file type bit field

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;
    uint8 constant FT_LAST      = FT_SYMLINK;

    uint16 constant DEF_BLOCK_SIZE = 100;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 60;
    uint16 constant MAX_BLOCKS = 4000;
    uint16 constant MAX_INODES = 600;

    uint8 constant ENOENT       = 1; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST       = 2; // "File exists"
    uint8 constant ENOTDIR      = 3; //  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR       = 4; //"Is a directory"
    uint8 constant EACCES       = 5; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)
    uint8 constant ENOTEMPTY    = 6; // "Directory not empty"
    uint8 constant EPERM        = 7; // "Not owner"
    uint8 constant EINVAL       = 8; //"Invalid argument"
    uint8 constant EROFS        = 9; //"Read-only file system"
    uint8 constant EFAULT       = 10; //Bad address.
    uint8 constant EBADF        = 11; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY        = 12; // "Device busy"
    uint8 constant ENOSYS       = 13; // "Operation not applicable"
    uint8 constant ENAMETOOLONG = 14; // pathname is too long.

    function parse_entry(string s) internal returns (DirEntry) {
        uint p = stdio.strchr(s, "\t");
        if (p > 1) {
            optional(int) index_u = stoi(s.substr(p));
            return DirEntry(file_type(s.substr(0, 1)), s.substr(1, p - 2), index_u.hasValue() ? uint16(index_u.get()) : ENOENT);
        }
    }

    function read_dir_data(bytes dir_data) internal returns (DirEntry[] contents, int16 status) {
        (string[] lines, ) = stdio.split(dir_data, "\n");
        for (string s: lines)
            contents.push(parse_entry(s));
        status = int16(contents.length);
    }

    function read_dir_verbose(bytes dir_data) internal returns (DirEntry[] contents, int16 status, string out) {
        (string[] lines, ) = stdio.split(dir_data, "\n");
        for (string s: lines) {
            if (s.empty())
                out.append("Empty dir entry line\n");
            else {
                (string s_head, string s_tail) = stdio.strsplit(s, "\t");
                if (s_head.empty())
                    out.append("Empty file type and name: " + s + "\n");
                else if (s_tail.empty())
                    out.append("Empty inode reference: " + s + "\n");
                else {
                    uint h_len = s_head.byteLength();
                    if (h_len < 2)
                        out.append("File type and name too short: " + s_head + "\n");
                    else {
                        DirEntry de = DirEntry(dirent.file_type(s_head.substr(0, 1)), s_head.substr(1), stdio.atoi(s_tail));
                        contents.push(de);
                        out.append(dirent.print(de));
                    }
                }
            }
        }
        status = int16(contents.length);
    }

    function print(DirEntry de) internal returns (string) {
        (uint8 file_type, string file_name, uint16 index) = de.unpack();
        return dir_entry_line(index, file_name, file_type);
    }

    function read_dir(Inode inode, bytes data) internal returns (DirEntry[] contents, int16 status) {
        if ((inode.mode & S_IFMT) != S_IFDIR)
            status = -ENOTDIR;
        else
            return read_dir_data(data);
    }

    function get_symlink_target(Inode inode, bytes node_data) internal returns (DirEntry target) {
        if ((inode.mode & S_IFMT) != S_IFLNK)
            target.index = ENOSYS;
        else
            return parse_entry(node_data);
    }

    function dir_entry_line(uint16 index, string file_name, uint8 file_type) internal returns (string) {
//        return file_type_sign(file_type) + file_name + format("\t{}\n", index);
        return format("{}{}\t{}\n", file_type_sign(file_type), file_name, index);
    }

    function file_type_sign(uint8 ft) internal returns (string) {
        if (ft == FT_BLKDEV)    return "b";
        if (ft == FT_CHRDEV)    return "c";
        if (ft == FT_REG_FILE)  return "-";
        if (ft == FT_DIR)       return "d";
        if (ft == FT_SYMLINK)   return "l";
        if (ft == FT_SOCK)      return "s";
        if (ft == FT_FIFO)      return "p";
        return "?";
    }

    function file_type(string s) internal returns (uint8) {
        if (s == "b") return FT_BLKDEV;
        if (s == "c") return FT_CHRDEV;
        if (s == "-") return FT_REG_FILE;
        if (s == "d") return FT_DIR;
        if (s == "l") return FT_SYMLINK;
        if (s == "s") return FT_SOCK;
        if (s == "p") return FT_FIFO;
        return FT_UNKNOWN;
    }

}
