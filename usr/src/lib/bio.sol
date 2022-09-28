pragma ton-solidity >= 0.58.0;

import "io.sol";
//import "liberr.sol";
import "libstat.sol";

struct s_biobuf {
    s_biobufhdr h;
    string b;
}

//enum td_states { TDS_INACTIVE, TDS_INHIBITED, TDS_CAN_RUN, TDS_RUNQ, TDS_RUNNING }

struct s_biobufhdr {
    int32 icount;    // neg num of bytes at eob
    uint32 ocount;   // num of bytes at bob
    uint32 rdline;   // num of bytes after rdline
    uint16 runesize; // num of bytes of last getrune
    uint16 state;    // r/w/inactive
    uint16 fid;      // open file
    uint16 flag;     // magic if malloc'ed
    uint32 offset;   // offset of buffer in file
    uint32 bsize;    // size of buffer
    uint32 bbuf;     // pointer to beginning of buffer
    uint32 ebuf;     // pointer to end of buffer
    uint32 gbuf;     // pointer to good data in buf
}

library libbio {

    using libstat for s_stat;

    function Bopen(s_proc p, string file, uint16 mode) internal returns (s_biobuf) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        for (uint i = 0; i < n_files; i++) {
            s_of f = fdt[i];
            if (f.path == file)
//              return Bfdopen(p, f.file, mode);
                return Bfdopen(p, uint16(i), mode);
        }
        p.p_xexit = err.ENOENT;
    }

    function Bfdopen(s_proc p, uint16 fd, uint16 mode) internal returns (s_biobuf b) {
        s_of[] fdt = p.p_fd.fdt_ofiles;
        uint n_files = p.p_fd.fdt_nfiles;
        if (fd < n_files) {
            s_of f = fdt[fd];
            s_stat st;
            st.stt(f.attr);
            if (st.st_uid == p.p_ucred.cr_uid || st.st_uid == p.p_ucred.cr_groups[0])
                b = Binit(p, fd, mode);
            else
                p.p_xexit = err.EPERM;
        }
        if (b.h.fid == 0)
            p.p_xexit = err.ENOENT;
    }

    function Binit(s_proc p, uint16 fd, uint16 mode) internal returns (s_biobuf) {
        s_of f = p.p_fd.fdt_ofiles[fd];
        s_stat st;
        st.stt(f.attr);
        return Binits(fd, mode, f.buf.buf, st.st_size);
   }

    function Binits(uint16 fd, uint16 /*mode*/, string buf, uint32 size) internal returns (s_biobuf) {
       return s_biobuf(s_biobufhdr(int32(-size), size, size, 0, 0, fd, 0, 0, size, 0, 0, 0), buf);
    }
    function Bterm(s_biobuf bp) internal returns (uint16) {}
    function Bprint(s_biobuf bp, string bformat) internal returns (uint16) {}
    function Bvprint(s_biobuf bp, string bformat, uint16[] arglist) internal returns (uint16) {}
    function Brdline(s_biobuf bp, byte delim) internal returns (bytes res) {
        if (bp.h.icount >= 0)
            return res;
        bytes buf = bp.b;
        uint32 off = bp.h.offset;
        uint32 cap = bp.h.bsize;
        uint32 i = off;
        while (i < cap && buf[i] != delim)
            i++;
        uint32 brd = i - off;
        if (brd > 0) {
            res = string(buf).substr(off, brd);
            bp.h.offset += brd;
            bp.h.icount += int32(brd);
        }
    }
    function Brdstr(s_biobuf bp, uint16 delim, uint16 nulldelim) internal returns (string) {

    }
    function Blinelen(s_biobuf bp) internal returns (uint16) {}
    function Boffset(s_biobuf bp) internal returns (uint32) {
        return bp.h.offset;
    }
    function Bfildes(s_biobuf bp) internal returns (uint16) {
        return bp.h.fid;
    }
    function Bgetc(s_biobuf bp) internal returns (uint16) {}
    function Bgetrune(s_biobuf bp) internal returns (uint32) {}
    function Bgetd(s_biobuf bp, bytes d) internal returns (uint16) {}
    function Bungetc(s_biobuf bp) internal returns (uint16) {}
    function Bungetrune(s_biobuf bp) internal returns (uint16) {}
    function Bseek(s_biobuf bp, uint32 n, uint8 stype) internal returns (uint32 pos) {
        if (stype == io.SEEK_SET)
            pos = n;
        else if (stype == io.SEEK_CUR)
            pos = n + bp.h.offset;
        else if (stype == io.SEEK_END)
            pos = bp.h.ebuf - n;
        bp.h.offset = n;
    }
    function Bputc(s_biobuf bp, uint16 c) internal returns (uint16) {}
    function Bputrune(s_biobuf bp, uint32 c) internal returns (uint16) {}
    function Bread(s_biobuf bp, uint32 offset, uint32 nbytes) internal returns (uint32) {
        uint32 file_len = bp.h.bsize;
        uint32 cap = nbytes > 0 ? math.min(nbytes, file_len - offset) : file_len - offset;
        bp.h.offset += cap;
        bp.h.icount += int32(cap);
        return cap;
    }
    function Bwrite(s_biobuf bp, bytes addr, uint32 nbytes) internal returns (uint32) {}
    function Bflush(s_biobuf bp) internal returns (uint16) {}
    function Bbuffered(s_biobuf bp) internal returns (uint32) {
        return bp.h.icount >= 0 ? 0 : uint32(-bp.h.icount);
    }
    function Beof(s_biobuf bp) internal returns (bool) {
        return bp.h.icount >= 0;
    }

}