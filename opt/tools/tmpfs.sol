pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "aio.sol";
import "fs.sol";
contract tmpfs is Utility {

// I/O control block
struct s_aiocb {
    uint16 aio_fildes;   // File descriptor
    uint32 aio_offset;   // File offset for I/O
    bytes aio_buf;       // I/O buffer in process space
    uint32 aio_nbytes;   // Number of bytes for I/O
    uint8 aio_lio_opcode;// LIO opcode
    uint8 status;
    uint8 error;
}

    // Asynchronously read from a file
    function aio_read(s_aiocb iocb, string env, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (s_aiocb res) {
        (uint16 aio_fildes, uint32 aio_offset, bytes aio_buf, uint32 aio_nbytes, uint8 aio_lio_opcode, uint8 status, uint8 error) = iocb.unpack();
        res = iocb;
        if (inodes_in.exists(aio_fildes) && data_in.exists(aio_fildes)) {
            bytes buf = data_in[aio_fildes];
            uint len = buf.length;
            res.aio_buf.append(buf[aio_offset : aio_offset + aio_nbytes]);
        }

    }

    // Asynchronously write to file
    function aio_write(s_aiocb iocb, string env, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        (uint16 aio_fildes, uint32 aio_offset, bytes aio_buf, uint32 aio_nbytes, uint8 aio_lio_opcode, uint8 status, uint8 error) = iocb.unpack();
        if (inodes_in.exists(aio_fildes) && data_in.exists(aio_fildes)) {
            bytes buf = data_in[aio_fildes];
            uint len = buf.length;
        }
    }

    function fopen(string[] enve, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        //(uint16 wd, /*string[] params*/, /*string flags*/, ) = arg.get_env(env);
        uint16 wd;
        uint16 device_id;
        string path = vars.val("REDIR_OUT", enve);
        inodes = inodes_in;
        data = data_in;
        (uint16 uid, uint16 gid) = (0, 0);//arg.get_user_data(env);
        (, , uint16 parent, uint16 dir_index) = fs.resolve_relative_path(path, wd, inodes_in, data_in);
        if (dir_index == 0) {
            ic = sb.get_inode_count(inodes);
            (inodes[ic], data[ic]) = inode.get_any_node(libstat.FT_REG_FILE, uid, gid, device_id, 0, path, "");
            string dirent = udirent.dir_entry_line(ic, path, libstat.FT_REG_FILE);
            data[parent].append(dirent);
            Inode parent_dir_node = inodes[parent];
            parent_dir_node.file_size = dirent.byteLength();
            parent_dir_node.n_links++;
            inodes[parent] = parent_dir_node;
            inodes[sb.SB_INODES] = sb.claim_inodes_and_blocks(inodes[sb.SB_INODES], 1, 0);
        }
    }

    function fwrite(string /*env*/, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in, uint16 ic, string text) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        inodes = inodes_in;
        data = data_in;
        data[ic].append(text);
    }

    function fclose(string /*env*/, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in, uint16 ic) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        inodes = inodes_in;
        data = data_in;
        Inode inode = inodes[ic];
        bytes bts = data[ic];
        uint data_size = bts.length;
        inode.file_size = uint32(data_size);
        uint16 block_size = 100;
        uint16 n_blocks = uint16(data_size / block_size + 1);
        inode.n_blocks = n_blocks;
        inode.modified_at = now;
        inode.last_modified = now;
        inodes[ic] = inode;
        inodes[sb.SB_INODES] = sb.claim_inodes_and_blocks(inodes[sb.SB_INODES], 0, n_blocks);
    }

    function handle_action(string env, Ar[] ars, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint16 device_id;
        uint16 block_size = 100;
        (uint16 uid, uint16 gid) = (0, 0); //arg.get_user_data(env);
        uint16 n_files;
        inodes = inodes_in;
        data = data_in;
        mapping (uint16 => Inode) inodes_diff;
        mapping (uint16 => bytes) data_diff;
        uint16 inode_count = sb.get_inode_count(inodes);
        uint16 counter = inode_count;
        uint total_blocks;

        uint n_ars = ars.length;
        for (uint i = 0; i < n_ars; i++) {
            (uint8 ar_type, uint16 index, string path, string text) = ars[i].unpack();
            if (ar_type == aio.MKFILE) {
                uint16 n_blocks = uint16(text.byteLength() / block_size + 1);
                (inodes_diff[counter], data[counter]) = inode.get_any_node(libstat.FT_REG_FILE, uid, gid, device_id, n_blocks, path, text);
                counter++;
                total_blocks += n_blocks;
            } else if (ar_type == aio.MKDIR) {
                (inodes_diff[counter], data[counter]) = inode.get_any_node(libstat.FT_DIR, uid, gid, device_id, 1, path, text);
                total_blocks++;
                counter++;
            } else if (ar_type == aio.ADD_DIR_ENTRY) {
                Inode parent_dir_node = inodes[index];
                bytes parent_dir_data = data[index];
                parent_dir_node.file_size += text.byteLength();
                parent_dir_node.modified_at = now;
                parent_dir_node.last_modified = now;
                inodes_diff[index] = parent_dir_node;
                parent_dir_data.append(text);
                data_diff[index] = parent_dir_data;
            } else if (ar_type == aio.UPDATE_DIR_ENTRY || ar_type == aio.UPDATE_TEXT_DATA) {
                Inode parent_dir_node = inodes[index];
                parent_dir_node.file_size = text.byteLength();
                inodes_diff[index] = parent_dir_node;
                data_diff[index] = text;
            } else if (ar_type == aio.WR_COPY) {
                uint b_count;
                bytes b_contents;
                if (index > 0)
                    b_contents = data[index];
                total_blocks += b_count;

                Inode file_copy_inode = inodes[index];
                file_copy_inode.modified_at = now;
                file_copy_inode.last_modified = now;
                file_copy_inode.owner_id = uid;
                file_copy_inode.group_id = gid;
                file_copy_inode.file_name = path;
                inodes_diff[counter] = file_copy_inode;
                data_diff[counter] = b_contents;
                counter++;
            } else if (ar_type == aio.UNLINK) {
                Inode victim_inode = inodes[index];
                victim_inode.n_links--;
                if (victim_inode.n_links == 0) {
                    delete inodes[index];
                    delete data[index];
                } else
                    inodes_diff[index] = victim_inode;
            } else if (ar_type == aio.HARDLINK) {
                Inode source_inode = inodes[index];
                source_inode.n_links++;
                source_inode.last_modified = now;
                inodes_diff[index] = source_inode;
            } else if (ar_type == aio.UPDATE_TIME) {
                Inode source_inode = inodes[index];
                source_inode.last_modified = now;
                inodes_diff[index] = source_inode;
            }
        }
        inodes_diff[sb.SB_INODES] = sb.claim_inodes_and_blocks(inodes[sb.SB_INODES], n_files, uint16(total_blocks));
        for ((uint16 index, Inode inode): inodes_diff)
            inodes[index] = inode;
        for ((uint16 index, bytes b_data): data_diff)
            data[index] = b_data;
    }

    /* Mount a set of index nodes to the specified mount point of the primary file system */
    function mount_dir(uint16 mount_point_index, mapping (uint16 => Inode) inodes_in, mapping (uint16 => bytes) data_in) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        mapping (uint16 => Inode) inn = inodes_in;
        mapping (uint16 => bytes) b_data = data_in;
        uint16 inode_count = sb.get_inode_count(inodes_in);
        uint16 block_size;// = block_size;
        uint16 counter = inode_count;
        uint total_blocks;
        uint n_inodes;

        for ((uint16 i, Inode inode): inodes) {
            inn[counter + i] = inode;
            n_inodes++;
        }
        for ((uint16 i, bytes bts): data) {
            b_data[counter + i] = bts;
            total_blocks += bts.length / block_size + 1;
        }
        inn[mount_point_index] = inodes[sb.ROOT_DIR];
//        inn[SB_INODES] = _claim_inodes_and_blocks(inodes[SB_INODES], n_inodes, total_blocks);

        for ((uint16 index, Inode inode): inn)
            inodes[index] = inode;
        for ((uint16 index, bytes bts): data)
            data[index] = bts;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tmpfs",
"[OPTION]... FILE...",
"temporary file system",
"Used for file system operations testing.",
"-c      do not create any files\n\
-m      change only the modification time",
"",
"Written by Boris",
"",
"",
"0.02");
    }
}
