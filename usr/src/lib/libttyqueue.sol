pragma ton-solidity >= 0.62.0;
import "uio_h.sol";
import "tty_h.sol";
import "str.sol";
import "libuio.sol";
library libttyqueue {
    uint8 constant TTYINQ_DATASIZE  = 128;
    uint8 constant TTYOUTQ_DATASIZE = 200;

    using libuio for s_uio;
/*struct s_ttyinq {
    string ti_firstblock;
    string ti_startblock;
    string ti_reprintblock;
    string ti_lastblock;
    uint8 ti_begin;
    uint8 ti_linestart;
    uint8 ti_reprint;
    uint8 ti_end;
    uint8 ti_nblocks;
    uint8 ti_quota;
}*/
    function ttyinq_setsize(s_ttyinq ti, s_tty tp, uint8 len) internal returns (uint8) {
    }
    function ttyinq_free(s_ttyinq ti) internal {
        delete ti;
    }
    function ttyinq_read_uio(s_ttyinq ti, s_tty tp, s_uio uio, uint8 readlen, uint8 flushlen) internal returns (uint8) {}
    function ttyinq_write(s_ttyinq ti, bytes buf, uint8 len, uint8 quote) internal returns (uint8) {}
    function ttyinq_write_nofrag(s_ttyinq ti, bytes buf, uint8 len, uint8 quote) internal returns (uint8) {}
    function ttyinq_canonicalize(s_ttyinq ti) internal {}
    function ttyinq_findchar(s_ttyinq ti, string breakc, uint8 maxlen, string lastc) internal returns (uint8) {}
    function ttyinq_flush(s_ttyinq ti) internal {
	    ti.ti_begin = 0;
	    ti.ti_linestart = 0;
	    ti.ti_reprint = 0;
	    ti.ti_end = 0;
    }
    function ttyinq_peekchar(s_ttyinq ti, string c, uint8 quote) internal returns (uint8) {}
    function ttyinq_unputchar(s_ttyinq ti) internal {}
    function ttyinq_reprintpos_set(s_ttyinq ti) internal {}
    function ttyinq_reprintpos_reset(s_ttyinq ti) internal {}

    function ttyinq_getsize(s_ttyinq ti) internal returns (uint8) {
        return ti.ti_nblocks * TTYINQ_DATASIZE;
    }

    function ttyinq_getallocatedsize(s_ttyinq ti) internal returns (uint8) {
        return ti.ti_quota * TTYINQ_DATASIZE;
    }

    function ttyinq_bytesleft(s_ttyinq ti) internal returns (uint16 ) {
        uint16 len = ti.ti_nblocks * TTYINQ_DATASIZE;
        if (len >= ti.ti_end)
            return (len - ti.ti_end);
    }

    function ttyinq_bytescanonicalized(s_ttyinq ti) internal returns (uint16 ) {
        if (ti.ti_begin <= ti.ti_linestart)
            return ti.ti_linestart - ti.ti_begin;
    }

    function ttyinq_bytesline(s_ttyinq ti) internal returns (uint16 ) {
        if (ti.ti_linestart <= ti.ti_end)
            return ti.ti_end - ti.ti_linestart;
    }

/*struct s_ttyoutq {
    string to_firstblock;
    string to_lastblock;
    uint8 to_begin;
    uint8 to_end;
    uint8 to_nblocks;
    uint8 to_quota;
}*/
    function ttyoutq_flush(s_ttyoutq to) internal {
        to.to_begin = 0;
        to.to_end = 0;
    }
    function ttyoutq_setsize(s_ttyoutq to, s_tty tp, uint16 size) internal returns (uint8) {
        to.to_quota = uint8(size / TTYOUTQ_DATASIZE);

    }
    function ttyoutq_free(s_ttyoutq to) internal {
	    ttyoutq_flush(to);
	    to.to_quota = 0;
	    delete to.to_blocks;
	}

    function ttyoutq_read(s_ttyoutq to, uint16 len) internal returns (uint16 rlen, bytes buf) {
        for (string s: to.to_blocks) {
            uint16 slen = str.strlen(s);
            if (len >= slen) {
                buf.append(s);
                len -= slen;
                rlen += slen;
            } else {
                buf.append(s.substr(0, len));
                rlen += len;
                break;
            }
        }
    }
    function ttyoutq_read_uio(s_ttyoutq to, s_tty tp, s_uio uio) internal returns (uint8 error) {
        /*while (uio.uio_resid > 0) {
            string ob;
            uint16 cbegin;
            uint16 cend;
            uint16 clen;
            // See if there still is data
            if (to.to_begin == to.to_end)
                return 0;
            string tob = to.to_firstblock;
            //  The end address should be the lowest of these three:
            // - The write pointer
            // - The blocksize - we can't read beyond the block
            // - The end address if we could perform the full read
            cbegin = to.to_begin;
            cend = math.min(to.to_end, to.to_begin + uio.uio_resid, TTYOUTQ_DATASIZE);
            clen = cend - cbegin;
            // We can prevent buffering in some cases:
            // - We need to read the block until the end.
            // - We don't need to read the block until the end, but there is no data beyond it, which allows us to move the write pointer to a new block.
            if (cend == TTYOUTQ_DATASIZE || cend == to.to_end) {
                // Fast path: zero copy. Remove the first block, so we can unlock the TTY temporarily.
//              TTYOUTQ_REMOVE_HEAD(to);
                to.to_begin = 0;
                if (to.to_end <= TTYOUTQ_DATASIZE)
                    to.to_end = 0;
                else
                    to.to_end -= TTYOUTQ_DATASIZE;
                error = uio.uiomove(tob, clen);
//              TTYOUTQ_RECYCLE(to, tob);
            } else {
//              memcpy(ob, tob.tob_data + cbegin, clen);
//              to.to_begin += clen;
                if (to.to_begin < TTYOUTQ_DATASIZE)
                    error = uio.uiomove(tob, clen);
            }
            if (error != 0)
                return error;
        }*/
        return 0;
    }
    function ttyoutq_write(s_ttyoutq to, bytes buf, uint16 len) internal returns (uint16) {
        uint blen = buf.length;
        uint cap = math.min(blen, len);
        uint nblocks = cap / TTYOUTQ_DATASIZE + 1;
        uint pos = 0;
        while (nblocks-- > 1) {
            //to.append(buf[pos, pos + TTYOUTQ_DATASIZE]);
            pos += TTYOUTQ_DATASIZE;
        }
        //to.append(buf[pos, cap - pos]);
        return uint16(pos);
    }
    function ttyoutq_write_nofrag(s_ttyoutq to, bytes buf, uint16 len) internal returns (uint16) {}

    function ttyoutq_getsize(s_ttyoutq to) internal returns (uint16) {
        return to.to_nblocks * TTYOUTQ_DATASIZE;
    }

    function ttyoutq_getallocatedsize(s_ttyoutq to) internal returns (uint16) {
        return to.to_quota * TTYOUTQ_DATASIZE;
    }

    function ttyoutq_bytesleft(s_ttyoutq to) internal returns (uint16) {
        uint16 len = to.to_nblocks * TTYOUTQ_DATASIZE;
        if (len >= to.to_end)
            return len - to.to_end;
    }

    function ttyoutq_bytesused(s_ttyoutq to) internal returns (uint16) {
        return to.to_end - to.to_begin;
    }

}