pragma ton-solidity >= 0.64.0;

contract lstr {
    function toa(uint num) internal pure returns (string) {
        return format("{}", num);
    }
    function _sizeof(TvmBuilder b) internal pure returns (uint8) {
        return uint8(b.remBits() / 8);
    }
    function strchr(bytes s, byte c) internal pure returns (uint) {
        uint i;
        for (byte b: s) {
            if (b == c)
                return i + 1;
            i++;
        }
    }
    function strcmp(string s1, string s2) internal pure returns (uint8) {
        return s1 == s2 ? 0 : 1;
    }
    function strstr(string text, string pattern) internal pure returns (uint) {
        uint text_len = text.byteLength();
        uint pattern_len = pattern.byteLength();
        if (text_len < pattern_len)
            return 0;
        for (uint i = 0; i <= text_len - pattern_len; i++)
            if (text.substr(i, pattern_len) == pattern)
                return i + 1;
    }
    function subst(string text, string pattern, string symbols) internal pure {
        uint p = strstr(text, pattern);
        if (p > 0)
            text = text.substr(0, p - 1) + symbols + text.substr(p - 1 + pattern.byteLength());
    }
    function translate(string text, string pattern, string symbols) internal pure returns (string sout) {
        uint pattern_len = pattern.byteLength();
        uint p = strstr(text, pattern);
        string stail = text;
        while (p > 0) {
            sout.append(stail.substr(0, p - 1) + symbols);
            stail = stail.substr(p - 1 + pattern_len);
            p = strstr(stail, pattern);
        }
        sout.append(stail);
        text = sout;
    }
    /*function b8(bytes8 bb) internal returns (string) {
        uint len;
        for (byte b: bb) {
            if (b == 0)
                break;
            len++;
        }
        return bb[ : len];
    }*/
    function null_term(bytes bb) internal pure returns (string) {
        uint len;
        for (byte b: bb) {
            if (b == 0)
                break;
            len++;
        }
        return bb[ : len];
    }        
}


/*struct vb_list {
    TvmBuilder bld;
    uint8 nargs;
    uint8[] tp;
    uint8[] sz;
}
struct bbuf {
    TvmBuilder b;
    byte prev;
    byte cur;
    byte next;
}*/
/*library lbb {
    function getc(bbuf bb) internal returns (byte c) {
        c = bb.s.decode(byte)
        if (s.)
    }
    function putc(bbuf bb, byte c) internal {
        (TvmBuilder b, byte prev, byte cur, byte next) = bb.unpack();
        b.store(c);
        bb.s = bb.b.toSlice();
    }
}
library lvb {
    function vb_str(bytes arg) internal returns (TvmBuilder b) {
        b.store(uint8(arg.length()));
        for (byte c: arg)
            b.store(c);
    }
    function vb_uint(uint arg) internal returns (TvmBuilder b) {
        uint16 len = uBitSize(arg);
        b.store(len);
        b.storeUnsigned(arg, len);
    }
    function vb_str0(bytes bb) internal returns (TvmBuilder b) {
        uint len;
        TvmBuilder b1;
        for (byte c: bb) {
            if (c == 0)
                break;
            len++;
            b1.store(c);
        }
        b.store(uint8(len));
        b.store(b1);
    }
}*/