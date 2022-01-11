pragma ton-solidity >= 0.51.0;

import "../lib/Format.sol";
import "Utility.sol";

/* Primary configuration files for a block device system initialization and error diagnostic data */
contract mke2fs is Format, Utility {

    function exec(string config) external pure returns (string out, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {

        /*bool use_block_size = (flags & _b) > 0;
        bool use_root_dir = (flags & _d) > 0;
        bool use_inode_size = (flags & _I) > 0;
        bool ext3_journal = (flags & _j) > 0;
        bool dry_run = (flags & _n) > 0;
        bool sb_only = (flags & _S) > 0;*/

        (inodes, data) = _get_system_init(config);
    }

    function _get_parent_offset(string parent, string[] file_list) internal pure returns (uint8 offset) {
        for (uint i = 0; i < file_list.length; i++)
            if (file_list[i] == parent)
                return uint8(i);
    }

    function get_device_fs(string devices) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return _get_device_fs(devices);
    }

    function t_mkfs(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
        (inodes, data) = _get_system_init(config);
//        return _mkfs(config);
    }
    function t_mkfs_2(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
        return _mkfs(config);
    }
    function _mkfs(string config) internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
//        (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, string s_out) = _get_system_init_2(config);
        return _get_system_init_2(config);
//        (c, out) = _store_inodes(inodes);
//        (c, out) = _store_inodes_and_dirs(inodes, data);
    }
/*
m2:b:c:5 0 100 6000
sysfs:-:c:11 100 6000 60 100
/:d:d:bin dev etc mnt proc sys usr
*/
    function _parse_config_line(string line) internal pure returns (string name, uint8 node_type, uint8 content_type, bytes content) {
        (string[] fields, uint n_fields) = _split_line(line, ":", "\n");
        if (n_fields > 3) {
            name = fields[0];
            node_type = _file_type(fields[1]);
            content_type = _file_type(fields[2]);
            content = fields[3];
        }
    }

    function _parse_blkdev(string contents) internal pure returns (uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks) {
        uint[] values = _parse_values(contents);
        if (values.length > 3) {
            major_id = uint8(values[0]);
            minor_id = uint8(values[1]);
            block_size = uint16(values[2]);
            n_blocks = uint16(values[3]);
        }
    }

    function _parse_sbinfo(string contents) internal pure returns (uint16 first_inode, uint16 block_size, uint16 n_blocks, uint16 inode_size, uint16 n_inodes) {
        uint[] values = _parse_values(contents);
        if (values.length > 4) {
            first_inode = uint16(values[0]);
            block_size = uint16(values[1]);
            n_blocks = uint16(values[2]);
            inode_size = uint16(values[3]);
            n_inodes = uint16(values[4]);
        }
    }

    function _parse_dir_entries(string contents) internal pure returns (string[] dirents, uint n_dirents) {
        return _split(contents, " ");
    }

    function _process_config_line(string line) internal pure returns (TvmBuilder b) {
        (string name, uint8 node_type, uint8 content_type, bytes content) = _parse_config_line(line);
        if (node_type == FT_BLKDEV) {
            (uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks) = _parse_blkdev(content);
            uint16 device_id = (uint16(major_id) << 8) + minor_id;
            b.store(device_id, block_size, n_blocks);
        } else if (node_type == FT_SOCK) {
            (uint16 first_inode, uint16 block_size, uint16 n_blocks, uint16 inode_size, uint16 n_inodes) = _parse_sbinfo(content);
            b.store(first_inode, block_size, n_blocks, inode_size, n_inodes);
        } else if (node_type == FT_DIR) {
            (string[] dirents, uint n_dirents) = _parse_dir_entries(content);
            for (uint i = 0; i < n_dirents; i++) {
                b.store(dirents[i]);
            }
        }

    }

//    function _get_system_init_2(string config) internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, string out) {
    function _get_system_init_2(string config) internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
        uint8 n = 0;
        (string[] config_lines, uint config_line_count) = _split(config, "\n");
//        DeviceInfo host_device_info = _parse_device_info(config_lines[0]);
        /*(string[] fields, uint n_fields) = _split_line(config_lines[0], ":", "\n");
        string device_name;
        if (n_fields > 0)
            device_name = fields[0];*/

        DeviceInfo host_device_info;
        uint16 host_device_id;
        uint16 block_size;
        uint16 block_count;
        string[] file_list = ["/"];

        uint16 n_dirs;
        uint16 n_reg_files;
        uint16 n_other;
//        TvmBuilder b_main = _read(inodes[SB_INFO]);
//        Inode def_inode = inodes[1];
//        (uint16 def_mode, uint16 def_owner_id, uint16 def_group_id, , uint16 def_device_id, , , uint32 def_modified_at, uint32 def_last_modified, ) = def_inode.unpack();

        TvmBuilder b_dev = _process_config_line(config_lines[0]);
        TvmBuilder b_info = _process_config_line(config_lines[1]);

//        TvmBuilder b_main = _store_def_inode(inodes[0]);
        TvmBuilder b_main;
        b_main.store(b_dev);
        b_main.store(b_info);
        TvmBuilder b_dirs;// = _store_def_inode(inodes[ROOT_DIR]);
//        TvmBuilder b_main = _def_inode(inodes[1]);
//        TvmBuilder b_main = _read(inodes[SB_INFO]);
//        out.append(_builder_string(0, b_main));
//        out.append(_builder_string(1, b_dirs));
//        out.append(_builder_string(1, b_dirs));
        TvmBuilder b_reg_files;// = _store_def_inode(inodes[5]);
        TvmBuilder b_dir_data;
        out.append(_builder_string(2, b_reg_files));
        TvmBuilder b_other;// = _store_def_inode(inodes[1]);
        out.append(_builder_string(3, b_other));
        /*for ((uint16 i, Inode inode): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
            if ((mode & S_IFMT) == S_IFDIR) {
//                b_dirs.store(i, n_links, uint16(file_size));
                bytes dir_data;// = data[i];
                out.append(format("dir data: {}\n", dir_data.length));
                n_dirs++;
                (, uint n_items) = _split(dir_data, "\n");
//                b_dirs.store(uint8(i), uint8(n_links), uint16(file_size));
                b_dirs.store(uint8(n_dirs), uint8(n_items), uint16(dir_data.length));
                out.append(_builder_string(1, b_dirs));
//                b_dir_data.store(dir_data);
                out.append(_builder_string(4, b_dir_data));
            }
            else if ((mode & S_IFMT) == S_IFREG) {
                b_reg_files.store(uint8(i), uint16(file_size));
                out.append(_builder_string(2, b_reg_files));
                n_reg_files++;
            } else {
                b_other.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
                out.append(_builder_string(3, b_other));
                n_other++;
            }
            /*inodes_in_cur_cell++;
            if (inodes_in_cur_cell >= max_inodes_per_cell) {
                TvmCell ref_c = ref_b.toCell();
                b.store(ref_c);
                delete ref_b;
                inodes_in_cur_cell = 0;
                cur_cells++;
            }
        }*/
//        TvmBuilder b = _read(inode);
        b_main.store(n_dirs, n_reg_files, n_other);
        b_dirs.store(n_dirs);
//        b_dirs.store(def_dir_mode, def_owner_id, def_group_id, def_group_n_links, def_device_id, def_dir_n_blocks, def_dir_file_size, def_modified_at, def_last_modified);
        b_dirs.storeRef(b_dir_data);

        b_reg_files.store(n_reg_files);
//        b_reg_files.store(def_reg_file_mode, def_owner_id, def_group_id, def_reg_file_n_links, def_device_id, def_reg_file_n_blocks, def_reg_file_file_size, def_modified_at, def_last_modified);

        b_other.store(n_other);
//        b_other.store(def_other_mode, def_owner_id, def_group_id, def_other_n_links, def_device_id, def_other_n_blocks, def_other_file_size, def_modified_at, def_last_modified);

        out.append(_builder_string(0, b_main));
        b_main.storeRef(b_dirs);
        out.append(_builder_string(0, b_main));
        b_main.storeRef(b_reg_files);
        out.append(_builder_string(0, b_main));
        b_main.storeRef(b_other);
        out.append(_builder_string(0, b_main));
        c = b_main.toCell();
        out.append(_size_string(c));

        for (uint j = 0; j < config_line_count; j++) {
//            DeviceInfo host_device_info = _parse_device_info(config_lines[0]);
            /*if (j == 0) {
                (inodes[n], data[n]) = _get_any_node(FT_DIR, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, _get_dots(n, n));
                continue;
            }&*/
            string line = config_lines[j];
            (string node_file_name, uint8 node_type, uint8 content_type, bytes content) = _parse_config_line(line);
            /*(string[] fields, uint n_fields) = _split(line, ":");
            string node_file_name = fields[0];
            uint8 node_type = _file_type(fields[1]);
            uint8 content_type = _file_type(fields[2]);*/
            uint8 node_index = _get_parent_offset(node_file_name, file_list);
            uint8 parent_node_index = _get_parent_offset(file_list[node_index], file_list);

            if (content_type == FT_REG_FILE || content_type == FT_DIR) {
                string dir_contents;
                dir_contents = content; //fields[3];
                (string[] files, uint n_files) = _split_line(dir_contents, " ", "\n");
                for (uint i = 0; i < n_files; i++) {
                    string file_name = files[i];
                    n++;
                    (inodes[n], data[n]) = _get_any_node(content_type, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, content_type == FT_DIR ? _get_dots(n, node_index) : "");
                    bytes dirent = _dir_entry_line(n, file_name, content_type);
                    inodes[parent_node_index].file_size += uint32(dirent.length);
                    inodes[parent_node_index].n_links++;
                    data[parent_node_index].append(dirent);
                }
            } else if (content_type == FT_CHRDEV) {

            }
//            bytes contents;
            if (node_type == FT_DIR) {
                string dir_contents;
//                dir_contents = fields[3];
                dir_contents = content;
                (string[] files, ) = _split_line(dir_contents, " ", "\n");

                    for (string file_name: files) {
                        n++;
                        file_list.push(file_name);
                        if (file_name != ROOT) {
                            (inodes[n], data[n]) = _get_any_node(content_type, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, content_type == FT_DIR ? _get_dots(n, node_index) : "");
                            bytes dirent = _dir_entry_line(n, file_name, content_type);
                            inodes[parent_node_index].file_size += uint32(dirent.length);
                            inodes[parent_node_index].n_links++;
                            data[parent_node_index].append(dirent);
                        } //else
//                            (inodes[n], data[n]) = _get_any_node(FT_DIR, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, _get_dots(n, n));
//                        block_count++;
                    }
            } else if (node_type == FT_BLKDEV) {
                host_device_info = _parse_device_info(line);
                host_device_id = (uint16(host_device_info.major_id) << 8) + host_device_info.minor_id;
                block_size = host_device_info.blk_size;
            }
        }
    }

    function _inode_string(Inode inode) internal pure returns (string) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = inode.unpack();
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
//            bytes file_data = s_dir_data.decode(bytes);
            inodes[index] = reg_inode;
//            data[index] = dir_data;
        }

        TvmSlice s_other = s_main.loadRefAsSlice();
        out.append(_size_string_s(s_other));
        Inode other_def_inode = _parse_def_inode(s_other);
        for (uint16 i = 0; i < n_other; i++) {
            (uint8 index, uint16 file_size) = s_other.decode(uint8, uint16);
            Inode inode = other_def_inode;
            inode.file_size = file_size;
//            bytes file_data = s_dir_data.decode(bytes);
            inodes[index] = inode;
//            data[index] = dir_data;
        }

    }

    function _store_inodes_and_dirs(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (TvmCell c, string out) {
        Inode inodes_inode = inodes[SB_INODES];
        out.append("Inodes inode: " + _inode_string(inodes_inode));
//        uint16 inode_count = inodes_inode.owner_id;
//        uint max_inodes_per_cell = 5;//1023 / 192;
//        uint n_cells = inode_count / max_inodes_per_cell;
//        uint inodes_in_cur_cell;
//        uint cur_cells;
        uint16 n_dirs;
        uint16 n_reg_files;
        uint16 n_other;
//        TvmBuilder b_main = _read(inodes[SB_INFO]);
//        Inode def_inode = inodes[1];
//        (uint16 def_mode, uint16 def_owner_id, uint16 def_group_id, , uint16 def_device_id, , , uint32 def_modified_at, uint32 def_last_modified, ) = def_inode.unpack();
        TvmBuilder b_main = _store_def_inode(inodes[0]);
        TvmBuilder b_dirs = _store_def_inode(inodes[ROOT_DIR]);
//        TvmBuilder b_main = _def_inode(inodes[1]);
//        TvmBuilder b_main = _read(inodes[SB_INFO]);
//        out.append(_builder_string(0, b_main));
//        out.append(_builder_string(1, b_dirs));
//        out.append(_builder_string(1, b_dirs));
        TvmBuilder b_reg_files = _store_def_inode(inodes[5]);
        TvmBuilder b_dir_data;
        out.append(_builder_string(2, b_reg_files));
        TvmBuilder b_other = _store_def_inode(inodes[1]);
        out.append(_builder_string(3, b_other));
        for ((uint16 i, Inode inode): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
            if ((mode & S_IFMT) == S_IFDIR) {
//                b_dirs.store(i, n_links, uint16(file_size));
                bytes dir_data = data[i];
                out.append(format("dir data: {}\n", dir_data.length));
                n_dirs++;
                (, uint n_items) = _split(dir_data, "\n");
//                b_dirs.store(uint8(i), uint8(n_links), uint16(file_size));
                b_dirs.store(uint8(n_dirs), uint8(n_items), uint16(dir_data.length));
                out.append(_builder_string(1, b_dirs));
//                b_dir_data.store(dir_data);
                out.append(_builder_string(4, b_dir_data));
            }
            else if ((mode & S_IFMT) == S_IFREG) {
                b_reg_files.store(uint8(i), uint16(file_size));
                out.append(_builder_string(2, b_reg_files));
                n_reg_files++;
            } else {
                b_other.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
                out.append(_builder_string(3, b_other));
                n_other++;
            }
        }
        b_main.store(n_dirs, n_reg_files, n_other);
        b_dirs.store(n_dirs);
//        b_dirs.store(def_dir_mode, def_owner_id, def_group_id, def_group_n_links, def_device_id, def_dir_n_blocks, def_dir_file_size, def_modified_at, def_last_modified);
        b_dirs.storeRef(b_dir_data);

        b_reg_files.store(n_reg_files);
//        b_reg_files.store(def_reg_file_mode, def_owner_id, def_group_id, def_reg_file_n_links, def_device_id, def_reg_file_n_blocks, def_reg_file_file_size, def_modified_at, def_last_modified);

        b_other.store(n_other);
//        b_other.store(def_other_mode, def_owner_id, def_group_id, def_other_n_links, def_device_id, def_other_n_blocks, def_other_file_size, def_modified_at, def_last_modified);

        out.append(_builder_string(0, b_main));
        b_main.storeRef(b_dirs);
        out.append(_builder_string(0, b_main));
        b_main.storeRef(b_reg_files);
        out.append(_builder_string(0, b_main));
        b_main.storeRef(b_other);
        out.append(_builder_string(0, b_main));
        c = b_main.toCell();
        out.append(_size_string(c));
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

    function _get_device_fs(string devices) internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 n = DEVFS_DEV_DIR;
        (string[] device_list, ) = _split(devices, "\n");

        uint16 host_device_id = 0;//(uint16(host_device_info.major_id) << 8) + host_device_info.minor_id;
        uint16 block_size = 100;//host_device_info.blk_size;
        uint16 block_count;
        string contents;
        (inodes[n], data[n]) = _get_any_node(FT_DIR, SUPER_USER, SUPER_USER_GROUP, host_device_id, 0, "/dev", _get_dots(DEVFS_DEV_DIR, DEVFS_DEV_DIR));
        uint16 node_index = n;
        n++;

        for (string device_info: device_list) {
            (string[] dev_fields, uint n_fields) = _split(device_info, "\t");
            if (n_fields > 3) {
                string file_name = dev_fields[2];
                n++;
                (inodes[n], data[n]) = _get_any_node(FT_BLKDEV, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, device_info);
                bytes dirent = _dir_entry_line(n, file_name, FT_BLKDEV);
                inodes[node_index].file_size += uint32(dirent.length);
                inodes[node_index].n_links++;
                data[node_index].append(dirent);
            }
        }

        uint32 fsize = contents.byteLength();
        block_count += uint16(fsize / block_size);
        Inode inode = inodes[node_index];
        inode.file_size += fsize;
        data[node_index].append(contents);
        inodes[node_index] = inode;

        Inode inodes_inode = inodes[DEVFS_INODES_INODE];
        inodes_inode.owner_id = n;
        inodes_inode.group_id = n;
        inodes[DEVFS_INODES_INODE] = inodes_inode;
    }

    function _get_user_id(string user_name) internal pure returns (uint16) {
        if (user_name == "root")
            return SUPER_USER;
        if (user_name == "boris")
            return REG_USER;
        if (user_name == "ivan")
            return REG_USER + 1;
        if (user_name == "guest")
            return GUEST_USER;
    }

    function _get_group_id(string group_name) internal pure returns (uint16) {
        if (group_name == "root")
            return SUPER_USER_GROUP;
        if (group_name == "staff")
            return REG_USER_GROUP;
        if (group_name == "boris")
            return REG_USER_GROUP;
        if (group_name == "guest")
            return GUEST_USER_GROUP;
    }

    function parse_fs(string text) external pure returns (string out, mapping (uint16 => Inode) inodes) {
        return _parsefs(text);
    }

    function _parse_values(string line) internal pure returns (uint[] values) {
        (string[] fields, ) = _split(line, " ");
        for (string s: fields) {
            optional(int) val = stoi(s);
            values.push(val.hasValue() ? uint(val.get()) : 0);
        }
    }

    function _parse_sb_inode(string line) internal pure returns (uint16 index, Inode inode) {
        string index_s = line.substr(0, DEF_INODE_SIZE);
        (string[] fields, ) = _split(index_s, " ");
        uint[] values;

        for (string s: fields) {
            optional(int) val = stoi(s);
            values.push(val.hasValue() ? uint(val.get()) : 0);
        }
        return (uint16(values[0]), Inode(uint16(values[1]), uint16(values[2]), uint16(values[3]), uint16(values[4]), uint16(values[5]), uint16(values[6]), uint32(values[7]),
            uint32(values[8]), uint32(values[9]), fields[10]));
    }

    function _parsefs(string text_stream) internal pure returns (string out, mapping (uint16 => Inode) inodes) {
        uint len = text_stream.byteLength();
        (string[] frs, uint frs_len) = _split(text_stream, "\x05");
        out.append(format("Parsing {} bytes, {} records\n", len, frs_len));

        for (uint i = 0; i < frs_len; i++) {
            string line = frs[i];
            uint line_len = line.byteLength();
            if (line_len > DEF_INODE_SIZE) {
                (uint16 index, Inode inode) = _parse_sb_inode(line);
                inodes[index] = inode;
            }
        }
    }
    function process_system_init(uint16 mode, string config) external pure returns (string out) {
        uint16 level = mode & 0xFF;
        uint16 form = (mode >> 8) & 0xFF;
//        (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) = _get_system_init(config, devices);
        (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) = _get_system_init(config);
        return _dumpfs(level, form, inodes, data);
    }

    function get_system_init(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return _get_system_init(config);
    }

    function _parse_device_info(string dev_info_s) internal pure returns (DeviceInfo dev_info) {
        (uint[] values, string[] names, address[] addresses) = _parse_record(dev_info_s, "\t");
        return DeviceInfo(uint8(values[0]), uint8(values[1]), names[0], uint16(values[2]), uint16(values[3]), addresses[0]);
    }

    function _parse_device_info_2(string dev_info_s) internal pure returns (string dev_name, uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks, uint16 device_id) {
        (string name, uint8 node_type, uint8 content_type, bytes content) = _parse_config_line(dev_info_s);
        if (node_type == FT_BLKDEV) {
            dev_name = name;
            (major_id, minor_id, block_size, n_blocks) = _parse_blkdev(content);
            device_id = (uint16(major_id) << 8) + minor_id;
        }
    }

    function _get_bare_fs() internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 n = 0;
        uint16 block_size = DEF_BLOCK_SIZE;
        uint16 n_blocks = MAX_BLOCKS;
        uint16 host_device_id = 0;
        uint16 block_count;

        n = ROOT_DIR;
        (inodes[n], data[n]) = _get_any_node(FT_DIR, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, ROOT, _get_dots(n, n));
        block_count++;

        SuperBlock sb = _get_default_sb("bfs", DEF_BLOCK_SIZE, n, inodes, data);
        bytes inodes_dump = _write_inodes(inodes, data);

        data[SB_INODES_TABLE] = inodes_dump;
        bytes sb_dump = _write_sb(inodes, data);
        data[SB] = sb_dump;
    }

    function _get_system_init(string config) internal pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint8 n = 0;
        string[] file_list = ["sb_set"];
        (string[] config_lines, uint config_line_count) = _split(config, "\n");
//        DeviceInfo host_device_info = _parse_device_info(config_lines[0]);
        (, , , uint16 block_size, uint16 n_blocks, uint16 host_device_id) = _parse_device_info_2(config_lines[0]);
//        uint16 host_device_id = (uint16(host_device_info.major_id) << 8) + host_device_info.minor_id;
  //      uint16 block_size = host_device_info.blk_size;
        uint16 block_count;

        for (uint j = 1; j < config_line_count; j++) {
            string line = config_lines[j];
            (string node_file_name, uint8 node_type, uint8 content_type, bytes content) = _parse_config_line(line);
            /*(string[] fields, uint n_fields) = _split(line, ":");
            string node_file_name = fields[0];
            uint8 node_type = _file_type(fields[1]);
            uint8 content_type = _file_type(fields[2]);*/
            uint8 node_index = _get_parent_offset(node_file_name, file_list);
            uint8 parent_node_index = _get_parent_offset(file_list[node_index], file_list);
            bytes contents;
            if (node_type == FT_DIR) {
                if (content_type == FT_REG_FILE || content_type == FT_DIR || content_type == FT_SYMLINK) {
                    string dir_contents;
                    if (content_type == FT_SYMLINK) {
                        string source = content; //fields[3];
                        uint8 source_index = _get_parent_offset(source, file_list);
                        dir_contents = data[source_index];
                    } else
                        dir_contents = content; //fields[3];
                    (string[] files, ) = _split_line(dir_contents, " ", "\n");
                    for (string file_name: files) {
                        n++;
                        file_list.push(file_name);
                        if (file_name != ROOT) {
                            (inodes[n], data[n]) = _get_any_node(content_type, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, content_type == FT_DIR ? _get_dots(n, node_index) : "");
                            bytes dirent = _dir_entry_line(n, file_name, content_type);
                            inodes[parent_node_index].file_size += uint32(dirent.length);
                            inodes[parent_node_index].n_links++;
                            data[parent_node_index].append(dirent);
                        } else
                            (inodes[n], data[n]) = _get_any_node(FT_DIR, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, _get_dots(n, n));
                        block_count++;
                    }
                }
            } else if (node_type == FT_REG_FILE) {
                if (content_type == FT_REG_FILE) {
                    contents.append(content);
                } else if (content_type == FT_SOCK) {
//                    if (node_file_name == "hostname") {
//                        contents = format("{}\n{}\n", host_device_info.name, host_device_info.device_address);
                    if (node_file_name == "sb_device_info")
                        contents = config_lines[0];
                } else if (content_type == FT_SYMLINK) {
                    string source = content; //fields[3];
                    uint8 source_index = _get_parent_offset(source, file_list);
                    contents = data[source_index];
                }
            }
            uint32 fsize = uint32(contents.length);
            block_count += uint16(fsize / block_size);
            Inode inode = inodes[node_index];
            inode.file_size += fsize;
            data[node_index].append(contents);
            inodes[node_index] = inode;
        }

        Inode info_inode = inodes[SB_INFO];
        bytes info = data[SB_INFO];
        uint16[] sb_info;
        (string[] fields, ) = _split_line(info, " ", "\n");
        for (string s: fields)
            sb_info.push(uint16(_atoi(s)));

        uint16 total_inodes = sb_info[1];
        uint16 total_blocks = sb_info[2];
        uint16 inode_size = sb_info[3];
        uint16 target_block_size = sb_info[4];

        info_inode.owner_id = total_inodes;
        info_inode.group_id = total_blocks;
        info_inode.n_links = inode_size;
        info_inode.n_blocks = target_block_size;
        info_inode.device_id = host_device_id;
        info_inode.modified_at = now;
        inodes[SB_INFO] = info_inode;

        Inode inodes_inode = inodes[SB_INODES];
        uint16 inode_count = n;
        uint16 free_inodes = total_inodes - n;
        uint16 free_blocks = total_blocks - n;

        inodes_inode.owner_id = inode_count;
        inodes_inode.group_id = block_count;

        string inodes_data = format("{} {} {}\n", inode_count, free_inodes, ROOT_DIR);
        string blocks_data = format("{} {} {}\n", block_count, free_blocks, ROOT_DIR);
        inodes_data.append(blocks_data);
        inodes[SB_INODES] = inodes_inode;
        data[SB_INODES] = inodes_data;
        bytes sb_dump = _write_sb(inodes, data);
        data[SB] = sb_dump;
        bytes inodes_dump = _write_inodes(inodes, data);
        data[SB_INODES_TABLE] = inodes_dump;
    }

    function _get_default_sb(string name, uint16 block_size, uint16 first_inode, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (SuperBlock sb) {
        uint16 inode_count;
        uint16 block_count;
        for ((uint16 i, Inode inode): inodes) {
            inode_count++;
            block_count++;
        }
        for ((uint16 i, bytes bts): data)
            block_count += uint16(bts.length / block_size) + 1;

        return SuperBlock(true, true, name, inode_count, block_count, MAX_INODES - inode_count - first_inode, MAX_BLOCKS - block_count,
            block_size, now, 0, now, 0, 0, 1, first_inode, DEF_INODE_SIZE);
    }

    /*function _update_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (SuperBlock sb) {
        SuperBlock psb = _read_sb(inodes, data);
        uint16 inode_count;
        uint16 block_count;
        for ((uint16 i, Inode inode): inodes) {
            inode_count++;
            block_count++;
        }
        for ((uint16 i, bytes bts): data)
            block_count += uint16(bts.length / block_size) + 1;

        psb.inode_count += inode_count;
        return SuperBlock(true, true, name, inode_count, block_count, MAX_INODES - inode_count - first_inode, MAX_BLOCKS - block_count,
            block_size, now, 0, now, 0, 0, 1, first_inode, DEF_INODE_SIZE);
    }*/

    function _write_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (bytes out) {
        SuperBlock sb = _get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();
        out = format("{} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}\n",
            file_system_state ? "Y" : "N", errors_behavior ? "Y" : "N", file_system_OS_type, inode_count, block_count, free_inodes, free_blocks, block_size, created_at, last_mount_time, last_write_time,
            mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
    }

    function _write_inodes(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (bytes out) {
        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, string file_name) = ino.unpack();
            out.append(format("{} {} {} {} {} {} {} {} {} {} {}\n", i, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name));
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("mke2fs", "build a Tonix filesystem", "[options] [fs-options] device [size]",
            "Used to build a Tonix filesystem on a device.",
            "bdIjnS", 1, M, [
            "specify the size of blocks in bytes",
            "copy the contents of the given directory into the root directory of the filesystem",
            "specify the size of each inode in bytes",
            "create the filesystem with an ext3 journal",
            "not actually create a filesystem, but display what it would do if it were to create a filesystem",
            "write superblock and group descriptors only"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}