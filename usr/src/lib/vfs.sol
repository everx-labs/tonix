pragma ton-solidity >= 0.62.0;

import "udirent.sol";
import "pw.sol";
import "gr.sol";
import "sb.sol";

struct DeviceInfo {
    uint8 major_id;
    uint8 minor_id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
    address device_address;
}

library vfs {

    using libstring for string;
    /* Size/string helpers */
    function size_strings(TvmSlice s) internal returns (string) {
        optional(uint, uint, uint) o = s.dataSizeQ(199);
        (uint n_cells, uint n_bits, uint n_refs) = o.get();
        return format("TOTAL {} cells {} bits {} refs\n", n_cells, n_bits, n_refs);
    }

    function size_string(TvmCell c) internal returns (string) {
        optional(uint, uint, uint) o = c.dataSizeQ(199);
        (uint n_cells, uint n_bits, uint n_refs) = o.get();
        return format("TOTAL {} cells {} bits {} refs\n", n_cells, n_bits, n_refs);
    }

    function size_string_b(TvmBuilder b) internal returns (string) {
        (uint16 bits, uint8 refs) = b.size();
        (uint16 rem_bits, uint8 rem_refs) = b.remBitsAndRefs();
        return format("{} {} {} {}\n", bits, refs, rem_bits, rem_refs);
    }

    function builder_string(uint i, TvmBuilder b) internal returns (string) {
        (uint16 bits, uint8 refs) = b.size();
        (uint16 rem_bits, uint8 rem_refs) = b.remBitsAndRefs();
        return format("Store {} CUR {} {} REM {} {}\n", i, bits, refs, rem_bits, rem_refs);
    }

    /* config parsing */
    function parse_sb_inode(string line) internal returns (uint16 index, Inode inode) {
        string index_s = line.substr(0, sb.DEF_INODE_SIZE);
        (string[] fields, ) = index_s.split(" ");
        uint[] values;

        for (string s: fields) {
            optional(int) val = stoi(s);
            values.push(val.hasValue() ? uint(val.get()) : 0);
        }
        return (uint16(values[0]), Inode(uint16(values[1]), uint16(values[2]), uint16(values[3]), uint16(values[4]), uint16(values[5]), uint16(values[6]), uint32(values[7]),
            uint32(values[8]), uint32(values[9]), fields[10]));
    }

    /* Byte stream -> fs */
    function parsefs(string text_stream) internal returns (string out, mapping (uint16 => Inode) inodes) {
        uint len = text_stream.byteLength();
        (string[] frs, uint frs_len) = text_stream.split("\x05");
        out.append(format("Parsing {} bytes, {} records\n", len, frs_len));

        for (uint i = 0; i < frs_len; i++) {
            string line = frs[i];
            uint line_len = line.byteLength();
            if (line_len > sb.DEF_INODE_SIZE) {
                (uint16 index, Inode inode) = parse_sb_inode(line);
                inodes[index] = inode;
            }
        }
    }

    /* Read inode table from cell */
    function parse_inodes(TvmCell c) internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, string out) {
        out.append(size_string(c));
        TvmSlice smain = c.toSlice();
        out.append(size_strings(smain));

        (uint16 n_dirs, uint16 n_reg_files, uint16 n_other) = smain.decode(uint16, uint16, uint16);
        TvmSlice sdirs = smain.loadRefAsSlice();
        out.append(size_strings(sdirs));

        TvmSlice sdir_data = sdirs.loadRefAsSlice();
        out.append(size_strings(sdir_data));
        Inode dir_def_inode = parse_def_inode(sdirs);
        for (uint16 i = 0; i < n_dirs; i++) {
            (uint8 index, uint8 n_links, uint16 file_size) = sdirs.decode(uint8, uint8, uint16);
            Inode dir_inode = dir_def_inode;
            dir_inode.n_links = n_links;
            dir_inode.file_size = file_size;
            bytes dir_data = sdir_data.decode(bytes);
            inodes[index] = dir_inode;
            data[index] = dir_data;
        }

        TvmSlice sreg_files = smain.loadRefAsSlice();
        out.append(size_strings(sreg_files));
        Inode reg_def_inode = parse_def_inode(sreg_files);
        for (uint16 i = 0; i < n_reg_files; i++) {
            (uint8 index, uint16 file_size) = sreg_files.decode(uint8, uint16);
            Inode reg_inode = reg_def_inode;
            reg_inode.file_size = file_size;
            inodes[index] = reg_inode;
        }

        TvmSlice sother = smain.loadRefAsSlice();
        out.append(size_strings(sother));
        Inode other_def_inode = parse_def_inode(sother);
        for (uint16 i = 0; i < n_other; i++) {
            (uint8 index, uint16 file_size) = sother.decode(uint8, uint16);
            Inode inode = other_def_inode;
            inode.file_size = file_size;
            inodes[index] = inode;
        }
    }

    function parse_def_inode(TvmSlice s) internal returns (Inode inode) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified) =
            s.decode(uint16, uint16, uint16, uint16, uint16, uint16, uint32, uint32, uint32);
        return Inode(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, "");
    }

    /* Devfs */
    uint16 constant DEVFS_INODES_INODE  = 0;
    uint16 constant DEVFS_DEV_DIR       = 1;

    /* Parse devfs from text config */
    function get_device_fs(string devices) internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 n = DEVFS_DEV_DIR;
        (string[] device_list, ) = devices.split("\n");

        uint16 host_device_id = 0;//(uint16(host_device_info.major_id) << 8) + host_device_info.minor_id;
        uint16 block_size = 100;//host_device_info.blk_size;
        uint16 block_count;
        string contents;
        (inodes[n], data[n]) = inode.get_any_node(libstat.FT_DIR, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 0, "/dev", inode.get_dots(DEVFS_DEV_DIR, DEVFS_DEV_DIR));
        uint16 node_index = n;
        n++;

        for (string device_info: device_list) {
            (string[] dev_fields, uint n_fields) = device_info.split("\t");
            if (n_fields > 3) {
                string file_name = dev_fields[2];
                n++;
                (inodes[n], data[n]) = inode.get_any_node(libstat.FT_BLKDEV, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 1, file_name, device_info);
                bytes dirent = udirent.dir_entry_line(n, file_name, libstat.FT_BLKDEV);
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

    /* text config -> builder */
    function process_config_line(string line) internal returns (TvmBuilder b) {
        (, uint8 node_type, , bytes content) = parse_config_line(line);
        if (node_type == libstat.FT_BLKDEV) {
            (uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks) = parse_blkdev(content);
            uint16 device_id = (uint16(major_id) << 8) + minor_id;
            b.store(device_id, block_size, n_blocks);
        } else if (node_type == libstat.FT_SOCK) {
            (uint16 first_inode, uint16 block_size, uint16 n_blocks, uint16 inode_size, uint16 n_inodes) = parse_sbinfo(content);
            b.store(first_inode, block_size, n_blocks, inode_size, n_inodes);
        } else if (node_type == libstat.FT_DIR) {
            (string[] dirents, uint n_dirents) = parse_dir_entries(content);
            for (uint i = 0; i < n_dirents; i++)
                b.store(dirents[i]);
        }
    }

    /* empty fs */
    function get_bare_fs() internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 n = 0;
        uint16 host_device_id = 0;
        uint16 block_count;

        n = sb.ROOT_DIR;
        (inodes[n], data[n]) = inode.get_any_node(libstat.FT_DIR, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 1, "/", inode.get_dots(n, n));
        block_count++;

//        SuperBlock sb = _get_default_sb("bfs", fs.DEF_BLOCK_SIZE, n, inodes, data);
        bytes inodes_dump = write_inodes(inodes, data);

        data[sb.SB_INODES_TABLE] = inodes_dump;
        bytes sb_dump = write_sb(inodes, data);
        data[sb.SB] = sb_dump;
    }

    /* Serialize */
    /* Superblock to text file */
    function write_sb(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (bytes out) {
        SuperBlock sb = sb.get_sb(inodes, data);
        (bool file_system_state, bool errors_behavior, string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes,
            uint16 free_blocks, uint16 block_size, uint32 created_at, uint32 last_mount_time, uint32 last_write_time, uint16 mount_count,
            uint16 max_mount_count, uint16 lifetime_writes, uint16 first_inode, uint16 inode_size) = sb.unpack();
        out = format("{} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}\n",
            file_system_state ? "Y" : "N", errors_behavior ? "Y" : "N", file_system_OS_type, inode_count, block_count, free_inodes, free_blocks, block_size, created_at, last_mount_time, last_write_time,
            mount_count, max_mount_count, lifetime_writes, first_inode, inode_size);
    }

    /* Inode table to text file */
    function write_inodes(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) /*data*/) internal returns (bytes out) {
        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, string file_name) = ino.unpack();
            out.append(format("{} {} {} {} {} {} {} {} {} {} {}\n", i, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified, file_name));
        }
    }

    /* default superblock */
    function get_default_sb(string name, uint16 block_size, uint16 first_inode, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (SuperBlock) {
        uint16 inode_count;
        uint16 block_count;
        for ((uint16 i, ): inodes) {
            if (i > 0)
                inode_count++;
            block_count++;
        }
        for ((, bytes bts): data)
            block_count += uint16(bts.length / block_size) + 1;

        return SuperBlock(true, true, name, inode_count, block_count, sb.MAX_INODES - inode_count - first_inode, sb.MAX_BLOCKS - block_count,
            block_size, now, 0, now, 0, 0, 1, first_inode, sb.DEF_INODE_SIZE);
    }

    /* calculate parent offset */
    function get_parent_offset(string parent, string[] file_list) internal returns (uint8 offset) {
        for (uint i = 0; i < file_list.length; i++)
            if (file_list[i] == parent)
                return uint8(i);
    }

    /* fs from config file (plus optimized form) */
    function get_system_init_2(string config) internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
        uint8 n = 0;
        (string[] config_lines, uint config_line_count) = config.split("\n");

        DeviceInfo host_device_info;
        uint16 host_device_id;
        uint16 block_size;
        string[] file_list = ["/"];

        uint16 n_dirs;
        uint16 n_reg_files;
        uint16 n_other;

        TvmBuilder b_dev = process_config_line(config_lines[0]);
        TvmBuilder b_info = process_config_line(config_lines[1]);

        TvmBuilder b_main;
        b_main.store(b_dev);
        b_main.store(b_info);
        TvmBuilder b_dirs;// = _store_def_inode(inodes[ROOT_DIR]);
        TvmBuilder b_reg_files;// = _store_def_inode(inodes[5]);
        TvmBuilder b_dir_data;
        out.append(builder_string(2, b_reg_files));
        TvmBuilder b_other;// = _store_def_inode(inodes[1]);
        out.append(builder_string(3, b_other));
        b_main.store(n_dirs, n_reg_files, n_other);
        b_dirs.store(n_dirs);
        b_dirs.storeRef(b_dir_data);

        b_reg_files.store(n_reg_files);

        b_other.store(n_other);

        out.append(builder_string(0, b_main));
        b_main.storeRef(b_dirs);
        out.append(builder_string(0, b_main));
        b_main.storeRef(b_reg_files);
        out.append(builder_string(0, b_main));
        b_main.storeRef(b_other);
        out.append(builder_string(0, b_main));
        c = b_main.toCell();
        out.append(size_string(c));

        for (uint j = 0; j < config_line_count; j++) {
            string line = config_lines[j];
            (string node_file_name, uint8 node_type, uint8 content_type, bytes content) = parse_config_line(line);
            uint8 node_index = get_parent_offset(node_file_name, file_list);
            uint8 parent_node_index = get_parent_offset(file_list[node_index], file_list);

            if (content_type == libstat.FT_REG_FILE || content_type == libstat.FT_DIR) {
                string dir_contents;
                dir_contents = content; //fields[3];
                (string[] files, uint n_files) = dir_contents.split_line(" ", "\n");
                for (uint i = 0; i < n_files; i++) {
                    string file_name = files[i];
                    n++;
                    (inodes[n], data[n]) = inode.get_any_node(content_type, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 1, file_name, content_type == libstat.FT_DIR ? inode.get_dots(n, node_index) : "");
                    bytes dirent = udirent.dir_entry_line(n, file_name, content_type);
                    inodes[parent_node_index].file_size += uint32(dirent.length);
                    inodes[parent_node_index].n_links++;
                    data[parent_node_index].append(dirent);
                }
            } else if (content_type == libstat.FT_CHRDEV) {

            }
            if (node_type == libstat.FT_DIR) {
                string dir_contents;
                dir_contents = content;
                (string[] files, ) = dir_contents.split_line(" ", "\n");

                    for (string file_name: files) {
                        n++;
                        file_list.push(file_name);
                        if (file_name != "/") {
                            (inodes[n], data[n]) = inode.get_any_node(content_type, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 1, file_name, content_type == libstat.FT_DIR ? inode.get_dots(n, node_index) : "");
                            bytes dirent = udirent.dir_entry_line(n, file_name, content_type);
                            inodes[parent_node_index].file_size += uint32(dirent.length);
                            inodes[parent_node_index].n_links++;
                            data[parent_node_index].append(dirent);
                        } //else
//                            (inodes[n], data[n]) = _get_any_node(FT_DIR, SUPER_USER, SUPER_USER_GROUP, host_device_id, 1, file_name, _get_dots(n, n));
//                        block_count++;
                    }
            } else if (node_type == libstat.FT_BLKDEV) {
                host_device_info = parse_device_info(line);
                host_device_id = (uint16(host_device_info.major_id) << 8) + host_device_info.minor_id;
                block_size = host_device_info.blk_size;
            }
        }
    }

    function parse_config_line(string line) internal returns (string name, uint8 node_type, uint8 content_type, bytes content) {
        (string[] fields, uint n_fields) = line.split_line(":", "\n");
        if (n_fields > 3) {
            name = fields[0];
            node_type = libstat.file_type(fields[1]);
            content_type = libstat.file_type(fields[2]);
            content = fields[3];
        }
    }

    function parse_values(string line) internal returns (uint[] values) {
        (string[] fields, ) = line.split(" ");
        for (string s: fields)
            values.push(str.toi(s));
    }

    /* Read block device from text config */
    function parse_blkdev(string contents) internal returns (uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks) {
        uint[] values = parse_values(contents);
        if (values.length > 3) {
            major_id = uint8(values[0]);
            minor_id = uint8(values[1]);
            block_size = uint16(values[2]);
            n_blocks = uint16(values[3]);
        }
    }

    function parse_dir_entries(string contents) internal returns (string[] dirents, uint n_dirents) {
        return libstring.split(contents, " ");
    }

    function inode_string(Inode inode) internal returns (string) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , ) = inode.unpack();
        return format("PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", mode, owner_id, group_id, n_links, device_id, n_blocks, file_size);
    }

    function store_def_inode(Inode inode) internal returns (TvmBuilder b) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
        b.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
    }

    function get_system_init(string config) internal returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint8 n = 0;
        string[] file_list = ["sb_set"];
        (string[] config_lines, uint config_line_count) = config.split("\n");
//        (string dev_name, uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks, uint16 host_device_id) = _parse_device_info_2(config_lines[0]);
        (, , , uint16 block_size, , uint16 host_device_id) = parse_device_info_2(config_lines[0]);
        uint16 block_count;

        for (uint j = 1; j < config_line_count; j++) {
            string line = config_lines[j];
            (string node_file_name, uint8 node_type, uint8 content_type, bytes content) = parse_config_line(line);
            uint8 node_index = get_parent_offset(node_file_name, file_list);
            uint8 parent_node_index = get_parent_offset(file_list[node_index], file_list);
            bytes contents;
            if (node_type == libstat.FT_DIR) {
                if (content_type == libstat.FT_REG_FILE || content_type == libstat.FT_DIR || content_type == libstat.FT_SYMLINK) {
                    string dir_contents;
                    if (content_type == libstat.FT_SYMLINK) {
                        string source = content; //fields[3];
                        uint8 source_index = get_parent_offset(source, file_list);
                        dir_contents = data[source_index];
                    } else
                        dir_contents = content; //fields[3];
                    (string[] files, ) = dir_contents.split_line(" ", "\n");
                    for (string file_name: files) {
                        n++;
                        file_list.push(file_name);
                        if (file_name != "/") {
                            (inodes[n], data[n]) = inode.get_any_node(content_type, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 1, file_name, content_type == libstat.FT_DIR ? inode.get_dots(n, node_index) : "");
                            bytes dirent = udirent.dir_entry_line(n, file_name, content_type);
                            inodes[parent_node_index].file_size += uint32(dirent.length);
                            inodes[parent_node_index].n_links++;
                            data[parent_node_index].append(dirent);
                        } else
                            (inodes[n], data[n]) = inode.get_any_node(libstat.FT_DIR, pw.SUPER_USER, gr.SUPER_USER_GROUP, host_device_id, 1, file_name, inode.get_dots(n, n));
                        block_count++;
                    }
                }
            } else if (node_type == libstat.FT_REG_FILE) {
                if (content_type == libstat.FT_REG_FILE) {
                    contents.append(content);
                } else if (content_type == libstat.FT_SOCK) {
                    if (node_file_name == "sb_device_info")
                        contents = config_lines[0];
                } else if (content_type == libstat.FT_SYMLINK) {
                    string source = content; //fields[3];
                    uint8 source_index = get_parent_offset(source, file_list);
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

        Inode info_inode = inodes[sb.SB_INFO];
        string info = string(data[sb.SB_INFO]);
        uint16[] sb_info;
        (string[] fields, ) = info.split_line(" ", "\n");
        for (string s: fields)
            sb_info.push(str.toi(s));

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
        inodes[sb.SB_INFO] = info_inode;

        Inode inodes_inode = inodes[sb.SB_INODES];
        uint16 inode_count = n;
        uint16 free_inodes = total_inodes - n;
        uint16 free_blocks = total_blocks - n;

        inodes_inode.owner_id = inode_count;
        inodes_inode.group_id = block_count;

        string inodes_data = format("{} {} {}\n", inode_count, free_inodes, sb.ROOT_DIR);
        string blocks_data = format("{} {} {}\n", block_count, free_blocks, sb.ROOT_DIR);
        inodes_data.append(blocks_data);
        inodes[sb.SB_INODES] = inodes_inode;
        data[sb.SB_INODES] = inodes_data;
    }

    function store_inodes_and_dirs(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (TvmCell c, string out) {
        Inode inod = inodes[sb.SB_INODES];
        out.append("Inodes inode: " + inode_string(inod));
        uint16 n_dirs;
        uint16 n_reg_files;
        uint16 n_other;
        TvmBuilder b_main = store_def_inode(inodes[0]);
        TvmBuilder b_dirs = store_def_inode(inodes[sb.ROOT_DIR]);
        TvmBuilder b_reg_files = store_def_inode(inodes[5]);
        TvmBuilder b_dir_data;
        out.append(builder_string(2, b_reg_files));
        TvmBuilder b_other = store_def_inode(inodes[1]);
        out.append(builder_string(3, b_other));
        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
            if (libstat.is_dir(mode)) {
                bytes dir_data = data[i];
                out.append(format("dir data: {}\n", dir_data.length));
                n_dirs++;
                (, uint n_items) = libstring.split(dir_data, "\n");
                b_dirs.store(uint8(n_dirs), uint8(n_items), uint16(dir_data.length));
                out.append(builder_string(1, b_dirs));
                out.append(builder_string(4, b_dir_data));
            }
            else if (libstat.is_reg(mode)) {
                b_reg_files.store(uint8(i), uint16(file_size));
                out.append(builder_string(2, b_reg_files));
                n_reg_files++;
            } else {
                b_other.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
                out.append(builder_string(3, b_other));
                n_other++;
            }
        }
        b_main.store(n_dirs, n_reg_files, n_other);
        b_dirs.store(n_dirs);
        b_dirs.storeRef(b_dir_data);

        b_reg_files.store(n_reg_files);

        b_other.store(n_other);

        out.append(builder_string(0, b_main));
        b_main.storeRef(b_dirs);
        out.append(builder_string(0, b_main));
        b_main.storeRef(b_reg_files);
        out.append(builder_string(0, b_main));
        b_main.storeRef(b_other);
        out.append(builder_string(0, b_main));
        c = b_main.toCell();
        out.append(size_string(c));
    }

    function parse_device_info(string dev_info_s) internal returns (DeviceInfo dev_info) {
        (uint[] values, string[] names, address[] addresses) = parse_record(dev_info_s, "\t");
        return DeviceInfo(uint8(values[0]), uint8(values[1]), names[0], uint16(values[2]), uint16(values[3]), addresses[0]);
    }

    function parse_record(string line, string separator) internal returns (uint[] values, string[] names, address[] addresses) {
        (string[] fields, ) = line.split_line(separator, "\n");
        for (string s: fields) {
            uint len = s.byteLength();
            if (len > 65)
                addresses.push(to_address(s));
            else {
                optional(int) val = stoi(s);
                if (val.hasValue())
                    values.push(uint(val.get()));
                else
                    names.push(s);
            }
        }
    }

    function to_address(string saddr) internal returns (address) {
        uint len = saddr.byteLength();
        if (len > 60) {
            string s_hex = "0x" + saddr.substr(2);
            optional(int) u_addr = stoi(s_hex);
            if (u_addr.hasValue())
                return address.makeAddrStd(0, uint(u_addr.get()));
        }
    }

    function parse_device_info_2(string dev_info_s) internal returns (string dev_name, uint8 major_id, uint8 minor_id, uint16 block_size, uint16 n_blocks, uint16 device_id) {
        (string name, uint8 node_type, , bytes content) = parse_config_line(dev_info_s);
        if (node_type == libstat.FT_BLKDEV) {
            dev_name = name;
            (major_id, minor_id, block_size, n_blocks) = parse_blkdev(content);
            device_id = (uint16(major_id) << 8) + minor_id;
        }
    }

    function parse_sbinfo(string contents) internal returns (uint16 first_inode, uint16 block_size, uint16 n_blocks, uint16 inode_size, uint16 n_inodes) {
        uint[] values = parse_values(contents);
        if (values.length > 4) {
            first_inode = uint16(values[0]);
            block_size = uint16(values[1]);
            n_blocks = uint16(values[2]);
            inode_size = uint16(values[3]);
            n_inodes = uint16(values[4]);
        }
    }

    function view_inode(Inode inode) internal returns (string) {
        TvmBuilder b = i_read(inode);
        (uint16 bits, uint8 refs) = b.size();
        (uint16 rem_bits, uint8 rem_refs) = b.remBitsAndRefs();
        return format("{} {} {} {}\n", bits, refs, rem_bits, rem_refs);
    }

    function i_read(Inode inode) internal returns (TvmBuilder b) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
        b.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
    }

    function read_inode_table(mapping (uint16 => bytes) data) internal returns (mapping (uint16 => Inode) inodes) {
        bytes inodes_data = data[sb.SB_INODES_TABLE];
        (string[] records, uint n_records) = libstring.split(inodes_data, "\n");
        for (uint i = 0; i < n_records; i++) {
            string line = records[i];
            (string[] fields, uint n_fields) = line.split(" ");

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

}