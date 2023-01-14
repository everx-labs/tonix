pragma ton-solidity >= 0.59.0;

import "uma_int.sol";
import "uer.sol";

struct hunk_header {
    uint16 src_pos;
    uint16 src_len;
    uint16 tgt_pos;
    uint16 tgt_len;
    uint16 header_len;
    uint16 hunk_len;
    string hunk_diff;
}

/*diff --git a/builtin b/builtin
index 54ae0a2..7cd01aa 100755
--- a/builtin
+++ b/builtin
@@ -1,4 +1,4 @@*/
struct file_meta_header {
    bytes4 src_index;
    bytes4 tgt_index;
    uint16 user_mask;
    uint32 phunks;
    string file_name;
}

/**
 * the internal representation for a single file (blob).  It records the blob
 * object name (if known -- for a work tree file it typically is a NUL SHA-1),
 * filemode and pathname.  This is what the `diff_addremove()`, `diff_change()`
 * and `diff_unmerge()` synthesize and feed `diff_queue()` function with.
 */
struct diff_filespec {
	string path;
	bytes data;
	bytes cnt_data;
	uint32 size;
	uint16 mode;
}

library libhunk {

    uint8 constant UMA_HUNK_HEADER_SIZEOF = 12;

    function init(hunk_header hh, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_HUNK_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uint96 v = uint96(bytes12(arg));
        hh = hunk_header(uint16(v >> 80 & 0xFFFF), uint16(v >> 64 & 0xFFFF), uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint16(v >> 16 & 0xFFFF), uint16(v & 0xFFFF), hh.hunk_diff);
        if (size == to)
            return 0;
        from = to;
        if (size > to)
            hh.hunk_diff = arg[from : ];
    }

    function fini(hunk_header hh, uint16 size) internal returns (bytes res) {
        (uint16 src_pos, uint16 src_len, uint16 tgt_pos, uint16 tgt_len, uint16 header_len, uint16 hunk_len, string hunk_diff) = hh.unpack();
        uint96 v = (uint96(src_pos) << 80) + (uint96(src_len) << 64) + (uint96(tgt_pos) << 48) + (uint96(tgt_len) << 32) + (uint96(header_len) << 16) + hunk_len;
        res = "" + bytes12(v);
        if (size > UMA_HUNK_HEADER_SIZEOF)
            res.append(hunk_diff);
    }
}

library libpatch {

    uint8 constant UMA_FILE_META_HEADER_SIZEOF = 14;
    uint8 constant UMA_COMMIT_INDEX_SIZEOF = 4;

    function init(file_meta_header fmh, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;

        if (size < UMA_FILE_META_HEADER_SIZEOF)
            return uer.SIZE_TOO_SMALL;
        uint16 from = 0;
        uint16 to = UMA_COMMIT_INDEX_SIZEOF;
        bytes4 src_index = bytes4(arg[from : to]);
        from = to;
        to += UMA_COMMIT_INDEX_SIZEOF;
        bytes4 tgt_index = bytes4(arg[from : to]);
        from = to;
        to += 4;
        uint48 v = uint48(bytes6(arg[from : to]));
        (uint16 user_mask, uint32 phunks) = (uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF));
        from = to;
        string file_name = arg[from : ];
        fmh = file_meta_header(src_index, tgt_index, user_mask, phunks, file_name);
    }

    function fini(file_meta_header fmh, uint16 size) internal returns (bytes res) {
        (bytes4 src_index, bytes4 tgt_index, uint16 user_mask, uint32 phunks, string file_name) = fmh.unpack();
        uint48 v = (uint48(user_mask) << 32) + phunks;
        res = "" + src_index + tgt_index + bytes6(v);
        if (size > UMA_FILE_META_HEADER_SIZEOF)
            res.append(file_name);
    }
}

library libfilemetaheader {

    uint8 constant UMA_FILE_META_HEADER_SIZEOF = 14;
    uint8 constant UMA_COMMIT_INDEX_SIZEOF = 4;

    function init(file_meta_header fmh, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;

        if (size < UMA_FILE_META_HEADER_SIZEOF)
            return uer.SIZE_TOO_SMALL;
        uint16 from = 0;
        uint16 to = UMA_COMMIT_INDEX_SIZEOF;
        bytes4 src_index = bytes4(arg[from : to]);
        from = to;
        to += UMA_COMMIT_INDEX_SIZEOF;
        bytes4 tgt_index = bytes4(arg[from : to]);
        from = to;
        to += 4;
        uint48 v = uint48(bytes6(arg[from : to]));
        (uint16 user_mask, uint32 phunks) = (uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF));
        from = to;
        string file_name = arg[from : ];
        fmh = file_meta_header(src_index, tgt_index, user_mask, phunks, file_name);
    }

    function fini(file_meta_header fmh, uint16 size) internal returns (bytes res) {
        (bytes4 src_index, bytes4 tgt_index, uint16 user_mask, uint32 phunks, string file_name) = fmh.unpack();
        uint48 v = (uint48(user_mask) << 32) + phunks;
        res = "" + src_index + tgt_index + bytes6(v);
        if (size > UMA_FILE_META_HEADER_SIZEOF)
            res.append(file_name);
    }
}
