pragma ton-solidity >= 0.51.0;

import "../lib/Format.sol";
import "Utility.sol";
import "../lib/SyncFS.sol";

/* Primary configuration files for a block device system initialization and error diagnostic data */
contract TapeArchive is Format, Utility, SyncFS {

/*    struct Archive {
//        string file_name;
//        string[] index;
//        TarEntry[] index;
        bytes[] data;
    }

    Archive[] _archives;*/

struct TarIndexEntry {
    string name;
    string mode;
    string size;
    string mtime;
    string uname;
    string gname;
    string prefix;
}

struct TarEntry {
    uint64 attrs;
    uint32 size;
    uint32 mtime;
    bytes uname;
    bytes gname;
    bytes name;
    bytes prefix;
}


    function pack_inode(Inode inode) external pure returns (TvmCell c) {
        TvmBuilder b = _read(inode);
        return b.toCell();
    }

    /*function store_inodes(mapping (uint16 => Inode) inodes) external pure returns (TvmCell c) {
        return b.toCell();
    }*/

    function _store_inodes_compact(mapping (uint16 => Inode) inodes) internal pure returns (TvmCell c) {
        Inode inodes_inode = inodes[SB_INODES];
        uint16 inode_count = inodes_inode.owner_id;
        optional(uint16, Inode) o = inodes.max();
        (, Inode ref_inode) = o.get();
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ref_inode.unpack();
        TvmBuilder b;
        b.store(mode, owner_id, group_id, n_links, device_id, modified_at, last_modified);
    }

    function _store_inodes(mapping (uint16 => Inode) inodes) internal pure returns (TvmCell c) {
        Inode inodes_inode = inodes[SB_INODES];
        uint16 inode_count = inodes_inode.owner_id;
        uint max_inodes_per_cell = 5;//1023 / 192;
        uint n_cells = inode_count / max_inodes_per_cell;
        uint inodes_in_cur_cell;
        uint cur_cells;
        TvmBuilder b;
        for ((uint16 i, Inode inode): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
            b.store(mode, owner_id, group_id, n_links, device_id, n_blocks, file_size, modified_at, last_modified);
            inodes_in_cur_cell++;
            if (inodes_in_cur_cell >= max_inodes_per_cell) {
                c = b.toCell();
                inodes_in_cur_cell = 0;
                cur_cells++;
            }
        }
        return b.toCell();
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


    function _encode_attrs(uint16 mode, uint16 uid, uint16 gid, uint8 typeflag, uint8 version) internal pure returns (uint64) {
        return uint64((uint(mode) << 48) + (uint(uid) << 32) + (uint(gid) << 16) + (uint(typeflag) << 8) + version);
    }

    function _decode_attrs(uint64 val) internal pure returns (uint16 mode, uint16 uid, uint16 gid, uint8 typeflag, uint8 version) {
        mode = uint16((val >> 48) & 0xFFFF);
        uid = uint16((val >> 32) & 0xFFFF);
        gid = uint16((val >> 16) & 0xFFFF);
        typeflag = uint8((val >> 8) & 0xFF);
        version = uint8(val & 0xFF);
    }

//    function _add_entry() internal pure returns
    function read_archive(string[] arc_index, bytes[] arc_data) external pure returns (string arc_index_file, bytes[] data) {
        for (uint i = 0; i < arc_index.length; i++) {
            string line = arc_index[i];
            arc_index_file.append(line + "\n");
//            bytes header = arc_data[i * 2];
            bytes file_data = arc_data[i * 2 + 1];
            data.push(file_data);
        }
    }

    /*function _match_archive_name(string name) internal view returns (uint) {
        uint len = _archives.length;
        for (uint i = 0; i < len; i++)
            if (_archives[i].file_name == name)
                return i + 1;
        return 0;
    }*/

    /*function create_archive(string arc_name, string[] arc_index, bytes[] arc_data) external accept {
        _archives.push(Archive(arc_name, arc_index, arc_data));
    }*/

    function apply_add_file_to_archive(uint16 arc_id, string[] arc_index, bytes[] arc_data) external pure accept {
//        Archive arc; = _archives[arc_id - 1];

        for (string s: arc_index) {
/*            arc.index.push();
        _read_tar_index_entry
        TarIndexEntry(base_name, s_mode, size_s, mtime, uname, gname, dir_name)
        TarEntry te = TarEntry(attrs, uint32 size, now, uname, gname, name, prefix);*/
        }
        for (bytes data: arc_data)
//            arc.data.push(data);
            arc_id = arc_id;
//        _archives[arc_id - 1] = arc;
    }

    /*function add_file_to_archive(string archive_name, string file_name, bytes data) external pure returns (string[] arc_index, bytes[] arc_data) {
//        _add_files(Session session, uint16 pino, uint8 et, Arg[] args);
        uint k;// = _match_archive_name(archive_name);
        if (k > 0) {
            TarEntry[] index;// = _archives[k - 1].index;
            uint j;// = _match_file_entry(k, file_name);
            if (j > 0) {
                string line = index[j - 1].name;
                arc_index.push(_write_tar_index_entry(_read_tar_index_entry(line)));
//                arc_data.push(_encode_tar_entry(_read_tar_entry(_read_tar_index_entry(line))));
                arc_data.push(_encode_tar_entry(_read_tar_entry(line)));
                arc_data.push(data);
            } else {
//                (string name, string mode, string size, string mtime, string uname, string gname, string prefix) = tie.unpack();
//                TarIndexEntry tie = TarIndexEntry(, s_mode, size_s, mtime, uname, gname, dir_name);
//                (string dir_name, string base_name) = _dir(file_name);
//                if (dir_name != ".")
//                    string prefix = dir_name;

//                arc_index.push(_write_tar_index_entry(_read_tar_index_entry(line)));
            }
        }
    }*/

    /*function delete_archive(string archive_name) external accept {
        uint k = _match_archive_name(archive_name);
        if (k > 0)
            delete _archives[k];
    }*/

//    function create_archive(string arc_index_file, bytes[] data) external pure returns (string[] arc_index, bytes[] arc_data) {
    function get_archive(string file_name, string arc_index_file, bytes[] data) external pure returns (string arc_name, string[] arc_index, bytes[] arc_data) {
        arc_name = file_name;
        (string[] arc_index_lines, ) = _split(arc_index_file, "\n");
        uint data_len = data.length;
        for (uint i = 0; i < arc_index_lines.length; i++) {
            string line = arc_index_lines[i];
            arc_index.push(_write_tar_index_entry(_read_tar_index_entry(line)));
            if (i < data_len && !data[i].empty()) {
//                arc_data.push(_encode_tar_entry(_read_tar_entry(_read_tar_index_entry(line))));
                arc_data.push(_encode_tar_entry(_read_tar_entry(line)));
                arc_data.push(data[i]);
            }
        }
    }

    function _read_tar_entry(string line) internal pure returns (TarEntry te) {
        string line_s = _tr_squeeze(line, " ");
        (string[] fields, ) = _split(line_s, " ");
        if (fields.length > 5) {
//            drwxr-xr-x boris/boris       0 2021-10-28 23:40 etc/
            string s_mode = fields[0];
            string file_path = fields[5];
            (string dir_name, string base_name) = _dir(file_path);
            if (dir_name == ".")
                delete dir_name;
            string s_owner = fields[1];
            (string uname, string gname) = _dir(s_owner);
            string s_size = fields[2];
//            string mtime = fields[3] + " " + fields[4];

            uint16 mode = _mode(s_mode);
            uint32 size = _atoi(s_size);
            uint64 attrs;// = _encode_attrs(mode, _get_user_id(uname), _get_group_id(gname), FT_REG_FILE, 0);

            te = TarEntry(attrs, size, now, uname, gname, base_name, dir_name);
        }
    }

    function _read_tar_index_entry(string line) internal pure returns (TarIndexEntry tie) {
        string line_s = _tr_squeeze(line, " ");
        (string[] fields, ) = _split(line_s, " ");
        if (fields.length > 5) {
//            drwxr-xr-x boris/boris       0 2021-10-28 23:40 etc/
            string s_mode = fields[0];
            string file_path = fields[5];
            (string dir_name, string base_name) = _dir(file_path);
            if (dir_name == ".")
                delete dir_name;
            string s_owner = fields[1];
            (string uname, string gname) = _dir(s_owner);
            string size_s = fields[2];
            string mtime = fields[3] + " " + fields[4];
            tie = TarIndexEntry(base_name, s_mode, size_s, mtime, uname, gname, dir_name);
        }
    }

    function _write_tar_index_entry(TarIndexEntry tie) internal pure returns (string line) {
        (string name, string mode, string size, string mtime, string uname, string gname, string prefix) = tie.unpack();
        line = mode + " " + uname + "/" + gname + " " + size + " " + mtime + " " + _full_name_s(name, prefix);
    }

    /*function _get_user_id(string user_name) internal pure returns (uint16) {
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
    }*/

    /*function _match_file_entry(uint archive_index, string name) internal view returns (uint) {
        TarEntry[] index = _archives[archive_index - 1].index;
        for (uint i = 0; i < index.length; i++) {
            TarEntry e = index[i];
            if (e.name == name)
                return i + 1;
        }
        return 0;
    }*/

    /*function _read_tar_entry(TarIndexEntry tie) internal pure returns (TarEntry header) {
        (string name, string s_mode, string s_size, , string uname, string gname, string prefix) = tie.unpack();
//            drwxr-xr-x boris/boris       0 2021-10-28 23:40 etc/
        uint16 mode = _mode(s_mode);
        uint32 size;
        (uint size_u, bool success) = stoi(s_size);
        if (success)
            size = uint32(size_u);
        uint64 attrs = _encode_attrs(mode, _get_user_id(uname), _get_group_id(gname), FT_REG_FILE, 0);
//        header = TarEntry(attrs, size, now, bytes16(uname), bytes16(gname), bytes32(name), bytes32(prefix));
        header = TarEntry(attrs, size, now, bytes(uname), bytes(gname), bytes(name), bytes(prefix));
    }*/

    /*function view_archive_data_raw() external view returns (string[][] arc_indices, bytes[][] out) {
        for (Archive arc: _archives) {
            string[] index = arc.index;
            bytes[] a_data = arc.data;
            arc_indices.push(index);
            uint data_len = a_data.length;
            for (uint i = 0; i < index.length; i++) {
                uint data_offset = i * 2 + 1;
                if (data_offset < data_len && !a_data[data_offset].empty())
                    out.push([a_data[data_offset]]);
            }
            out.push(a_data);
        }
    }*/

    function view_archive_data() external view returns (string out) {
        /*for (Archive arc: _archives) {
            TarEntry[] index = arc.index;
            bytes[] a_data = arc.data;
            uint data_len = a_data.length;
            for (uint i = 0; i < index.length; i++) {
                uint header_offset = i * 2;
                uint data_offset = header_offset + 1;
                if (data_offset < data_len && !a_data[data_offset].empty()) {
                    out.push(_print_header(a_data[header_offset]));
                    out.push(_print_data(a_data[data_offset]));
                }
            }
        }*/
//        return _dump_fs(2, _sb, _inodes);
    }

    function _print_data(bytes data) internal pure returns (string out) {
        out = string(data);
    }

    function _full_name_s(string file_name, string prefix) internal pure returns (string) {
        return prefix.empty() ? file_name : file_name + "/" + prefix;
    }

    function _print_header(bytes header) internal pure returns (string out) {
//        (string s_attributes, , , bytes32 s_name, bytes32 s_prefix, string s_owner, string s_path) = _decode_header(header);
  //      out = format("{} {} {}\n", s_attributes, s_owner, s_path);
    }

    function _bytes_to_string(bytes str) internal pure returns (string) {
        string s = string(str);
        uint p = _strchr(s, "\u0000");
        return p > 0 ? s.substr(0, p - 1) : s;
    }

    function _decode_header(bytes header) internal pure returns (string s_attributes, bytes16 uname, bytes16 gname, bytes32 name, bytes32 prefix, string s_owner, string s_path) {
        uint64 attrs = uint64(bytes8(header[:8]));
        (uint16 mode, uint16 uid, uint16 gid, uint8 typeflag, uint8 version) = _decode_attrs(attrs);
        uint32 size = uint32(bytes4(header[8:12]));
        uint32 mtime = uint32(bytes4(header[12:16]));
        s_attributes = format("{} {} {} {} {} {} {} ", _permissions(mode), uid, gid, size, _ts(mtime), typeflag, version);
        bytes b_uname = header[32:48];
        bytes b_gname = header[48:64];
        bytes b_name = header[64:96];
        bytes b_prefix = header[96:128];
        uname = bytes16(b_uname);
        gname = bytes16(b_gname);
        name = bytes32(b_name);
        prefix = bytes32(b_prefix);
        s_owner = _bytes_to_string(b_uname) + "/" + _bytes_to_string(b_gname);
        s_path = _bytes_to_string(b_name);
        if (b_prefix.length > 0)
            s_path = _bytes_to_string(b_prefix) + "/" + s_path;
    }

    /*function create_archive_index(TarIndexEntry[] entries, TarEntry[] headers) external pure returns (string[] arc_index, bytes[] binary_headers) {
        for (TarIndexEntry tie: entries)
            arc_index.push(_write_tar_index_entry(tie));
        for (TarEntry header: headers)
            binary_headers.push(_encode_tar_entry(header));
    }*/

    function _encode_tar_entry(TarEntry header) internal pure returns (bytes data) {
//        (uint64 h_attrs, uint32 h_size, uint32 h_mtime, bytes16 h_uname, bytes16 h_gname, bytes32 h_name, bytes32 h_prefix) = header.unpack();
        (uint64 h_attrs, uint32 h_size, uint32 h_mtime, bytes h_uname, bytes h_gname, bytes h_name, bytes h_prefix) = header.unpack();
        tvm.hexdump(h_attrs);
        tvm.hexdump(h_size);
        tvm.hexdump(h_mtime);

        /*(uint16 h_mode, uint16 h_uid, uint16 h_gid, uint8 h_typeflag, uint8 h_version) = _decode_attrs(h_attrs);
        uint128 attributes = uint128((uint(h_mode) << 112) + (uint(h_uid) << 96) + (uint(h_gid) << 80) + (uint(h_size) << 48) + (uint(h_mtime) << 16) + (uint(h_typeflag) << 8) + h_version);
        string s_attr = format("{:x}", attributes);
        string str = s_attr + bytes16(h_uname) + bytes16(h_gname) + bytes32(h_name) + bytes32(h_prefix);*/
        data.append(h_uname);
        data.append(h_gname);
        data.append(h_name);
        data.append(h_prefix);
//        return bytes(str);
    }

    /*function extract_archive_headers(string arc_index_file) external pure returns (TarIndexEntry[] entries, TarEntry[] headers) {
        string[] arc_index_lines = _split(arc_index_file, "\n");
        for (string line: arc_index_lines)
            entries.push(_read_tar_index_entry(line));
        for (TarIndexEntry tie: entries)
            headers.push(_read_tar_entry(tie));
    }*/


    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("tar", "an archiving utility", "-A [OPTIONS] ARCHIVE ARCHIVE\t-cdru [-f ARCHIVE] [OPTIONS] [FILE...]\t-tx [-f ARCHIVE] [OPTIONS] [MEMBER...]",
            "An archiving program designed to store multiple files in a single file (an archive), and to manipulate such archives.",
            "AcdrtuxfkUWOmpRvo", 1, M, [
            "append tar files to an archive",
            "create a new archive",
            "find differences between archive and file system",
            "append files to the end of an archive",
            "list the contents of an archive",
            "only append files newer than copy in archive",
            "extract files from an archive",
            "use archive file or device ARCHIVE",
            "don't replace existing files when extracting, treat them as errors",
            "remove each file prior to extracting over it",
            "attempt to verify the archive after writing it",
            "extract files to standard output",
            "don't extract file modified time",
            "extract information about file permissions (default for superuser)",
            "show block number within archive with each message",
            "verbosely list files processed",
            "when creating, same as -k; when extracting, extract files as yourself"]);
    }
}
