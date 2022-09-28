pragma ton-solidity >= 0.59.0;
import "uma_int.sol";
import "uer.sol";

struct strbuf {
    uint16 alloc;
    uint16 len;
    bytes buf;
}

library libstrbuf {

 //strbuf_swap(strbuf a, strbuf b){SWAP(*a, *b);}
    function strbuf_avail(strbuf sb) internal returns (uint16) {
        return sb.alloc > 0 ? sb.alloc - sb.len - 1 : 0;
    }

    function strbuf_setlen(strbuf sb, uint16 len) internal {
        if (len > (sb.alloc > 0 ? sb.alloc - 1 : 0)) {}
//          BUG("strbuf_setlen() beyond buffer");
        sb.len = len;
        /*if (sb.buf != strbuf_slopbuf)
               sb.buf[len] = 0;
        else
            assert(!strbuf_slopbuf[0])*/
    }

    function strbuf_complete(strbuf sb, byte term) internal {
        if (sb.len > 0 && sb.buf[sb.len - 1] != term)
            strbuf_addch(sb, term);
    }

    function strbuf_addch(strbuf sb, byte c) internal {
        if (strbuf_avail(sb) == 0)
            strbuf_grow(sb, 1);
        sb.buf[sb.len++] = c;
        sb.buf[sb.len] = 0;
    }

    function strlen(string s) internal returns (uint16) {
        return uint16(s.byteLength());
    }
    function strbuf_addstr(strbuf sb, string s) internal {
        strbuf_add(sb, s, strlen(s));
    }

    function strbuf_insertstr(strbuf sb, uint16 pos, string s) internal {
        strbuf_insert(sb, pos, s, strlen(s));
    }

//    function strbuf_strip_suffix(strbuf sb, string suffix) internal returns (uint16) {
//      if (strip_suffix_mem(sb.buf, sb.len, suffix)) {
//  	    strbuf_setlen(sb, sb.len);
//          return 1;
//      } else
//          return 0;
//    }

    function  strbuf_split_str(string str, uint16 terminator, uint16 max) internal returns (strbuf[]) {
    	return strbuf_split_buf(str, uint16(str.byteLength()), terminator, max);
    }

    function strbuf_split_max(strbuf sb, uint16 terminator, uint16 max) internal returns (strbuf[]) {
        return strbuf_split_buf(sb.buf, sb.len, terminator, max);
    }

    function strbuf_split(strbuf sb, uint16 terminator) internal returns (strbuf[]) {
        return strbuf_split_max(sb, terminator, 0);
    }

    function strbuf_complete_line(strbuf sb) internal {
        strbuf_complete(sb, '\n');
    }

    function strbuf_init(strbuf sb, uint16 alloc) internal {}
    function strbuf_release(strbuf sb) internal {}
    function strbuf_detach(strbuf sb, uint16 sz) internal returns (string) {}
    function strbuf_attach(strbuf sb, bytes str, uint16 len, uint16 mem) internal {}
    function strbuf_grow(strbuf sb, uint16 amount) internal {}
    function strbuf_trim(strbuf sb) internal {}
    function strbuf_rtrim(strbuf sb) internal {}
    function strbuf_ltrim(strbuf sb) internal {}
    function strbuf_trim_trailing_dir_sep(strbuf sb) internal {}
    function strbuf_trim_trailing_newline(strbuf sb) internal {}
    function strbuf_reencode(strbuf sb, string from, string to) internal returns (uint16) {}
    function strbuf_tolower(strbuf sb) internal {}
    function strbuf_cmp(strbuf first, strbuf second) internal returns (uint16) {}
    function strbuf_addchars(strbuf sb, uint16 c, uint16 n) internal  {}
    function strbuf_insert(strbuf sb, uint16 pos, bytes , uint16) internal {}
    function strbuf_vinsertf(strbuf sb, uint16 pos, string fmt, uint16 ap) internal {}
    function strbuf_insertf(strbuf sb, uint16 pos, string fmt) internal {}
    function strbuf_remove(strbuf sb, uint16 pos, uint16 len) internal {}
    function strbuf_splice(strbuf sb, uint16 pos, uint16 len, bytes data, uint16 data_len) internal {}
    function strbuf_add_commented_lines(strbuf out, string buf, uint16 size) internal {}
    function strbuf_add(strbuf sb, bytes data, uint16 len) internal {}
    function strbuf_addbuf(strbuf sb, strbuf sb2) internal {}
    function strbuf_join_argv(strbuf buf, uint16 argc, string[] argv, byte  delim) internal returns (string) {}
    function strbuf_expand(strbuf sb, string fmt, uint16 fn, bytes context) internal {}
    function strbuf_expand_literal_cb(strbuf sb, string placeholder, bytes context) internal returns (uint16) {}
    function strbuf_expand_dict_cb(strbuf sb, string placeholder, bytes context) internal returns (uint16) {}
    function strbuf_addbuf_percentquote(strbuf dst, strbuf src) internal {}
    function strbuf_add_percentencode(strbuf dst, string src, uint16 flags) internal {}
    function strbuf_humanise_bytes(strbuf buf, uint16 nbytes) internal {}
    function strbuf_humanise_rate(strbuf buf, uint16 nbytes) internal {}
    function strbuf_addf(strbuf sb, string fmt) internal {}
    function strbuf_commented_addf(strbuf sb, string fmt) internal {}
    function strbuf_vaddf(strbuf sb, string fmt, uint16 ap) internal {}
    function strbuf_addftime(strbuf sb, string fmt, uint32 tm, uint16 tz_offset, uint16 suppress_tz_name) internal  {}
    function strbuf_fread(strbuf sb, uint16 size, FILE file) internal returns (uint16) {}
    function strbuf_read(strbuf sb, uint16 fd, uint16 hint) internal returns (uint16) {}
    function strbuf_read_once(strbuf sb, uint16 fd, uint16 hint) internal returns (uint16) {}
    function strbuf_read_file(strbuf sb, string path, uint16 hint) internal returns (uint16) {}
    function strbuf_readlink(strbuf sb, string path, uint16 hint) internal returns (uint16) {}
    function strbuf_write(strbuf sb, FILE stream) internal returns (uint16) {}
    function strbuf_getline_lf(strbuf sb, FILE fp) internal returns (uint16) {}
    function strbuf_getline_nul(strbuf sb, FILE fp) internal returns (uint16) {}
    function strbuf_getline(strbuf sb, FILE file) internal returns (uint16) {}
    function strbuf_getwholeline(strbuf sb, FILE file, uint16 term) internal returns (uint16) {}
    function strbuf_appendwholeline(strbuf sb, FILE file, uint16 term) internal returns (uint16) {}
    function strbuf_getwholeline_fd(strbuf sb, uint16 fd, uint16 term) internal returns (uint16) {}
    function strbuf_getcwd(strbuf sb) internal returns (uint16) {}
    function strbuf_add_absolute_path(strbuf sb, string path) internal {}
    function strbuf_add_real_path(strbuf sb, string path) internal {}
    function strbuf_normalize_path(strbuf sb) internal returns (uint16) {}
    function strbuf_stripspace(strbuf buf, bool skip_comments) internal  {}
    function strbuf_split_buf(string str, uint16 len, uint16 terminator, uint16 max) internal returns (strbuf[]) {}
//    function strbuf_add_separated_string_list(strbuf str, string sep, string_list slist) internal {}
    function strbuf_list_free(strbuf[] list) internal {}
//    function strbuf_repo_add_unique_abbrev(strbuf sb, repository repo, object_id oid, uint16 abbrev_len) internal {}
//    function strbuf_add_unique_abbrev(strbuf sb, object_id oid, uint16 abbrev_len) internal {}
    function launch_editor(string path, strbuf buffer, string env) internal returns (uint16) {}
    function launch_sequence_editor(string path, strbuf buffer, string env) internal returns (uint16) {}
    function strbuf_edit_interactively(strbuf buffer, string path, string env) internal returns (uint16) {}
    function strbuf_add_lines(strbuf sb, string prefix, string buf, uint16 size) internal {}
    function strbuf_addstr_xml_quoted(strbuf sb, string s) internal {}
    function strbuf_branchname(strbuf sb, string name, bool allowed) internal {}
    function strbuf_check_branch_ref(strbuf sb, string name) internal returns (uint16) {}
    function is_rfc3986_unreserved(byte ch) internal returns (uint16) {}
    function is_rfc3986_reserved_or_unreserved(byte ch) internal returns (uint16) {}
    function strbuf_addstr_urlencode(strbuf sb, string name, bool allow_unencoded_fn) internal {}
    function printf_ln(string fmt) internal returns (uint16) {}
    function fprintf_ln(FILE fp, string fmt) internal returns (uint16) {}
    function xstrdup_tolower(string) internal returns (string) {}
    function xstrdup_toupper(string) internal returns (string) {}


//#define strbuf_reset(sb)  strbuf_setlen(sb, 0)
//typedef int (*strbuf_getline_fn)(strbuf , FILE );
//typedef size_t (*expand_fn_t) (strbuf sb, string placeholder, bytes context);
//#define STRBUF_ENCODE_SLASH 1
struct strbuf_expand_dict_entry {
    string placeholder;
    string value;
}
struct FILE {
    uint16 fd;
}
//struct repository;
//typedef int (*char_predicate)(char ch);

    uint8 constant UMA_STRBUF_SIZEOF = 12;
    /*(function init(hunk_header hh, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_HUNK_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uint96 v = uint96(bytes12(arg));
        hh = hunk_header(uint16(v >> 80 & 0xFFFF), uint16(v >> 64 & 0xFFFF), uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint16(v >> 16 & 0xFFFF), uint16(v & 0xFFFF), hh.sect_heading, hh.hunk_diff);
        if (size == to)
            return 0;
        from = to;
        if (size > to)
            hh.text = arg[from : ];
    }
    function fini(hunk_header hh, uint16 size) internal returns (bytes res) {
        (uint16 src_pos, uint16 src_len, uint16 tgt_pos, uint16 tgt_len, uint16 header_len, uint16 hunk_len, string header, string hunk_diff) = hh.unpack();
        uint96 v = (uint96(src_pos) << 80) + (uint96(src_len) << 64) + (uint96(tgt_pos) << 48) + (uint96(tgt_len) << 32) + (uint96(header_len) << 16) + hunk_len;
        res = "" + bytes12(v);
        if (size > UMA_HUNK_HEADER_SIZEOF)
            res.append(text);
    }*/

}