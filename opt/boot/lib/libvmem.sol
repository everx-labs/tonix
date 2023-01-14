pragma ton-solidity >= 0.66.0;

library libvmem {
    uint8 constant FRAG_SIZE    = 31;
    uint8 constant FS_MAXCONTIG	= 16;
    uint8 constant MAXFRAG 	    = 4;
    uint8 constant MINCORE_INCORE	 	    = 0x1;  // Page is incore
    uint8 constant MINCORE_REFERENCED	    = 0x2;  // Page has been referenced by us
    uint8 constant MINCORE_MODIFIED	        = 0x4;  // Page has been modified by us
    uint8 constant MINCORE_REFERENCED_OTHER = 0x8;  // Page has been referenced
    uint8 constant MINCORE_MODIFIED_OTHER	= 0x10; // Page has been modified
    uint8 constant MINCORE_SUPER		    = 0x60; // Page is a "super" page
//    function mincore(mapping (uint32 => TvmCell) m, uint32 addr, uint32 len) internal returns (TvmCell vec) {
//        TvmBuilder b;
//        uint32 cap = addr + len;
//        optional(uint32, TvmCell) p = m.nextOrEq(addr);
//        while (p.hasValue()) {
//            (uint32 a, TvmCell c) = p.get();
//            if (a > cap)
//                break;
//            res[a] = c;
//            p = m.next(a);
//        }
//    }
    function uconv(TvmBuilder b, uint16 n) internal returns (TvmCell) {
        TvmSlice s = b.toSlice();
        uint16 nb = s.bits();
        uint16 sz = nb / n;
        vector(uint248) vv;
        repeat (n) {
            uint248 v = s.loadUnsigned(sz);
            vv.push(v);
        }
        TvmBuilder b0;
        b0.storeUnsigned(n - 1, 2);
        while (!vv.empty())
            b0.store(vv.pop());
        return b0.toCell();
    }

    function mem_check(mapping (uint32 => TvmCell) m) internal returns (string out) {
        for ((uint32 a, TvmCell ca): m) {
            TvmSlice s = ca.toSlice();
            uint nb = s.bits();
            if ((nb % 248) != 2)
                out.append(format("{} not aligned to 248 ({} bits), skipping\n", a, nb));
            else {
//            if (nb > 2) {
                uint ni = s.loadUnsigned(2);
                (uint nf, uint nrem) = math.divmod(nb - 2, 248);
//                TvmBuilder b;
//                repeat (nf)
//                    b.storeUnsigned(s.loadUnsigned(248));
//                if (nrem > 0)
//                    b.store(s.loadUnsigned(uint16(nrem)));
//                res[a] = b.toCell();
                out.append(format("{}: ok, ni {} nf {} nrem {}\n", a, ni, nf, nrem));
            }
        }
    }
    function remap_pages(mapping (uint32 => TvmCell) m, uint32 flags) internal returns (mapping (uint32 => TvmCell) res) {
        flags;
        for ((uint32 a, TvmCell ca): m) {
            TvmSlice s = ca.toSlice();
            uint nb = s.bits();
            if ((nb % 248) == 2) {
//            if (nb > 2) {
//                uint ni = s.loadUnsigned(2);
//                len = ni + 1;
                (uint nf, uint nrem) = math.divmod(nb - 2, 248);
                TvmBuilder b;
                repeat (nf)
                    b.storeUnsigned(s.loadUnsigned(248), 248);
                if (nrem > 0)
                    b.store(s.loadUnsigned(uint16(nrem)));
                res[a] = b.toCell();
            }
        }
    }
    function mmap(mapping (uint32 => TvmCell) m, uint32 addr, uint32 len) internal returns (mapping (uint32 => TvmCell) res) {
        uint32 cap = addr + len;
        optional(uint32, TvmCell) p = m.nextOrEq(addr);
        while (p.hasValue()) {
            (uint32 a, TvmCell c) = p.get();
            if (a >= cap)
                break;
            res[a] = c;
            p = m.next(a);
        }
    }
    function fread(mapping (uint32 => TvmCell) m, uint a) internal returns (string out) {
        (, uint ncyl, uint nfrag) = _va(a);
        if (!m.exists(uint32(ncyl)))
            return "not found";
        vector(TvmSlice) vs = vuload(m[uint32(ncyl)].toSlice());
        repeat (nfrag)
            vs.pop();
        TvmSlice s = vs.pop();
        out.append(format("\n{:x}: {:X}\n", a, s.loadUnsigned(248)));
    }
    function faccess(mapping (uint32 => TvmCell) m, uint a) internal returns (string out) {
        (, uint ncyl, uint nfrag) = _va(a);
        if (!m.exists(uint32(ncyl)))
            return "address not initialized";
        vector(TvmSlice) vs = vuload(m[uint32(ncyl)].toSlice());
        if (nfrag >= vs.length())
            return "address out of range";
        repeat (nfrag)
            vs.pop();
        TvmSlice s = vs.pop();
        (uint16 nb, uint8 nr) = s.size();
        if (nb == 0) {
            if (nr > 0)
                return "data in refs";
            else
                return "empty slice";
        }
        out = format("success! {} bits {} refs", nb, nr);
    }
    function access(mapping (uint32 => TvmCell) m, uint a) internal returns (string out) {
//        (uint ncg, uint32 ncyl, uint nref, uint nfrag) = _va(a);
        (, uint ncl, uint nfrag) = _va(a);
        uint32 ncyl = uint32(ncl);
//        (fsb sb, , ) = fetch_sb(m);
//        if (ncg > sb.ncg)
//            return "out of address space";
        if (!m.exists(ncyl))
            return "address not initialized";
        TvmSlice s = m[ncyl].toSlice();
        (uint16 nb, uint8 nr) = s.size();
        if (nr < nfrag)
            return "no ref in slice";
        if (nfrag > 0)
            s.skip(nfrag);
        TvmSlice s1 = s.loadRefAsSlice();
        (nb, nr) = s1.size();
        if (nb == 0) {
            if (nr > 0)
                return "data in refs";
            else
                return "empty slice";
        }
        out = format("success! {} bits {} refs", nb, nr);
//        out.append(s.decode(string));
    }
    function _conva(uint v) internal returns (string) {
        (uint ncg, uint ncyl, uint nfrag) = _va(v);
        return format("{} -> G{} C{} F{}\n", v, ncg, ncyl, nfrag);
    }
    function suword(mapping (uint32 => TvmCell) m, uint8 base, uint248 word) internal {
        TvmBuilder b;
        b.store(word);
        m[base] = uconv(b, 1);
//        (, uint32 ncyl, ) = _va(base);
//        if (!m.exists(ncyl))
//            m[ncyl] = abi.encode(uint248(word));
    }
    function write(mapping (uint32 => TvmCell) m, uint a, string text) internal returns (string out) {
//        (uint ncg, uint32 ncyl, uint nref, uint nfrag) = _va(a);
        (, uint ncyl, ) = _va(a);
        if (m.exists(uint32(ncyl)))
            return "already exists";
        m[uint32(ncyl)] = abi.encode(text);
        return "success";
    }
    function read(mapping (uint32 => TvmCell) m, uint a) internal returns (string out) {
        (, uint ncyl, ) = _va(a);
        if (!m.exists(uint32(ncyl)))
            return "not found";
        out = abi.decode(m[uint32(ncyl)], string);
        out.append("\nsuccess\n");
    }
    function dump_slices(mapping (uint32 => TvmCell) m) internal returns (string out) {
        for ((uint32 a, TvmCell c): m) {
            out.append(format("{}: ", a));
            out.append(dump_slice(c.toSlice()) + "\n");
        }
    }
    function dump_slice(TvmSlice s) internal returns (string out) {
        (uint16 nb, uint8 nr) = s.size();
        (uint nbb, uint rem) = math.divmod(nb, 8);
        if (rem > 0) {
            out.append(format("Not byte-aligned: {} {} {}  ", nb, nbb, rem));
            nbb++;
        }
        (uint nblk, uint brem) = math.divmod(nbb, FRAG_SIZE);//BLK_SIZE);
        out.append(format("{} refs {} bits {} bytes {} blocks", nr, nb, nbb, nblk));
        if (brem > 0) {
            nblk++;
            (uint bfrag, uint bfrem) = math.divmod(brem, FRAG_SIZE / MAXFRAG);
            if (bfrem > 0)
                bfrag++;
            out.append(format(" {} frags", bfrag));
        }
    }
    function dump_mem(mapping (uint32 => TvmCell) m) internal returns (string out) {
        for ((uint32 a, TvmCell c): m) {
            TvmSlice s = c.toSlice();
            (uint16 nba, uint8 nra) = s.size();
            out.append(format("0x{:03x} | {:3} {} | .... |\n", a, nba / 8, nra));
        }
    }
    function dump_bin(mapping (uint32 => TvmCell) m) internal returns (string out) {
        for ((uint32 a, TvmCell ca): m) {
            TvmSlice s = ca.toSlice();
            (uint16 nba, ) = s.size();
            uint va = a * 4;
            if ((nba % 248) == 2) {
                (, uint248[] vals) = ufetch(ca);
                for (uint248 v: vals) {
                    out.append(va % 2 == 0 ? format("\n0x{:03x}: ", va) : " | ");
                    out.append(format("{:X}", v));
                    va++;
                }
            }
        }
    }
    function _va(uint v) internal returns (uint ncg, uint ncyl, uint nfrag) {
        return (v >> 8 & 0x0F, v >> 2 & 0x3F, v & 0x03);
    }
    function rc(mapping (uint32 => TvmCell) m, uint8 nc) internal returns (TvmSlice) {
        if (m.exists(nc))
            return m[nc].toSlice();
    }
    function wc(mapping (uint32 => TvmCell) m, TvmBuilder b, uint8 nc) internal {
        m[nc] = b.toCell();
    }
    function fublk(mapping (uint32 => TvmCell) m, uint16 base) internal returns (vector(TvmSlice) res) {
        return vuload(m[base].toSlice());
    }
    function fuword(mapping (uint32 => TvmCell) m, uint16 base) internal returns (TvmSlice res) {
        (, uint ncyl, uint nfrag) = _va(base);
        vector(TvmSlice) vs = vuload(m[uint32(ncyl)].toSlice());
        uint len = vs.length();
        if (nfrag < len) {
            repeat (nfrag)
                vs.pop();
            return vs.pop();
        }
    }
    function vadd(vector(TvmBuilder) argv, TvmBuilder arg, uint n) internal {
        if (n == 0 || n > 4)
            return;
        TvmBuilder b;
        b.storeUnsigned(n - 1, 2);
        uint nb = arg.bits();
        TvmSlice s = arg.toSlice();
        uint sz = nb / n;
        repeat (n)
            b.storeUnsigned(s.loadUnsigned(uint16(sz)), 248);
        argv.push(b);
    }
    function vstore(mapping (uint32 => TvmCell) m, vector(TvmBuilder) argv, uint16 base) internal {
        while (!argv.empty() && base > 0)
            m[base--] = argv.pop().toCell();
    }
    function pack_block(vector(TvmBuilder) args) internal returns (TvmCell) {
        uint8 len = args.length();
        if (len > 0 && len < 5) {
            vector(uint248) vv;
            while (!args.empty()) {
                TvmSlice s = args.pop().toSlice();
                uint16 nb = s.bits();
                uint248 v = nb > 248 ? s.loadUnsigned(248) : s.loadUnsigned(nb);
                vv.push(v);
            }
            TvmBuilder b;
            b.storeUnsigned(len - 1, 2);
            while (!vv.empty())
                b.store(vv.pop());
            return b.toCell();
        }
    }

//    function suload(TvmSlice s, ) internal returns (vector(TvmSlice) fv) {
//        uint nb = s.bits();
//        if (nb > 2) {
//            uint ni = s.loadUnsigned(2);
//            ni;
//            (uint nf, uint nrem) = math.divmod(nb - 2, 248);
//            repeat (nf)
//                fv.push(s.loadSlice(248));
//            if (nrem > 0)
//                fv.push(s.loadSlice(uint16(nrem)));
//        }
//    }

    function vuload(TvmSlice s) internal returns (vector(TvmSlice) fv) {
        uint nb = s.bits();
        if (nb > 2) {
            uint ni = s.loadUnsigned(2);
            ni;
            (uint nf, uint nrem) = math.divmod(nb - 2, 248);
            repeat (nf)
                fv.push(s.loadSlice(248));
            if (nrem > 0)
                fv.push(s.loadSlice(uint16(nrem)));
        }
    }
    function ufetch(TvmCell c) internal returns (uint len, uint248[] fv) {
        TvmSlice s = c.toSlice();
        uint nb = s.bits();
        if (nb > 2) {
            uint ni = s.loadUnsigned(2);
            len = ni + 1;
            (uint nf, uint nrem) = math.divmod(nb - 2, 248);
            repeat (nf)
                fv.push(s.loadUnsigned(248));
            if (ni > nf) {}
            if (nrem > 0)
                fv.push(s.loadUnsigned(uint16(nrem)));
        }
    }
}