pragma ton-solidity >= 0.59.0;
import "uer.sol";
struct chunk {
    uint8 ord;
    uint16 n_cells;
    uint32 n_bits;
    uint16 n_refs;
    uint32 size;
    uint hash_code;
}

struct stored_chunk {
    uint8 file_index;  // file index in the group
    uint8 chunk_index; // chunk index in the file
    uint8 n_cells;     // number of cells in the chunk
    uint16 chunk_size; // size of the chunk in bytes
}

struct load_data {
    uint8 count;
    chunk[] meta;
    TvmCell[] cells;
}

struct file_info {
    uint8 mime_type;
    uint8 mime_subtype;
    uint8 charset;
    uint8 n_parts;
    uint32 size;
    uint32 created_at;
//    uint file_hash;
    string name;
}

struct chunk_info {
    uint8 file_index;  // file index in the group
    uint8 chunk_index; // chunk index in the file
    uint8 n_cells;     // number of cells in the chunk
    uint16 chunk_size; // size of the chunk in bytes
    uint chunk_hash;   // hash code of the root cell
}

struct file_type_info {
    uint8 type_id;
    string type_desc;
}

struct batch_info {
    uint8 batch_id;
    uint8 type_id;
    uint8 n_files;
    uint16 start_file;
}

struct load_data_2 {
    batch_info batch;
    file_info[] files;
    mapping (uint => chunk_info) chunks;
    TvmCell[] cells;
}

struct chunk_2 {
    uint8 file_index;  // file index in the group
    uint8 chunk_index; // chunk index in the file
    uint8 n_cells;     // number of cells in the chunk
    uint16 chunk_size; // size of the chunk in bytes
}

struct data_range {
    uint8 file_from;
    uint8 file_count;
    uint8 chunk_from;
    uint8 chunk_count;
}

interface load_data_peer {
    function import_load_data(load_data[] stg) external;
    function export_load_data(uint32 range, address addr) external view;
}

interface load_data_peer_2 {
    function import_load_data_2(load_data_2[] stg) external;
    function export_load_data_2(uint32 range, address addr) external view;
}

library libloadinfo {

    uint8 constant UMA_CHUNK_HEADER_SIZEOF = 14;
    uint8 constant UMA_FILE_HEADER_SIZEOF = 8;
    uint8 constant UMA_CHUNK_HASH_SIZEOF = 32;

    function chunk_hash_ctor(bytes /*mem*/, uint16 size, bytes arg, uint32 /*flags*/) internal returns (uint8 ec, bytes res) {
        if (size < UMA_CHUNK_HASH_SIZEOF)
            ec = uer.SIZE_TOO_SMALL;
        else {
//            res = "" + bytes32(arg);
            res = arg.length > UMA_CHUNK_HASH_SIZEOF ? arg[ : UMA_CHUNK_HASH_SIZEOF] : arg;
        }
    }
    function chunk_ctor(bytes /*mem*/, uint16 size, bytes arg, uint32 /*flags*/) internal returns (uint8 ec, bytes res) {
        if (size < UMA_CHUNK_HEADER_SIZEOF)
            ec = uer.SIZE_TOO_SMALL;
        else {
//            res = "" + bytes14(arg);
            res = arg.length > UMA_CHUNK_HEADER_SIZEOF ? arg[ : UMA_CHUNK_HEADER_SIZEOF] : arg;
            /*uint112 v = uint112(bytes14(arg));
            ck = chunk(uint8(v >> 96 & 0xFF), uint16(v >> 80 & 0xFFFF), uint32(v >> 48 & 0xFFFFFFFF), uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF),
                mem.empty() ? 0 : tvm.hash(mem));*/
        }
    }

    function chunk_code(chunk c) internal returns (uint112) {
        (uint8 ord, uint16 n_cells, uint32 n_bits, uint16 n_refs, uint32 size, ) = c.unpack();
        return (uint112(ord) << 96) + (uint112(n_cells) << 80) + (uint112(n_bits) << 48) + (uint112(n_refs) << 32) + size;
    }

    function store(load_data ld, bytes data) internal {
        TvmBuilder b;
        b.store(data);
        TvmCell c = b.toCell();
        uint8 cnt = ld.count++;
        (uint cells, uint bits, uint refs) = c.dataSize(2000);
        ld.meta.push(chunk(cnt, uint16(cells), uint32(bits), uint16(refs), uint32(data.length), tvm.hash(c)));
        ld.cells.push(c);
    }

    function fetch_cells(load_data ld, uint8 chunk_from, uint8 chunk_count) internal returns (TvmCell[] cells) {
        uint8 lim = chunk_from + chunk_count;
        uint8 chunk_to = chunk_count > 0 && lim < ld.count ? chunk_from + chunk_count : ld.count;
        for (uint8 j = chunk_from; j < chunk_to; j++)
            cells.push(ld.cells[j]);
    }

    string constant CHUNK_HEADING    = " NF Ord  Cells  Bits  Refs  Size";

    function print_chunks(bytes[] cdd) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        for (bytes bb: cdd)
            o.append(print_chunk(bb) + "\n");
    }

    function print_chunks0(uint112[] vv) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        for (uint112 v: vv)
            o.append(print_chunk0(v) + "\n");
    }

    function print_chunks00(vector(uint112) vv) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        while (!vv.empty()) {
            uint112 v = vv.pop();
            o.append(print_chunk0(v) + "\n");
        }
    }

    function print_stored_chunks00(vector(uint40) vv) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        while (!vv.empty()) {
            uint40 v = vv.pop();
            o.append(print_stored_chunk0(v) + "\n");
        }
    }

    function print_chunks1(bytes14[] bts) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        for (bytes14 b: bts)
            o.append(print_chunk1(b) + "\n");
    }

    function print_chunks_full(bytes[] cdd, bytes[] hcd) internal returns (string o) {
        o = CHUNK_HEADING + "    Hash code \n";
        uint cap = math.min(cdd.length, hcd.length);
        for (uint i = 0; i < cap; i++)
            o.append(print_chunk(cdd[i]) + format("{:x}\n", uint(bytes32(hcd[i]))));
    }

    function print_stored_chunk0(uint40 v) internal returns (string) {
        (uint8 file_index, uint8 chunk_index, uint8 cells, uint16 chunk_size) = (uint8(v >> 32 & 0xFF), uint8(v >> 24 & 0xFF), uint8(v >> 16 & 0xFF), uint16(v & 0xFFFF));
        (uint8 nf, uint8 ord, uint16 n_cells, uint32 n_bits, uint16 n_refs, uint32 size) = (file_index, chunk_index, cells, uint32(chunk_size) * 8, cells > 0 ? (cells - 1) : 0, chunk_size);
        return format("{:3} {:3}  {:4} {:7} {:4} {:7}  ", nf, ord, n_cells, n_bits, n_refs, size);
    }

    function print_chunk0(uint112 v) internal returns (string) {
        (uint8 nf, uint8 ord, uint16 n_cells, uint32 n_bits, uint16 n_refs, uint32 size) = (uint8(v >> 104 & 0xFF), uint8(v >> 96 & 0xFF),
            uint16(v >> 80 & 0xFFFF), uint32(v >> 48 & 0xFFFFFFFF), uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF));
        return format("{:3} {:3}  {:4} {:7} {:4} {:7}  ", nf, ord, n_cells, n_bits, n_refs, size);
    }

    function print_chunk1(bytes14 cd) internal returns (string) {
        uint112 v = uint112(cd);
        if (v > 0)
            return print_chunk0(v);
    }

    function print_chunk(bytes cd) internal returns (string) {
        return print_chunk1(bytes14(cd));
    }
}

library libloadinfo_2 {

    uint8 constant UMA_CHUNK_HEADER_SIZEOF = 14;
    uint8 constant UMA_FILE_HEADER_SIZEOF = 8;
    uint8 constant UMA_CHUNK_HASH_SIZEOF = 32;

    string constant CHUNK_HEADING    = " NF Ord  Cells  Bits  Refs  Size";

    function print_chunks(bytes[] cdd) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        for (bytes bb: cdd)
            o.append(print_chunk(bb) + "\n");
    }

    function print_chunks0(uint112[] vv) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        for (uint112 v: vv)
            o.append(print_chunk0(v) + "\n");
    }

    function print_chunks00(vector(uint112) vv) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        while (!vv.empty()) {
            uint112 v = vv.pop();
            o.append(print_chunk0(v) + "\n");
        }
    }

    function print_stored_chunks00(vector(uint40) vv) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        while (!vv.empty()) {
            uint40 v = vv.pop();
            o.append(print_stored_chunk0(v) + "\n");
        }
    }

    function print_chunks1(bytes14[] bts) internal returns (string o) {
        o = CHUNK_HEADING + "\n";
        for (bytes14 b: bts)
            o.append(print_chunk1(b) + "\n");
    }

    function print_chunks_full(bytes[] cdd, bytes[] hcd) internal returns (string o) {
        o = CHUNK_HEADING + "    Hash code \n";
        uint cap = math.min(cdd.length, hcd.length);
        for (uint i = 0; i < cap; i++)
            o.append(print_chunk(cdd[i]) + format("{:x}\n", uint(bytes32(hcd[i]))));
    }

    function print_stored_chunk0(uint40 v) internal returns (string) {
        (uint8 file_index, uint8 chunk_index, uint8 cells, uint16 chunk_size) = (uint8(v >> 32 & 0xFF), uint8(v >> 24 & 0xFF), uint8(v >> 16 & 0xFF), uint16(v & 0xFFFF));
        (uint8 nf, uint8 ord, uint16 n_cells, uint32 n_bits, uint16 n_refs, uint32 size) = (file_index, chunk_index, cells, uint32(chunk_size) * 8, cells > 0 ? (cells - 1) : 0, chunk_size);
        return format("{:3} {:3}  {:4} {:7} {:4} {:7}  ", nf, ord, n_cells, n_bits, n_refs, size);
    }

    function print_chunk0(uint112 v) internal returns (string) {
        (uint8 nf, uint8 ord, uint16 n_cells, uint32 n_bits, uint16 n_refs, uint32 size) = (uint8(v >> 104 & 0xFF), uint8(v >> 96 & 0xFF),
            uint16(v >> 80 & 0xFFFF), uint32(v >> 48 & 0xFFFFFFFF), uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF));
        return format("{:3} {:3}  {:4} {:7} {:4} {:7}  ", nf, ord, n_cells, n_bits, n_refs, size);
    }

    function print_chunk1(bytes14 cd) internal returns (string) {
        uint112 v = uint112(cd);
        if (v > 0)
            return print_chunk0(v);
    }

    function print_chunk(bytes cd) internal returns (string) {
        return print_chunk1(bytes14(cd));
    }
}

