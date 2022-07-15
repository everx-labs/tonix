pragma ton-solidity >= 0.62.0;

import "sb.sol";
import "libstat.sol";

library inode {

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
    function get_device_version(uint16 device_id) internal returns (string, string) {
        return (format("{}", device_id >> 8), format("{}", device_id & 0xFF));
    }

    function permissions(uint16 p) internal returns (string) {
        return libstat.sign(p) + permissions_octet(p >> 6 & 0x0007) + permissions_octet(p >> 3 & 0x0007) + permissions_octet(p & 0x0007);
    }

    function permissions_octal(uint16 p) internal returns (string) {
        return format("{}{}{}", p >> 6 & 0x0007, p >> 3 & 0x0007, p & 0x0007);
    }

    function mode(string s) internal returns (uint16 imode) {
        imode = libstat.get_def_mode(libstat.file_type(s.substr(0, 1)));
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

    function get_any_node(uint8 t, uint16 owner, uint16 group, uint16 device_id, uint16 n_blocks, string file_name, string text) internal returns (Inode, bytes) {
        if (t > libstat.FT_UNKNOWN && t <= libstat.FT_LAST)
            return (Inode(libstat.get_def_mode(t), owner, group, t == libstat.FT_DIR ? 2 : 1, device_id, n_blocks, uint32(text.byteLength()),  now, now, file_name), text);
    }

    /* Getting an index node of a particular type */
    function get_dots(uint16 this_dir, uint16 parent_dir) internal returns (string) {
        return format("d.\t{}\nd..\t{}\n", this_dir, parent_dir);
    }

    function get_dir_node(uint16 this_dir, uint16 parent_dir, uint16 owner, uint16 group, uint16 device_id, string dir_name) internal returns (Inode, bytes) {
        return get_any_node(libstat.FT_DIR, owner, group, device_id, 1, dir_name, get_dots(this_dir, parent_dir));
    }

    function bare() internal returns (Inode) {
        return Inode(0, 0, 0, 0, 0, 0, 0, now, now, "");
    }

    function set_dots(Inode ino, uint16 this_dir, uint16 parent_dir) internal {
        string dots = format("d.\t{}\nd..\t{}\n", this_dir, parent_dir);
        ino.file_name = dots;
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
            if (i < sb.ROOT_DIR && (level & DUMP_SB_INODES) == 0 ||
                i > sb.ROOT_DIR && (level & DUMP_USER_INODES) == 0)
                    continue;
            (uint16 imode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, string file_name) = ino.unpack();
            bytes text = data[i];
            string inode_s;
            if ((level & DUMP_INDEX_HEADERS) > 0) {
                if (form == DUMP_COMPACT)
                    inode_s = fmt.pad(format("{} {} {} {} {} {} {} {} {} {} {}", i, imode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name),
                        inode_size, fmt.LEFT);
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
            if ((level & DUMP_TEXT_DIRS) > 0 && libstat.is_dir(imode) || (level & DUMP_TEXT_ALL) > 0) {
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
            if (level > 0 && (libstat.is_dir(imode) || libstat.is_symlink(imode) || level > 1))
                out.append(data[i]);
        }
    }
}
