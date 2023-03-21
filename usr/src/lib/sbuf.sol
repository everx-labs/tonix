pragma ton-solidity >= 0.67.0;
import "libstring.sol";
import "uio_h.sol";
struct s_sbuf {
    bytes buf;       // storage buffer
    uint8 error;     // current error code
    uint32 size;     // size of storage buffer
    uint16 len;      // current length of string
    uint32 flags;    // flags
    uint16 sect_len; // current length of section
    uint32 rec_off;  // current record start offset
}

using sbuf for s_sbuf global;

library sbuf {

    using str for string;
    using libstring for string;

    uint8 constant ENOMEM   = 12; // Cannot allocate memory

    uint32 constant SBUF_FIXEDLEN   = 0x00000000; // fixed length buffer (default)
    uint32 constant SBUF_AUTOEXTEND = 0x00000001; // automatically extend buffer
    uint32 constant SBUF_INCLUDENUL = 0x00000002; // nulterm byte is counted in len
    uint32 constant SBUF_DRAINTOEOR = 0x00000004; // use section 0 as drain EOR marker
    uint32 constant SBUF_NOWAIT     = 0x00000008; // Extend with non-blocking malloc
    uint32 constant SBUF_USRFLAGMSK = 0x0000ffff; // mask of flags the user may specify
    uint32 constant SBUF_DYNAMIC    = 0x00010000; // k_buf must be freed
    uint32 constant SBUF_FINISHED   = 0x00020000; // set by sbuf_finish()
    uint32 constant SBUF_DYNSTRUCT  = 0x00080000; // sbuf must be freed
    uint32 constant SBUF_INSECTION  = 0x00100000; // set by sbuf_start_section()
    uint32 constant SBUF_DRAINATEOL = 0x00200000; // drained contents ended in \n

    uint32 constant HD_COLUMN_MASK = 0xff;
    uint32 constant HD_DELIM_MASK  = 0xff00;
    uint32 constant HD_OMIT_COUNT  = 1 << 16;
    uint32 constant HD_OMIT_HEX    = 1 << 17;
    uint32 constant HD_OMIT_CHARS  = 1 << 18;

    function sbuf_new(s_sbuf s, string buf, uint32 length, uint32 flags) internal returns (s_sbuf) {
        uint16 len = buf.strlen();
        uint8 error = len > length ? ENOMEM : 0;
        s = s_sbuf(buf, error, length, len, flags, 0, 0);
        return s;
    }

    function sbuf_new_auto(s_sbuf s) internal returns (s_sbuf) {
        string empty;
        s = sbuf_new(s, empty, 0, SBUF_AUTOEXTEND);
        return s;
    }

    function sbuf_get_flags(s_sbuf s) internal returns (uint32) {
        return s.flags;
    }

    function sbuf_clear_flags(s_sbuf s, uint32 flags) internal {
        s.flags &= flags;
    }

    function sbuf_set_flags(s_sbuf s, uint32 flags) internal {
        s.flags |= flags;
    }

    function sbuf_clear(s_sbuf s) internal {
        delete s.buf;
        s.len = 0;
    }

    function sbuf_setpos(s_sbuf s, uint16 pos) internal returns (uint8) {
        if (pos < s.len)
            s.len = pos;
        return s.error;
    }

    function sbuf_bcat(s_sbuf s, bytes buf, uint16 len) internal returns (uint8) {
        s.add(buf, len, true);
        return s.error;
    }
    function sbuf_bcpy(s_sbuf s, bytes buf, uint16 len) internal returns (uint8) {
        s.add(buf, len, false);
        return s.error;
    }
    function sbuf_cat(s_sbuf s, string ss) internal returns (uint8) {
        s.add(ss, ss.strlen(), true);
        return s.error;
    }
    function sbuf_cpy(s_sbuf s, string ss) internal returns (uint8) {
        s.add(ss, ss.strlen(), false);
        return s.error;
    }
    function sbuf_nl_terminate(s_sbuf s) internal returns (uint8) {
        if (s.len > 0 && s.buf[s.len - 1] != '\n')
            s.add('\n', 1, true);
        return s.error;
    }
    function sbuf_putc(s_sbuf s, bytes1 b) internal returns (uint8) {
        s.add(bytes(b), 1, true);
        return s.error;
    }
    function sbuf_trim(s_sbuf s) internal returns (uint8) {
        bytes buf = s.buf;
        uint16 len = s.len;
        if (len > 0) {
            uint16 i = len;
            while (buf[i - 1] == ' ' && i > 0)
                i--;
            s.len = i;
        }
        return s.error;
    }
    function sbuf_error(s_sbuf s) internal returns (uint8) {
        return s.error;
    }

    function sbuf_finish(s_sbuf s) internal returns (uint8) {
        if (s.len > s.size)
            s.error = ENOMEM;
        s.flags |= SBUF_FINISHED;
        return s.error;
    }
    function sbuf_data(s_sbuf s) internal returns (string) {
        if ((s.flags & SBUF_FINISHED) > 0)
            return s.buf;
    }
    function sbuf_len(s_sbuf s) internal returns (uint32) {
        return s.len;
    }

    function sbuf_done(s_sbuf s) internal returns (bool) {
        return (s.flags & SBUF_FINISHED) > 0;
    }

    function sbuf_delete(s_sbuf s) internal {
        delete s;
    }

    function sbuf_start_section(s_sbuf s) internal returns (uint16 old_lenp) {
        old_lenp = s.sect_len;
        s.flags |= SBUF_INSECTION;
        s.sect_len = 0;
    }

    function sbuf_end_section(s_sbuf s, uint16 old_len, uint8 pad, bytes1 c) internal returns (uint32) {
//        uint16 cur_len = s.sect_len;
        string padbuf;
        repeat (pad)
            padbuf = padbuf + c;
        s.add(padbuf, pad, true);
        s.sect_len = old_len;
    }
    function sbuf_hexdump(s_sbuf s, bytes ptr, uint16 length, string hdr, uint16 flags) internal {

    }
    function sbuf_count_drain(bytes arg, string data, uint16 len) internal returns (uint16) {}
    function sbuf_printf_drain(bytes arg, string data, uint16 len) internal returns (uint16) {}

    function sbuf_vprintf(s_sbuf s, string sfmt, string[] ss, uint16[] dd) internal returns (uint16) {
        for (string s0: ss)
            sfmt.subst("%s", s0);
        for (uint16 d0: dd)
            sfmt.subst("%d", str.toa(d0));
        s.add(sfmt, str.strlen(sfmt), true);
    }

    function sbuf_putbuf(s_sbuf s) internal returns (bytes) {
        if ((s.flags & SBUF_FINISHED) > 0)
            return s.buf;
    }

    function add(s_sbuf s, bytes buf, uint16 len, bool append) internal {
        if (append && (s.flags & SBUF_FINISHED) > 0)
            return;
        uint16 avl = uint16(math.min(len, buf.length));
        uint16 tot = append ? avl + s.len : avl;
        uint16 cap = avl;
        if (tot > s.size) {
            if ((s.flags & SBUF_AUTOEXTEND) > 0)
                s.size = tot;
            else
                cap = uint16(s.size - s.len);
        }
        cap = math.min(cap, avl);
        if (cap > 0) {
            s.buf.append(cap < avl ? string(buf).substr(0, cap) : buf);
//            s.buf.strlcat(buf, cap);
            s.len += cap;
            if ((s.flags & SBUF_INSECTION) > 0)
                s.sect_len += cap;
        }
    }

    function sbuf_uionew(s_sbuf s, s_uio, uint16) internal returns (s_sbuf) {

    }
    function sbuf_bcopyin(s_sbuf s, bytes uaddr, uint16 len) internal returns (uint16) {
        s.add(uaddr, len, false);
    }
    function sbuf_copyin(s_sbuf s, bytes uaddr, uint16 len) internal returns (uint16) {
        s.add(uaddr, len, false);
    }
}