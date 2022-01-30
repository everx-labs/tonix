pragma ton-solidity >= 0.56.0;

import "../include/fs_types.sol";
import "sb.sol";

library inode {

    uint16 constant ROOT_DIR = 11;

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

    /* Index node, file and directory entry types helpers */
    function get_device_version(uint16 device_id) internal returns (string major, string minor) {
        return (format("{}", device_id >> 8), format("{}", device_id & 0xFF));
    }

    function permissions(uint16 p) internal returns (string) {
        return inode_mode_sign(p) + permissions_octet(p >> 6 & 0x0007) + permissions_octet(p >> 3 & 0x0007) + permissions_octet(p & 0x0007);
    }

    function permissions_octal(uint16 p) internal returns (string) {
        return format("{}{}{}", p >> 6 & 0x0007, p >> 3 & 0x0007, p & 0x0007);
    }

    function mode(string s) internal returns (uint16 imode) {
        imode = get_def_mode(file_type(s.substr(0, 1)));
        imode += string_to_octet(s.substr(1, 3)) << 6;
        imode += string_to_octet(s.substr(4, 3)) << 3;
        imode += string_to_octet(s.substr(7, 3));
    }

    function string_to_octet(string s) internal returns (uint16 p) {
        if (s.substr(0, 1) == "r")
            p += 4;
        if (s.substr(1, 1) == "w")
            p += 2;
        if (s.substr(2, 1) == "x")
            p++;
    }

    function permissions_octet(uint16 p) internal returns (string out) {
        out = ((p & 4) > 0) ? "r" : "-";
        out.append(((p & 2) > 0) ? "w" : "-");
        out.append(((p & 1) > 0) ? "x" : "-");
    }

    function inode_mode_sign(uint16 imode) internal returns (string) {
        if ((imode & S_IFMT) == S_IFBLK)  return "b";
        if ((imode & S_IFMT) == S_IFCHR)  return "c";
        if ((imode & S_IFMT) == S_IFREG)  return "-";
        if ((imode & S_IFMT) == S_IFDIR)  return "d";
        if ((imode & S_IFMT) == S_IFLNK)  return "l";
        if ((imode & S_IFMT) == S_IFSOCK) return "s";
        if ((imode & S_IFMT) == S_IFIFO)  return "p";
    }

    function is_block_dev(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFBLK;
    }

    function is_char_dev(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFCHR;
    }

    function is_reg(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFREG;
    }

    function is_dir(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFDIR;
    }

    function is_symlink(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFLNK;
    }

    function is_socket(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFSOCK;
    }

    function is_pipe(uint16 imode) internal returns (bool) {
        return (imode & S_IFMT) == S_IFIFO;
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

    function mode_to_file_type(uint16 imode) internal returns (uint8) {
        if ((imode & S_IFMT) == S_IFBLK)  return FT_BLKDEV;
        if ((imode & S_IFMT) == S_IFCHR)  return FT_CHRDEV;
        if ((imode & S_IFMT) == S_IFREG)  return FT_REG_FILE;
        if ((imode & S_IFMT) == S_IFDIR)  return FT_DIR;
        if ((imode & S_IFMT) == S_IFLNK)  return FT_SYMLINK;
        if ((imode & S_IFMT) == S_IFSOCK) return FT_SOCK;
        if ((imode & S_IFMT) == S_IFIFO)  return FT_FIFO;
        return FT_UNKNOWN;
    }

    function file_type_description(uint16 imode) internal returns (string) {
        if ((imode & S_IFMT) == S_IFBLK)  return "block special file";
        if ((imode & S_IFMT) == S_IFCHR)  return "character special file";
        if ((imode & S_IFMT) == S_IFREG)  return "regular file";
        if ((imode & S_IFMT) == S_IFDIR)  return "directory";
        if ((imode & S_IFMT) == S_IFLNK)  return "symbolic link";
        if ((imode & S_IFMT) == S_IFSOCK) return "socket";
        if ((imode & S_IFMT) == S_IFIFO)  return "fifo";
        return "unknown";
    }

    function get_def_mode(uint8 ft) internal returns (uint16) {
        if (ft == FT_REG_FILE) return DEF_REG_FILE_MODE;
        if (ft == FT_DIR) return DEF_DIR_MODE;
        if (ft == FT_SYMLINK) return DEF_SYMLINK_MODE;
        if (ft == FT_BLKDEV) return DEF_BLOCK_DEV_MODE;
        if (ft == FT_CHRDEV) return DEF_CHAR_DEV_MODE;
        if (ft == FT_FIFO) return DEF_FIFO_MODE;
        if (ft == FT_SOCK) return DEF_SOCK_MODE;
    }

    function get_any_node(uint8 ft, uint16 owner, uint16 group, uint16 device_id, uint16 n_blocks, string file_name, string text) internal returns (Inode, bytes) {
        if (ft > FT_UNKNOWN && ft <= FT_LAST)
            return (Inode(get_def_mode(ft), owner, group, ft == FT_DIR ? 2 : 1, device_id, n_blocks, uint32(text.byteLength()),  now, now, file_name), text);
    }

    /* Getting an index node of a particular type */
    function get_dots(uint16 this_dir, uint16 parent_dir) internal returns (string) {
        return format("d.\t{}\nd..\t{}\n", this_dir, parent_dir);
    }

    function get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, uint16 device_id, string dir_name) internal returns (Inode, bytes) {
        return get_any_node(FT_DIR, owner, group, device_id, 1, dir_name, get_dots(this_dir, parent_dir));
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
            (uint16 imode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, string file_name) = ino.unpack();
            bytes text = data[i];
            string inode_s;
            if ((level & DUMP_INDEX_HEADERS) > 0) {
                if (form == DUMP_COMPACT)
                    inode_s = fmt.pad(format("{} {} {} {} {} {} {} {} {} {} {}", i, imode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name),
                        inode_size, fmt.ALIGN_LEFT);
                else if (form == DUMP_AS_TEXT)
                    inode_s = format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, imode, owner_id, group_id, n_links, device_id, n_blocks, file_size);
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
            if ((level & DUMP_TEXT_DIRS) > 0 && is_dir(imode) || (level & DUMP_TEXT_ALL) > 0) {
                out.append(text);
                out.append("\x05");
                if (data.exists(i))
                    out.append(data[i]);
            }
        }
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
            (uint16 imode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, imode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
            if (level > 0 && (is_dir(imode) || is_symlink(imode) || level > 1))
                out.append(data[i]);
        }
    }

}
