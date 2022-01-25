pragma ton-solidity >= 0.56.0;

import "../include/fs_types.sol";
import "fmt.sol";
import "dirent.sol";
import "sb.sol";

library fs {

    uint16 constant ROOT_DIR = 11;

    uint16 constant DUMP_SB             = 1;
    uint16 constant DUMP_INDEX_HEADERS  = 2;
    uint16 constant DUMP_TEXT_DIRS      = 4;
    uint16 constant DUMP_TEXT_ALL       = 8;
    uint16 constant DUMP_SB_INODES      = 16;
    uint16 constant DUMP_USER_INODES    = 32;
    uint16 constant DUMP_ALL_INODES     = 48;
    uint16 constant DUMP_FILE_MAPPING   = 64;
    uint16 constant DUMP_INODE_ALL      = DUMP_SB + DUMP_INDEX_HEADERS + DUMP_ALL_INODES + DUMP_TEXT_ALL;

    uint16 constant DUMP_AS_TEXT        = 1;
    uint16 constant DUMP_COMPACT        = 2;
    uint16 constant DUMP_AS_TAR_HEADER  = 3;
    uint16 constant DUMP_AS_TAR_BYTES   = 4;

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

    /* Looks for a file name in the directory entry. Return file index and file type */
    function fetch_dir_entry(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16 ino, uint8 ft) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR);
        if (!inodes.exists(dir))
            return (ENOTDIR, FT_UNKNOWN);
        Inode inode = inodes[dir];
        if ((inode.mode & S_IFMT) != S_IFDIR)
            return (ENOTDIR, FT_UNKNOWN);
        (ino, ft) = lookup_dir(inode, data[dir], name);
    }

    function resolve_absolute_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint16) {
        if (s_path == "/")
            return ROOT_DIR;
        (string s_dir, string s_not_dir) = path.dir(s_path);
        (uint16 ino, ) = fetch_dir_entry(s_not_dir, resolve_absolute_path(s_dir, inodes, data), inodes, data);
        return ino;
    }

    function xpath(string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        return path.strip_path(xpath0(s_arg, wd, inodes, data));
    }

    function xpath0(string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        uint len = s_arg.byteLength();
        if (len > 0 && s_arg.substr(0, 1) == "/")
            return s_arg;
        string cwd = get_absolute_path(wd, inodes, data);
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

    function get_absolute_path(uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        if (dir == ROOT_DIR)
            return "/";
        (uint16 parent, uint8 ft) = fetch_dir_entry("..", dir, inodes, data);
        if (ft != FT_DIR)
            return "/";

        return (parent == ROOT_DIR ? "" : get_absolute_path(parent, inodes, data)) + "/" + inodes[dir].file_name;
    }

    function get_file_contents_at_path(string s_path, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        (string dir_name, string file_name) = path.dir(s_path);
        uint16 dir_index = resolve_absolute_path(dir_name, inodes, data);
        (uint16 file_index, uint8 ft) = lookup_dir(inodes[dir_index], data[dir_index], file_name);
        if (ft == FT_UNKNOWN)
            return "Failed to read file " + file_name + " at path " + dir_name + "\n";
        return get_file_contents(file_index, inodes, data);
    }

    function get_file_contents(uint16 file_index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string) {
        if (!inodes.exists(file_index))
            return format("Inode {} does not exist\n", file_index);
        if (!data.exists(file_index))
            return format("Data {} does not exist\n", file_index);
        return data[file_index];
    }

    /* Looks for a file name in the directory entry. Returns file index */
    function resolve_relative_path(string name, uint16 dir, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns
            (uint16 index, uint8 file_type, uint16 parent, uint16 dir_index) {
        if (name == "/")
            return (ROOT_DIR, FT_DIR, ROOT_DIR, 1);
        parent = name.substr(0, 1) == "/" ? ROOT_DIR : dir;

        (string dir_path, string base_name) = path.dir(name);
        string[] parts = path.disassemble_path(dir_path);
        uint len = parts.length;

        for (uint i = len - 1; i > 0; i--) {
            (uint16 ino, uint8 ft, , uint16 dir_idx) = resolve_relative_path(parts[i - 1], parent, inodes, data);
            if (dir_idx == 0)
                return (ino, ft, parent, dir_idx);
            else if (ft == FT_DIR)
                parent = ino;
            else
                break;
        }
        (index, file_type, dir_index) = lookup_dir_ext(inodes[parent], data[parent], base_name);
    }

    /* File system helpers */
    function dump_fs(uint8 level, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string out) {
        SuperBlock sblk = sb.get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sblk.unpack();
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

    function dumpfs(uint16 level, uint16 form, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (string out) {
        SuperBlock sblk = sb.get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sblk.unpack();
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
                    inode_s = _write_tar_index_entry_bin(ino);*/
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

    function lookup_dir(Inode inode, bytes data, string file_name) internal returns (uint16 index, uint8 file_type) {
        (index, file_type, ) = lookup_dir_ext(inode, data, file_name);
    }

    function lookup_dir_ext(Inode inode, bytes data, string file_name) internal returns (uint16 index, uint8 file_type, uint16 dir_idx) {
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
}
