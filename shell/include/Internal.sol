pragma ton-solidity >= 0.55.0;

import "Base.sol";
//import "fs_types.sol";
import "../lib/fmt.sol";
import "../lib/dirent.sol";
import "../lib/sb.sol";
import "../lib/inode.sol";
import "../lib/fs.sol";

/* Base contract to work with index nodes */
abstract contract Internal is Base {

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

    uint16 constant DEF_REG_FILE_MODE   = S_IFREG + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_DIR_MODE        = S_IFDIR + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;
    uint16 constant DEF_SYMLINK_MODE    = S_IFLNK + S_IRWXU + S_IRWXG + S_IRWXO;
    uint16 constant DEF_BLOCK_DEV_MODE  = S_IFBLK + S_IRUSR + S_IWUSR;
    uint16 constant DEF_CHAR_DEV_MODE   = S_IFCHR + S_IRUSR + S_IWUSR;
    uint16 constant DEF_FIFO_MODE       = S_IFIFO + S_IRUSR + S_IWUSR + S_IRGRP + S_IROTH;
    uint16 constant DEF_SOCK_MODE       = S_IFSOCK + S_IRWXU + S_IRGRP + S_IXGRP + S_IROTH + S_IXOTH;

    uint8 constant FT_UNKNOWN   = 0;
    uint8 constant FT_REG_FILE  = 1;
    uint8 constant FT_DIR       = 2;
    uint8 constant FT_CHRDEV    = 3;
    uint8 constant FT_BLKDEV    = 4;
    uint8 constant FT_FIFO      = 5;
    uint8 constant FT_SOCK      = 6;
    uint8 constant FT_SYMLINK   = 7;
    uint8 constant FT_LAST      = FT_SYMLINK;

    uint8 constant TF_REG_FILE  = 0;
    uint8 constant TF_HARDLINK  = 1;
    uint8 constant TF_SYMLINK   = 2;
    uint8 constant TF_CHRDEV    = 3;
    uint8 constant TF_BLKDEV    = 4;
    uint8 constant TF_DIR       = 5;
    uint8 constant TF_FIFO      = 6;
    uint8 constant TF_SOCK      = 7;

    uint16 constant MOUNT_NONE          = 0;
    uint16 constant MOUNT_DIR           = 1;
    uint16 constant MOUNT_OVERLAY       = 4;
    uint16 constant QUERY_FS_CACHE      = 5;

    uint16 constant UAO_SYSTEM              = 16;
    uint16 constant UAO_CREATE_HOME_DIR     = 32;
    uint16 constant UAO_CREATE_USER_GROUP   = 64;
    uint16 constant UAO_ADD_SUPP_GROUPS     = 128;
    uint16 constant UAO_REMOVE_HOME_DIR     = 1024;
    uint16 constant UAO_REMOVE_EMPTY_GROUPS = 2048;

    uint8 constant AE_LOGIN         = 1;
    uint8 constant AE_LOGOUT        = 2;
    uint8 constant AE_SHUTDOWN      = 3;

    uint16 constant DEF_BLOCK_SIZE = 100;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 60;
    uint16 constant MAX_BLOCKS = 4000;
    uint16 constant MAX_INODES = 600;

    uint16 constant CANON_NONE  = 0;
    uint16 constant CANON_MISS  = 1;
    uint16 constant CANON_DIRS  = 2;
    uint16 constant CANON_EXISTS = 3;
    uint16 constant EXPAND_SYMLINKS = 8;

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

    uint8 constant ERR_MSG              = 0;
    uint8 constant invalid_option       = 7;
    uint8 constant extra_operand        = 8;
    uint8 constant missing_file_operand = 11;
    uint8 constant invalid_mode         = 15;
    uint8 constant invalid_owner        = 16;
    uint8 constant try_help_for_info    = 21;
    uint8 constant omitting_directory   = 23;
    uint8 constant cant_overwrite_dir   = 24;
    uint8 constant command_not_found    = 25;
    uint8 constant options_l_s_incompat = 26;
    uint8 constant ln_target            = 27;
    uint8 constant failed_symlink       = 28;
    uint8 constant failed_hardlink      = 29;
    uint8 constant hard_or_symlink      = 30;
    uint8 constant no_hardlink_on_dir   = 31;
    uint8 constant mutually_exclusive_options = 32;
    uint8 constant login_data_not_found = 33;
    uint8 constant not_a_block_device   = 34;

    uint constant _0 = 1 << 48;
    uint constant _1 = 1 << 49;
    uint constant _2 = 1 << 50;
    uint constant _3 = 1 << 51;
    uint constant _4 = 1 << 52;
    uint constant _5 = 1 << 53;
    uint constant _6 = 1 << 54;
    uint constant _7 = 1 << 55;
    uint constant _8 = 1 << 56;
    uint constant _9 = 1 << 57;

    uint constant _A = 1 << 65;
    uint constant _B = 1 << 66;
    uint constant _C = 1 << 67;
    uint constant _D = 1 << 68;
    uint constant _E = 1 << 69;
    uint constant _F = 1 << 70;
    uint constant _G = 1 << 71;
    uint constant _H = 1 << 72;
    uint constant _I = 1 << 73;
    uint constant _J = 1 << 74;
    uint constant _K = 1 << 75;
    uint constant _L = 1 << 76;
    uint constant _M = 1 << 77;
    uint constant _N = 1 << 78;
    uint constant _O = 1 << 79;
    uint constant _P = 1 << 80;
    uint constant _Q = 1 << 81;
    uint constant _R = 1 << 82;
    uint constant _S = 1 << 83;
    uint constant _T = 1 << 84;
    uint constant _U = 1 << 85;
    uint constant _V = 1 << 86;
    uint constant _W = 1 << 87;
    uint constant _X = 1 << 88;
    uint constant _Y = 1 << 89;
    uint constant _Z = 1 << 90;

    uint constant _a = 1 << 97;
    uint constant _b = 1 << 98;
    uint constant _c = 1 << 99;
    uint constant _d = 1 << 100;
    uint constant _e = 1 << 101;
    uint constant _f = 1 << 102;
    uint constant _g = 1 << 103;
    uint constant _h = 1 << 104;
    uint constant _i = 1 << 105;
    uint constant _j = 1 << 106;
    uint constant _k = 1 << 107;
    uint constant _l = 1 << 108;
    uint constant _m = 1 << 109;
    uint constant _n = 1 << 110;
    uint constant _o = 1 << 111;
    uint constant _p = 1 << 112;
    uint constant _q = 1 << 113;
    uint constant _r = 1 << 114;
    uint constant _s = 1 << 115;
    uint constant _t = 1 << 116;
    uint constant _u = 1 << 117;
    uint constant _v = 1 << 118;
    uint constant _w = 1 << 119;
    uint constant _x = 1 << 120;
    uint constant _y = 1 << 121;
    uint constant _z = 1 << 122;

    /* Looks for a file name in the directory entry. Return file index and file type */
/*    function _fetch_dir_entry(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (uint16 ino, uint8 ft) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR);
        if (!inodes.exists(dir))
            return (ENOTDIR, FT_UNKNOWN);
        Inode inode = inodes[dir];
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return (ENOTDIR, FT_UNKNOWN);
        (ino, ft) = _lookup_dir(inode, data[dir], name);
    }

    function _resolve_absolute_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (uint16) {
        if (s_path == ROOT)
            return ROOT_DIR;
        (string s_dir, string s_not_dir) = path.dir(s_path);
        (uint16 ino, ) = _fetch_dir_entry(s_not_dir, _resolve_absolute_path(s_dir, inodes, data), inodes, data);
        return ino;
    }

    function _xpath(string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        return path.strip_path(_xpath0(s_arg, wd, inodes, data));
    }

    function _xpath0(string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        uint len = s_arg.byteLength();
        if (len > 0 && s_arg.substr(0, 1) == "/")
            return s_arg;
        string cwd = _get_absolute_path(wd, inodes, data);
        if (len == 0 || s_arg == ".")
            return cwd;
        if (len > 1 && s_arg.substr(0, 2) == "./")
            return cwd + "/" + s_arg.substr(2);
        if (len > 1 && s_arg.substr(0, 2) == "..") {
            (string dir_name, ) = path.dir(cwd);
            if (s_arg == "..")
                return dir_name;
            if (dir_name == "/")
                dir_name = "";
            return dir_name + "/" + s_arg.substr(3);
        }
        return cwd + "/" + s_arg;
    }

    function _get_absolute_path(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        if (dir == ROOT_DIR)
            return ROOT;
        (uint16 parent, uint8 ft) = _fetch_dir_entry("..", dir, inodes, data);
        if (ft != FT_DIR)
            return ROOT;

        return (parent == ROOT_DIR ? "" : _get_absolute_path(parent, inodes, data)) + "/" + inodes[dir].file_name;
    }

    function _get_file_contents_at_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        (string dir_name, string file_name) = path.dir(s_path);
        uint16 dir_index = _resolve_absolute_path(dir_name, inodes, data);
        (uint16 file_index, uint8 ft) = _lookup_dir(inodes[dir_index], data[dir_index], file_name);
        if (ft == FT_UNKNOWN)
            return "Failed to read file " + file_name + " at path " + dir_name + "\n";
        return _get_file_contents(file_index, inodes, data);
    }

    function _get_file_contents(uint16 file_index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        if (!inodes.exists(file_index))
            return format("Inode {} does not exist\n", file_index);
        if (!data.exists(file_index))
            return format("Data {} does not exist\n", file_index);
        return data[file_index];
    }

    function _resolve_relative_path(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns
            (uint16 index, uint8 file_type, uint16 parent, uint16 dir_index) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR, ROOT_DIR, 1);
        parent = name.substr(0, 1) == "/" ? ROOT_DIR : dir;

        (string dir_path, string base_name) = path.dir(name);
        string[] parts = path.disassemble_path(dir_path);
        uint len = parts.length;

        for (uint i = len - 1; i > 0; i--) {
            (uint16 ino, uint8 ft, , uint16 dir_idx) = _resolve_relative_path(parts[i - 1], parent, inodes, data);
            if (dir_idx == 0)
                return (ino, ft, parent, dir_idx);
            else if (ft == FT_DIR)
                parent = ino;
            else
                break;
        }
        (index, file_type, dir_index) = _lookup_dir_ext(inodes[parent], data[parent], base_name);
    }

    function _dump_fs(uint8 level, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        SuperBlock sb = sb.get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();
        out = format("{} IC {} BC {} FI {} FB {} BS {} MC {} MMC {} WR {} FI {} IS {} FSS {} EB {}\n",
            file_system_OS_type, inode_count, block_count, free_inodes, free_blocks, block_size,
            mount_count, max_mount_count, lifetime_writes, first_inode, inode_size, file_system_state ? "Y" : "N", errors_behavior ? "Y" : "N");
        out.append(format("CT {} LMT {} LWT {}\n", fmt.ts(created_at), fmt.ts(last_mount_time), fmt.ts(last_write_time)));

        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
            if (level > 0 && ((mode & S_IFMT) == S_IFDIR || (mode & S_IFMT) == S_IFLNK) || level > 1)
                out.append(data[i]);
        }
    }

    function _dumpfs(uint16 level, uint16 form, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        SuperBlock sb = sb.get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();
        if ((level & DUMP_SB) > 0) {
            if (form == DUMP_COMPACT)
                out = format("{} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}\n",
                    file_system_state ? "Y" : "N", errors_behavior ? "Y" : "N", file_system_OS_type,
                    inode_count, block_count, free_inodes, free_blocks, block_size, created_at,
                    last_mount_time, last_write_time, mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
            else if (form == DUMP_AS_TEXT) {
                out = format("{} IC {} BC {} FI {} FB {} BS {} MC {} MMC {} WR {} FI {} IS {} FSS {} EB {}\n",
                    file_system_OS_type, inode_count, block_count, free_inodes, free_blocks, block_size,
                    mount_count, max_mount_count, lifetime_writes, first_inode, inode_size, file_system_state ? "Y" : "N", errors_behavior ? "Y" : "N");
                out.append(format("CT {} LMT {} LWT {}\n", fmt.ts(created_at), fmt.ts(last_mount_time), fmt.ts(last_write_time)));
            }
        }
        uint pos = 0;
        for ((uint16 i, Inode ino): inodes) {
            if (i < ROOT_DIR && (level & DUMP_SB_INODES) == 0 ||
                i > ROOT_DIR && (level & DUMP_USER_INODES) == 0)
                    continue;
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, string file_name) = ino.unpack();
            bytes text = data[i];
            string inode_s;
            if ((level & DUMP_INDEX_HEADERS) > 0) {
                if (form == DUMP_COMPACT)
                    inode_s = fmt.pad(format("{} {} {} {} {} {} {} {} {} {} {}", i, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name),
                        inode_size, fmt.ALIGN_LEFT);
                else if (form == DUMP_AS_TEXT)
                    inode_s = format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size);
                /*else if (form == DUMP_AS_TAR_HEADER)
                    inode_s = _write_tar_index_entry_bin(ino);
            }
            uint inode_len = inode_s.byteLength();
            uint count = text.length;
            if ((level & DUMP_FILE_MAPPING) > 0) {
                string index_s;
                if (inode_len > 0) {
                    index_s = format("{} {} {} {}\n", i, pos, inode_len, count);
                    pos += inode_len + count;
                    out.append(index_s);
                }
            }
            if (!inode_s.empty())
                out.append(inode_s);
            if ((level & DUMP_TEXT_DIRS) > 0 && (mode & S_IFMT) == S_IFDIR || (level & DUMP_TEXT_ALL) > 0) {
                out.append(text);
                out.append("\x05");
                if (data.exists(i))
                    out.append(data[i]);
            }
        }
    }

    function _lookup_dir(Inode inode, bytes data, string file_name) internal pure returns (uint16 index, uint8 file_type) {
        (index, file_type, ) = _lookup_dir_ext(inode, data, file_name);
    }

    function _lookup_dir_ext(Inode inode, bytes data, string file_name) internal pure returns (uint16 index, uint8 file_type, uint16 dir_idx) {
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return (ENOTDIR, FT_UNKNOWN, 0);
        (DirEntry[] contents, int16 status) = dirent.read_dir(inode, data);
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

    function _get_device_version(uint16 device_id) internal pure returns (string major, string minor) {
        return (format("{}", device_id >> 8), format("{}", device_id & 0xFF));
    }

    function _permissions(uint16 p) internal pure returns (string) {
        return _inode_mode_sign(p) + _permissions_octet(p >> 6 & 0x0007) + _permissions_octet(p >> 3 & 0x0007) + _permissions_octet(p & 0x0007);
    }

    function _permissions_octal(uint16 p) internal pure returns (string) {
        return format("{}{}{}", p >> 6 & 0x0007, p >> 3 & 0x0007, p & 0x0007);
    }

    function _mode(string s) internal pure returns (uint16 mode) {
        mode = _get_def_mode(dirent.file_type(s.substr(0, 1)));
        mode += _string_to_octet(s.substr(1, 3)) << 6;
        mode += _string_to_octet(s.substr(4, 3)) << 3;
        mode += _string_to_octet(s.substr(7, 3));
    }

    function _string_to_octet(string s) internal pure returns (uint16 p) {
        if (s.substr(0, 1) == "r")
            p += 4;
        if (s.substr(1, 1) == "w")
            p += 2;
        if (s.substr(2, 1) == "x")
            p++;
    }

    function _permissions_octet(uint16 p) internal pure returns (string out) {
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

    function _mode_to_file_type(uint16 mode) internal pure returns (uint8) {
        if ((mode & S_IFMT) == S_IFBLK)  return FT_BLKDEV;
        if ((mode & S_IFMT) == S_IFCHR)  return FT_CHRDEV;
        if ((mode & S_IFMT) == S_IFREG)  return FT_REG_FILE;
        if ((mode & S_IFMT) == S_IFDIR)  return FT_DIR;
        if ((mode & S_IFMT) == S_IFLNK)  return FT_SYMLINK;
        if ((mode & S_IFMT) == S_IFSOCK) return FT_SOCK;
        if ((mode & S_IFMT) == S_IFIFO)  return FT_FIFO;
        return FT_UNKNOWN;
    }

    function _file_type_description(uint16 mode) internal pure returns (string) {
        if ((mode & S_IFMT) == S_IFBLK)  return "block special";
        if ((mode & S_IFMT) == S_IFCHR)  return "character special";
        if ((mode & S_IFMT) == S_IFREG)  return "regular";
        if ((mode & S_IFMT) == S_IFDIR)  return "directory";
        if ((mode & S_IFMT) == S_IFLNK)  return "symbolic link";
        if ((mode & S_IFMT) == S_IFSOCK) return "socket";
        if ((mode & S_IFMT) == S_IFIFO)  return "fifo";
        return "unknown";
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

    function _get_any_node(uint8 ft, uint16 owner, uint16 group, uint16 device_id, uint16 n_blocks, string file_name, string text) internal pure returns (Inode, bytes) {
        if (ft > FT_UNKNOWN && ft <= FT_LAST)
            return (Inode(_get_def_mode(ft), owner, group, ft == FT_DIR ? 2 : 1, device_id, n_blocks, uint32(text.byteLength()),  now, now, file_name), text);
    }

    function _get_dots(uint16 this_dir, uint16 parent_dir) internal pure returns (string) {
        return format("d.\t{}\nd..\t{}\n", this_dir, parent_dir);
    }

    function _get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, uint16 device_id, string dir_name) internal pure returns (Inode, bytes) {
        return _get_any_node(FT_DIR, owner, group, device_id, 1, dir_name, _get_dots(this_dir, parent_dir));
    }*/
}
