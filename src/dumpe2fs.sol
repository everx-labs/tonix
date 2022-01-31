pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract dumpe2fs is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , , string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        (bool sb_only, bool image_fs, , , , , , ) = arg.flag_values("hi", flags);

        SuperBlock sblk = sb.get_sb(inodes, data);
        if (sb_only)
            out = sb.display_sb(sblk);

        if (image_fs) {
            string s1 = _dump_e2fs(2, inodes, data);
            string s2 = _dump_e2fs(2, _read_inode_table(data), data);
            out = s1 + "\n\n\n" + s2;
        }
        out = _dump_e2fs(2, inodes, data);
    }

    function _get_parent_offset(string parent, string[] file_list) internal pure returns (uint8 offset) {
        for (uint i = 0; i < file_list.length; i++)
            if (file_list[i] == parent)
                return uint8(i);
    }

    function _read_inode_table(mapping (uint16 => bytes) data) internal pure returns (mapping (uint16 => Inode) inodes) {
        bytes inodes_data = data[SB_INODES_TABLE];
        (string[] records, uint n_records) = stdio.split(inodes_data, "\n");
        for (uint i = 0; i < n_records; i++) {
            string line = records[i];
            (string[] fields, uint n_fields) = stdio.split(line, " ");

            if (n_fields < 10)
                continue;

            uint[] values;
            string[] texts;
            for (string s: fields) {
                optional(int) val = stoi(s);
                if (val.hasValue())
                    values.push(uint(val.get()));
                else
                    texts.push(s);
            }
            uint16 index = uint16(values[0]);
            uint16 mode = uint16(values[1]);
            uint16 owner_id = uint16(values[2]);
            uint16 group_id = uint16(values[3]);
            uint16 n_links = uint16(values[4]);
            uint16 device_id = uint16(values[5]);
            uint16 n_blocks = uint16(values[6]);
            uint32 file_size = uint32(values[7]);
            uint32 modified_at = uint32(values[8]);
            uint32 last_modified = uint32(values[9]);
            string file_name = texts.empty() ? "" : texts[0];

            inodes[index] = Inode(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name);
        }
    }

    function _dump_e2fs(uint8 level, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        SuperBlock sblk = sb.get_sb(inodes, data);
        out = sb.display_sb(sblk);

        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
            if (level > 0 && (inode.is_dir(mode) || inode.is_symlink(mode) || level > 1)) {
                out.append(data[i]);
                out.append("\n");
            }
        }
    }

    function _parse_dir_entries(string contents) internal pure returns (string[] dirents, uint n_dirents) {
        return stdio.split(contents, " ");
    }

    function _inode_string(Inode inode) internal pure returns (string) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , ) = inode.unpack();
        return format("PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", mode, owner_id, group_id, n_links, device_id, n_blocks, file_size);
    }

    function _store_def_inode(Inode inode) internal pure returns (TvmBuilder b) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
        b.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
    }

    function _parse_def_inode(TvmSlice s) internal pure returns (Inode inode) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified) =
            s.decode(uint16, uint16, uint16, uint16, uint16, uint16, uint32, uint32, uint32);
        return Inode(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, "");
    }

    function _builder_string(uint i, TvmBuilder b) internal pure returns (string) {
        (uint16 bits, uint8 refs) = b.size();
        (uint16 rem_bits, uint8 rem_refs) = b.remBitsAndRefs();
        return format("Store {} CUR {} {} REM {} {}\n", i, bits, refs, rem_bits, rem_refs);
    }

    function _size_string(TvmCell c) internal pure returns (string) {
        optional(uint, uint, uint) o = c.dataSizeQ(199);
        (uint n_cells, uint n_bits, uint n_refs) = o.get();
        return format("TOTAL {} cells {} bits {} refs\n", n_cells, n_bits, n_refs);
    }

    function _size_string_s(TvmSlice s) internal pure returns (string) {
        optional(uint, uint, uint) o = s.dataSizeQ(199);
        (uint n_cells, uint n_bits, uint n_refs) = o.get();
        return format("TOTAL {} cells {} bits {} refs\n", n_cells, n_bits, n_refs);
    }

    function _size_string_b(TvmBuilder b) internal pure returns (string) {
        (uint16 bits, uint8 refs) = b.size();
        (uint16 rem_bits, uint8 rem_refs) = b.remBitsAndRefs();
        return format("{} {} {} {}\n", bits, refs, rem_bits, rem_refs);
    }

    function _parse_inodes(TvmCell c) internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, string out) {
        out.append(_size_string(c));
        TvmSlice s_main = c.toSlice();
        out.append(_size_string_s(s_main));

        (uint16 n_dirs, uint16 n_reg_files, uint16 n_other) = s_main.decode(uint16, uint16, uint16);
        TvmSlice s_dirs = s_main.loadRefAsSlice();
        out.append(_size_string_s(s_dirs));

        TvmSlice s_dir_data = s_dirs.loadRefAsSlice();
        out.append(_size_string_s(s_dir_data));
        Inode dir_def_inode = _parse_def_inode(s_dirs);
        for (uint16 i = 0; i < n_dirs; i++) {
            (uint8 index, uint8 n_links, uint16 file_size) = s_dirs.decode(uint8, uint8, uint16);
            Inode dir_inode = dir_def_inode;
            dir_inode.n_links = n_links;
            dir_inode.file_size = file_size;
            bytes dir_data = s_dir_data.decode(bytes);
            inodes[index] = dir_inode;
            data[index] = dir_data;
        }

        TvmSlice s_reg_files = s_main.loadRefAsSlice();
        out.append(_size_string_s(s_reg_files));
        Inode reg_def_inode = _parse_def_inode(s_reg_files);
        for (uint16 i = 0; i < n_reg_files; i++) {
            (uint8 index, uint16 file_size) = s_reg_files.decode(uint8, uint16);
            Inode reg_inode = reg_def_inode;
            reg_inode.file_size = file_size;
            inodes[index] = reg_inode;
        }

        TvmSlice s_other = s_main.loadRefAsSlice();
        out.append(_size_string_s(s_other));
        Inode other_def_inode = _parse_def_inode(s_other);
        for (uint16 i = 0; i < n_other; i++) {
            (uint8 index, uint16 file_size) = s_other.decode(uint8, uint16);
            Inode inode = other_def_inode;
            inode.file_size = file_size;
            inodes[index] = inode;
        }

    }

    function view_inode(Inode inode) external pure returns (string) {
        TvmBuilder b = _read(inode);
        (uint16 bits, uint8 refs) = b.size();
        (uint16 rem_bits, uint8 rem_refs) = b.remBitsAndRefs();
        return format("{} {} {} {}\n", bits, refs, rem_bits, rem_refs);
    }

    function _read(Inode inode) internal pure returns (TvmBuilder b) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
        b.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
    }
    uint16 constant DEVFS_INODES_INODE  = 0;
    uint16 constant DEVFS_DEV_DIR       = 1;

    function parse_fs(string text) external pure returns (string out, mapping (uint16 => Inode) inodes) {
        return _parsefs(text);
    }

    function _parse_values(string line) internal pure returns (uint[] values) {
        (string[] fields, ) = stdio.split(line, " ");
        for (string s: fields) {
            values.push(str.toi(s));
        }
    }

    function _parse_sb_inode(string line) internal pure returns (uint16 index, Inode inode) {
        string index_s = line.substr(0, fs.DEF_INODE_SIZE);
        (string[] fields, ) = stdio.split(index_s, " ");
        uint[] values;

        for (string s: fields)
            values.push(str.toi(s));

        return (uint16(values[0]), Inode(uint16(values[1]), uint16(values[2]), uint16(values[3]), uint16(values[4]), uint16(values[5]), uint16(values[6]), uint32(values[7]),
            uint32(values[8]), uint32(values[9]), fields[10]));
    }

    function _parsefs(string text_stream) internal pure returns (string out, mapping (uint16 => Inode) inodes) {
        uint len = text_stream.byteLength();
        (string[] frs, uint frs_len) = stdio.split(text_stream, "\x05");
        out.append(format("Parsing {} bytes, {} records\n", len, frs_len));

        for (uint i = 0; i < frs_len; i++) {
            string line = frs[i];
            uint line_len = line.byteLength();
            if (line_len > fs.DEF_INODE_SIZE) {
                (uint16 index, Inode inode) = _parse_sb_inode(line);
                inodes[index] = inode;
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"dumpe2fs",
"[ -bfghixV ] device",
"dump ext2/ext3/ext4 filesystem information",
"Prints the super block and blocks group information for the filesystem present on device.",
"-h     only display the superblock information and not any of the block group descriptor detail information\n\
-i      display the filesystem data from an image file created by e2image, using device as the pathname to the image file",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
