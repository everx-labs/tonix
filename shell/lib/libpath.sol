pragma ton-solidity >= 0.51.0;

import "../include/Internal.sol";
import "../lib/stdio.sol";
import "../lib/libfmt.sol";

//library libpath {
abstract contract libpath {

    uint16 constant ROOT_DIR = 11;
    string constant ROOT = "/";

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

    function _fetch_dir_entry(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16 ino, uint8 ft) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR);
        if (!inodes.exists(dir))
            return (ENOTDIR, FT_UNKNOWN);
        Inode inode = inodes[dir];
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return (ENOTDIR, FT_UNKNOWN);
        (ino, ft) = _lookup_dir(inode, data[dir], name);
    }

    function _resolve_absolute_path(string path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16) {
        if (path == ROOT)
            return ROOT_DIR;
        (string dir, string not_dir) = _dir(path);
        (uint16 ino, ) = _fetch_dir_entry(not_dir, _resolve_absolute_path(dir, inodes, data), inodes, data);
        return ino;
    }

    function _get_file_contents_at_path(string path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        (string dir_name, string file_name) = _dir(path);
        uint16 dir_index = _resolve_absolute_path(dir_name, inodes, data);
        (uint16 file_index, uint8 ft) = _lookup_dir(inodes[dir_index], data[dir_index], file_name);
        if (ft == FT_UNKNOWN)
            return "Failed to read file " + file_name + " at path " + dir_name + "\n";
        return _get_file_contents(file_index, inodes, data);
    }

    function _get_file_contents(uint16 file_index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        if (!inodes.exists(file_index))
            return format("Inode {} does not exist\n", file_index);
        if (!data.exists(file_index))
            return format("Data {} does not exist\n", file_index);
        return data[file_index];
    }

    function _lookup_dir(Inode inode, bytes data, string file_name) internal returns (uint16 index, uint8 file_type) {
        (index, file_type, ) = _lookup_dir_ext(inode, data, file_name);
    }

    function _lookup_dir_ext(Inode inode, bytes data, string file_name) internal returns (uint16 index, uint8 file_type, uint16 dir_idx) {
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return (ENOTDIR, FT_UNKNOWN, 0);
        (DirEntry[] contents, int16 status) = _read_dir(inode, data);
        if (status < 0)
            return (uint16(-status), FT_UNKNOWN, 0);
        else {
            for (uint i = 0; i < uint(status); i++) {
                (uint8 ft, string name, uint16 idx) = contents[i].unpack();
                if (name == file_name)
                    return (idx, ft, uint16(i + 1));
            }
            return (ENOENT, FT_UNKNOWN, 0);
        }
    }

    function _dir(string path) internal returns (string dir, string not_dir) {
        if (path.empty())
            return (".", "");
        if (path == "/")
            return ("/", "/");
        uint q = stdio._strrchr(path, "/");
        if (q == 0)
            return (".", path);
        if (q == 1)
            return ("/", path.substr(1));
        return (path.substr(0, q - 1), path.substr(q));
    }

    function _parse_entry(string s) internal returns (DirEntry dirent) {
        uint p = stdio._strchr(s, "\t");
        if (p > 1) {
            optional(int) index_u = stoi(s.substr(p));
            if (index_u.hasValue())
                dirent = DirEntry(_file_type(s.substr(0, 1)), s.substr(1, p - 2), uint16(index_u.get()));
            else
                dirent = DirEntry(_file_type(s.substr(0, 1)), s.substr(1, p - 2) + " ?" + s.substr(p) + "? ", ENOENT);
        }
    }

    function _read_dir_data(bytes dir_data) internal returns (DirEntry[] contents, int16 status) {
        (string[] lines, ) = stdio._split(dir_data, "\n");
        for (string s: lines)
            contents.push(_parse_entry(s));
        status = int16(contents.length);
    }

    function _read_dir(Inode inode, bytes data) internal returns (DirEntry[] contents, int16 status) {
        if ((inode.mode & S_IFMT) != S_IFDIR)
            status = -ENOTDIR;
        else
            return _read_dir_data(data);
    }

    function _file_type(string s) internal returns (uint8) {
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