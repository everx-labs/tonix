pragma ton-solidity >= 0.62.0;
struct s_vmc {
    TvmCell[] kpages;
    bytes[] upages;
}
library libcvm {
    function PHYS_TO_VM_PAGE(s_vmc c, uint32 pa) internal returns (TvmCell) {
        uint pn = pa >> 16;
        if (pn < c.kpages.length)
            return c.kpages[pn];
    }
    function copyin(s_vmc c, uint32 uaddr, uint32 kaddr, uint16 len) internal returns (uint8) {
        uint upn = uaddr >> 16;
        uint kpn = kaddr >> 16;
        bytes up;
        bytes res;
        TvmCell cres;
        TvmCell cp;
        if (upn < c.upages.length) {
            up = c.upages[upn];
            uint uoff = uaddr & 0xFFFF;
            res = uoff > 0 && up.length > uoff ? up[uoff : ] : up;
            TvmBuilder b;
            cres = b.encode(res).toCell();
            if (kpn < c.kpages.length) {
//            cp = kpages[kpn];
                uint koff = kaddr & 0xFFFF;
                if (koff == 0)
                    c.kpages[kpn] = cres;
            }
        }
    }
    function copyin_nofault(bytes uaddr, bytes kaddr, uint16 len) internal returns (uint8) {}
    function copyout(bytes kaddr, bytes uaddr, uint16 len) internal returns (uint8) {}
    function copyout_nofault(bytes kaddr, bytes uaddr, uint16 len) internal returns (uint8) {}
    function copystr(bytes kfaddr, bytes kdaddr, uint16 len) internal returns (uint8, uint16 done) {}
    function copyinstr(bytes uaddr, bytes kaddr, uint16 len) internal returns (uint8, uint16 done) {}
    function bcopy(bytes src, uint16 len) internal returns (bytes dst) {
        uint slen = src.length;
        dst = slen > len ? src[0 : len] : src;
    }
}