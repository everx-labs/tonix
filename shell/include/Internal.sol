pragma ton-solidity >= 0.55.0;

import "../include/Errors.sol";
import "../include/Base.sol";
import "../lib/Format.sol";

struct Inode {
    uint16 mode;
    uint16 owner_id;
    uint16 group_id;
    uint16 n_links;
    uint16 device_id;
    uint16 n_blocks;
    uint32 file_size;
    uint32 modified_at;
    uint32 last_modified;
    string file_name;
}

struct SuperBlock {
    bool file_system_state;
    bool errors_behavior;
    string file_system_OS_type;
    uint16 inode_count;
    uint16 block_count;
    uint16 free_inodes;
    uint16 free_blocks;
    uint16 block_size;
    uint32 created_at;
    uint32 last_mount_time;
    uint32 last_write_time;
    uint16 mount_count;
    uint16 max_mount_count;
    uint16 lifetime_writes;
    uint16 first_inode;
    uint16 inode_size;
}

struct SBS {
    uint16 inode_size;
    uint16 inode_count;
    uint16 free_inodes;
    uint16 first_inode;
    uint16 block_size;
    uint16 block_count;
    uint16 free_blocks;
    uint16 first_block;
    uint32 created_at;
    uint32 last_write_time;
    bytes32 file_system_OS_type;
}

struct DirEntry {
    uint8 file_type;
    string file_name;
    uint16 index;
}

struct MountInfo {
    uint8 source_dev_id;
    uint16 source_id;
    uint16 target_mount_point;
    string target_path;
    uint16 options;
}

struct FileMapS {
    uint16 storage_type;
    uint16 start;
    uint16 count;
}

struct FileS {
    uint16 mode;
    uint16 inode;
    uint16 state;
    uint16 bc;
    uint16 n_blk;
    uint32 pos;
    uint32 fize;
    string name;
}

struct ProcessInfo {
    uint16 owner_id;
    uint16 self_id;
    uint16 umask;
    mapping (uint16 => FileS) fd_table;
    string cwd;
}

struct UserInfo {
    uint16 gid;
    string user_name;
    string primary_group;
}

struct GroupInfo {
    string group_name;
    bool is_system;
}

struct Login {
    uint16 user_id;
    uint16 tty_id;
    uint16 process_id;
    uint32 login_time;
}

struct TTY {
    uint8 device_id;
    uint16 user_id;
    uint16 login_id;
}

struct TextDataFile {
    uint8 file_type;
    uint8 n_links;
    string file_name;
    string contents;
}

/* Base contract to work with index nodes */
abstract contract Internal is Base, Format, Errors {

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

    function _get_inode_size(mapping (uint16 => Inode) inodes) internal pure returns (uint16) {
        return inodes[SB_INFO].n_links;
    }

    function _get_inode_count(mapping (uint16 => Inode) inodes) internal pure returns (uint16) {
        return inodes[SB_INODES].owner_id + 1;
    }

    function _claim_inodes_and_blocks(Inode inodes_inode, uint inode_count, uint block_count) internal pure returns (Inode) {
        uint16 i_count = uint16(inode_count);
        uint16 b_count = uint16(block_count);
        if (i_count > 0) {
            inodes_inode.owner_id += i_count;
            inodes_inode.modified_at = now;
        }
        if (b_count > 0) {
            inodes_inode.group_id += b_count;
            inodes_inode.last_modified = now;
        }
        inodes_inode.n_links++;
        return inodes_inode;
    }

    /* Looks for a file name in the directory entry. Return file index and file type */
    function _fetch_dir_entry(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (uint16 ino, uint8 ft) {
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

    function _get_block_size(mapping (uint16 => Inode) inodes) internal pure returns (uint16) {
        return inodes[SB_INFO].n_blocks;
    }

    function _get_device_id(mapping (uint16 => Inode) inodes) internal pure returns (uint16) {
        return inodes[SB_INFO].device_id;
    }

    /* Looks for a file name in the directory entry. Returns file index */
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

    /* File system helpers */
    function _dump_fs(uint8 level, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        SuperBlock sb = _get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();
        out = format("{} IC {} BC {} FI {} FB {} BS {} MC {} MMC {} WR {} FI {} IS {} FSS {} EB {}\n",
            file_system_OS_type, inode_count, block_count, free_inodes, free_blocks, block_size,
            mount_count, max_mount_count, lifetime_writes, first_inode, inode_size, file_system_state ? "Y" : "N", errors_behavior ? "Y" : "N");
        out.append(format("CT {} LMT {} LWT {}\n", _ts(created_at), _ts(last_mount_time), _ts(last_write_time)));

        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
            if (level > 0 && ((mode & S_IFMT) == S_IFDIR || (mode & S_IFMT) == S_IFLNK) || level > 1)
                out.append(data[i]);
        }
    }

    function _dumpfs(uint16 level, uint16 form, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        SuperBlock sb = _get_sb(inodes, data);
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
                out.append(format("CT {} LMT {} LWT {}\n", _ts(created_at), _ts(last_mount_time), _ts(last_write_time)));
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
                    inode_s = _pad(format("{} {} {} {} {} {} {} {} {} {} {}", i, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name),
                        inode_size, ALIGN_LEFT);
                else if (form == DUMP_AS_TEXT)
                    inode_s = format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size);
                else if (form == DUMP_AS_TAR_HEADER)
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

    function _parse_entry(string s) internal pure returns (DirEntry dirent) {
        uint p = stdio.strchr(s, "\t");
        if (p > 1) {
            optional(int) index_u = stoi(s.substr(p));
            if (index_u.hasValue())
                dirent = DirEntry(_file_type(s.substr(0, 1)), s.substr(1, p - 2), uint16(index_u.get()));
            else
                dirent = DirEntry(_file_type(s.substr(0, 1)), s.substr(1, p - 2) + " ?" + s.substr(p) + "? ", ENOENT);
        }
    }

    function _read_dir_data(bytes dir_data) internal pure returns (DirEntry[] contents, int16 status) {
        (string[] lines, ) = stdio.split(dir_data, "\n");
        for (string s: lines)
            contents.push(_parse_entry(s));
        status = int16(contents.length);
    }

    function _read_dir(Inode inode, bytes data) internal pure returns (DirEntry[] contents, int16 status) {
        if ((inode.mode & S_IFMT) != S_IFDIR)
            status = -ENOTDIR;
        else
            return _read_dir_data(data);
    }

    function _get_symlink_target(Inode inode, bytes node_data) internal pure returns (DirEntry target) {
        if ((inode.mode & S_IFMT) != S_IFLNK)
            target.index = ENOSYS;
        else
            return _parse_entry(node_data);
    }

    function _dir_entry_line(uint16 index, string file_name, uint8 file_type) internal pure returns (string) {
        return _file_type_sign(file_type) + file_name + format("\t{}\n", index);
    }

    /* Index node, file and directory entry types helpers */
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
        mode = _get_def_mode(_file_type(s.substr(0, 1)));
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

    function _mode_to_typeflag(uint16 mode) internal pure returns (uint8) {
        if ((mode & S_IFMT) == S_IFBLK)  return TF_BLKDEV;
        if ((mode & S_IFMT) == S_IFCHR)  return TF_CHRDEV;
        if ((mode & S_IFMT) == S_IFREG)  return TF_REG_FILE;
        if ((mode & S_IFMT) == S_IFDIR)  return TF_DIR;
        if ((mode & S_IFMT) == S_IFLNK)  return TF_SYMLINK;
        if ((mode & S_IFMT) == S_IFSOCK) return TF_SOCK;
        if ((mode & S_IFMT) == S_IFIFO)  return TF_FIFO;
    }

    function _file_type_sign(uint8 ft) internal pure returns (string) {
        if (ft == FT_BLKDEV)    return "b";
        if (ft == FT_CHRDEV)    return "c";
        if (ft == FT_REG_FILE)  return "-";
        if (ft == FT_DIR)       return "d";
        if (ft == FT_SYMLINK)   return "l";
        if (ft == FT_SOCK)      return "s";
        if (ft == FT_FIFO)      return "p";
        return "?";
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

    /* Getting an index node of a particular type */
    function _get_dots(uint16 this_dir, uint16 parent_dir) internal pure returns (string) {
        return format("d.\t{}\nd..\t{}\n", this_dir, parent_dir);
    }

    function _get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, uint16 device_id, string dir_name) internal pure returns (Inode, bytes) {
        return _get_any_node(FT_DIR, owner, group, device_id, 1, dir_name, _get_dots(this_dir, parent_dir));
    }

    function _get_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (SuperBlock sb) {
        Inode info_inode = inodes[SB_INFO];
        uint16[] sb_info = _get_sb_data(data[SB_INFO]);
        uint16 total_inodes = info_inode.owner_id; //sb_info[1];
        uint16 total_blocks = info_inode.group_id; // sb_info[2];
        uint32 created_at = info_inode.modified_at;
        uint16 first_inode = ROOT_DIR;// = sb_info[0];
        uint16 inode_size = info_inode.n_links;
        uint16 block_size = info_inode.n_blocks;
        uint16 max_mount_count = 10;

        if (sb_info.length > 5) {
            first_inode = sb_info[0];
            max_mount_count = sb_info[5];
        }

        Inode inodes_inode = inodes[SB_INODES];
        uint16 inode_count = inodes_inode.owner_id;
        uint16 free_inodes = total_inodes - inode_count;
        uint32 last_write_time = inodes_inode.modified_at;
        uint16 lifetime_writes = inodes_inode.n_links;
        uint16 block_count = inodes_inode.group_id;
        uint16 free_blocks = total_blocks - block_count;

        Inode mounts_inode = inodes[SB_MOUNTS];
        uint16[] sb_mounts = _get_sb_data(data[SB_MOUNTS]);
        uint16 mount_count = 0;
        if (!sb_mounts.empty())
            mount_count = sb_mounts[0];
        uint32 last_mount_time = mounts_inode.modified_at;

        (string[] sb_state, ) = _get_sb_text(data[SB_STATE]);
        bool file_system_state = true;
        bool errors_behavior = true;
        string file_system_OS_type;
        if (sb_state.length > 2) {
            file_system_state = sb_state[0] == "Y";
            errors_behavior = sb_state[1] == "Y";
            file_system_OS_type = sb_state[2];
        }

        sb = SuperBlock(file_system_state, errors_behavior, file_system_OS_type, inode_count, block_count, free_inodes, free_blocks,
            block_size, created_at, last_mount_time, last_write_time, mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
    }

    function _get_sb_text(bytes data) internal pure returns (string[] values, uint n_fields) {
        return stdio.split_line(data, " ", "\n");
    }

    function _get_sb_data(bytes data) internal pure returns (uint16[] values) {
        (string[] fields, ) = stdio.split_line(data, " ", "\n");
        for (string s: fields)
            values.push(stdio.atoi(s));
    }

    function _write_tar_index_entry_bin(Inode inode) internal pure returns (string line) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, , , uint32 file_size, uint32 modified_at, , string file_name) = inode.unpack();
        uint8 typeflag = _mode_to_typeflag(mode);
        mode = mode & 0xFFFF;
        uint checksum;// = _byte_sum([mode, owner_id, group_id, file_size, modified_at]);

        line = _pad(file_name, 100, ALIGN_LEFT) + _dec_to_oct(mode, 7) + _dec_to_oct(owner_id, 7) + _dec_to_oct(group_id, 7) +
            _dec_to_oct(file_size, 14) + _dec_to_oct(modified_at, 14) + _dec_to_oct(checksum, 6) + _dec_to_oct(n_links, 1);

        string res; // = _v0(mode);

        uint[] values = [mode, owner_id, group_id, file_size, modified_at, checksum, typeflag];
        uint8[] widths = [8, 8, 8, 12, 12, 8, 1];
        string res2 = _octal_dump(widths, values);
        return res + "\n" + res2;
    }
}
