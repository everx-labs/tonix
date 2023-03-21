pragma ton-solidity >= 0.67.0;

import "libctl.sol";
import "libdis.sol";
import "libdis2.sol";
contract cstat {

    uint32 _flags;

    function dda(bytes bb) external pure returns (string out) {
        return libdis.dda(bb);
    }

    function dda2(bytes bb) external pure returns (string out) {
        return libdis2.dda(bb);
    }

    function conf(uint32 val) external {
        tvm.accept();
        _flags = val;
    }

    function stat(TvmCell c, uint8 n) external view returns (string out) {
        return _psstat(c.toSlice(), 0, 0, n);
    }

    function statw(TvmCell c, uint8 n) external view returns (string out) {
        return _pwid(c.toSlice(), 0, 0, n);
    }

    function statl(TvmCell c, uint8 n) external view returns (string out) {
        //return _plev([sp(c.toSlice(), 0)], 0, 0, n);
    }

    function pcstat(TvmCell c) external view returns (string out) {
        return _psstat(c.toSlice(), 0, 0, 100);
    }

    /* Print current slice stats */
    function _pslice(TvmSlice s) internal view returns (string out) {
        (uint ncells, uint bit_size, uint total_refs) = s.dataSize(20000);
        (uint16 nbits, uint8 nrefs) = s.size();
        uint depth = s.depth();

        (uint funits, , uint fcells, uint fsize, uint frefs, uint fdepth, , ) = libctl.cstat_options(_flags);
        if (funits == libctl.UNITS_BYTES) {
            bit_size /= 8;
            nbits /= 8;
        }
        out = libctl.print_count("", fsize, nbits, bit_size);
        if (ncells > 1) {
            out = libctl.print_count("\u20B5", fcells, ncells) + " " + out;
            if (ncells != depth) {
                out.append(libctl.print_count(" \u250B", fdepth, depth));
                out.append(libctl.print_count(" >", frefs, nrefs, total_refs));
            }
        }
        string gu = _code_guess(s);
        out.append(gu);
        if (gu == " [ ??? ] ") {
            out.append(_code_hex(s));
            out.append(_code_stream(s));
            out.append(_code_stream2(s));
        }
    }

    function guess(bytes bb) internal pure returns (string out) {
        uint len = bb.length;
        if (len < 1) out = "\u2205";
        else if (len < 2) out = "too short";
        else if (len > 3 && bytes3(bb[len - 3 : ]) == 0xC9ED54) {
            if (bytes3(bb[ : 3]) == 0xED44D0) out = "upd_only_time_in_c4";
            else out = "c7_to_c4";
        }
        else if (len > 4 && bytes5(bb[ : 5]) == 0xF846F2E04C) out = "constructor first";
        else if (len > 7 && bytes8(bb[ : 8]) == 0xF4A420F4BDF2C04E) out = "<internal-selector>";
        else if (len > 9 && bytes10(bb[ : 10]) == 0xED44D0D3FFD33FD30031) out = "c4_to_c7";
        else if (len > 9 && bytes4(bb[ : 4]) == 0x736F6C20) out = bb;
        else if (len > 8 && bytes9(bb[ : 9]) == 0xED44D0D749C301F866) {
            bytes1 b10 = bb[9];
            if (b10 == 0x22) out = "main_internal";
            else if (b10 == 0x21) out = "main_external";
            else out = "!! unrecognized main";
        }
        else if (len > 8 && bytes2(bb[ : 2]) == 0x2082 && bytes2(bb[len - 2 : ]) == 0xE302) out = "public_function_selector";
        else if (len > 11 && bytes11(bb[ : 11]) == 0x30F8426EE300F846F273D1) out = "constructor";
        else if (len > 17 && bytes18(bb[ : 18]) == 0x8AED5320E30320C0FFE30220C0FEE302F20B) out = "<entry-selector>";
        else if (len > 30 && bytes30(bb[ : 30]) == 0xED44D0D749C2018E1470ED44D0F4058040F40EF2BDD70BFFF86270F863E3) out = "c4_to_c7_with_init_storage";
        else out = "???";
    }

    function _slice_as_bytes(TvmSlice s) internal pure returns (bytes bb) {
        uint16 rb = s.bits();
        while (rb >= 8) {
            bb.append(bytes(bytes1(s.loadUnsigned(8))));
            rb -= 8;
        }
    }
    function _code_stream(TvmSlice s) internal pure returns (string out) {
        return " [ " + libdis._dda(_slice_as_bytes(s), "; ") + " ] ";
    }
    function _code_stream2(TvmSlice s) internal pure returns (string out) {
        return " [ " + libdis2._dda(_slice_as_bytes(s), "; ") + " ] ";
    }
    function _code_guess(TvmSlice s) internal pure returns (string out) {
        return " [ " + guess(_slice_as_bytes(s))  + " ] ";
    }
    function _code_hex(TvmSlice s) internal pure returns (string out) {
        uint16 rb = s.bits();
        while (rb > 256) {
            out.append(format(" [{:X}]", s.loadUnsigned(256)));
            rb -= 256;
        }
        out.append(format(" [{:X}] ", s.loadUnsigned(rb)));
    }
    struct sp {
        TvmSlice s;
        uint mask;
    }
    function _plev(sp[] ss, uint level, uint mmask, uint max_depth) internal view returns (string out) {
//        out = format("\n==== Level {}/{} =========\n", level, max_depth);
//        uint len = ss.length;
//        sp[][] next;
//        for (uint i = 0; i < len; i++) {
//            (TvmSlice s, uint mask) = ss[i].unpack();
////            out.append(format("> Slice {}/{}: ", i + 1, len) + _pslice(s));
//            out.append("\u2517" + _pslice(s));
//            if (level < max_depth) {
//                sp[] t;
//                uint nrefs = s.refs();
////                for (uint j = 0; j < nrefs; j++)
////                    t.push(sp(s.loadRefAsSlice(), mask |= j << (level * 2)));
//                if (!t.empty())
//                    next.push(t);
//            }
//        }
//        if (level < max_depth)
//            for (uint i = 0; i < next.length; i++)
//                out.append(_plev(next[i], level + 1, mmask, max_depth));
    }
    function _pwid(TvmSlice s, uint level, uint mask, uint max_depth) internal view returns (string out) {
        out = _pslice(s);
        if (max_depth <= level)
            return out;
        uint nrefs = s.refs();
        mask |= 1 << level;
        out.append("\n");
        string prefix = "\u2517";
        for (uint i = 0; i < nrefs; i++) {
            if (nrefs > 1)
                out.append(prefix);
            out.append(_pwid(s.loadRefAsSlice(), level + 1, mask, max_depth));
        }
    }
    function _psstat(TvmSlice s, uint level, uint mask, uint max_depth) internal view returns (string out) {
        out = _pslice(s);
        if (max_depth <= level)
            return out;
        uint nrefs = s.refs();
        mask |= 1 << level;
        string prefix;
        if (nrefs > 1) {
            prefix.append("\n");
            for (uint j = 0; j < level; j++)
                prefix.append((mask & 1 << j) == 0 ? " " : "\u2503");
        }
        for (uint i = 0; i < nrefs; i++) {
            if (nrefs > 1)
                out.append(prefix);
            if (i + 1 < nrefs)
                out.append("\u2523");
            else {
                out.append("\u2517");
                mask &= ~(1 << level);
            }
            out.append(_psstat(s.loadRefAsSlice(), level + 1, mask, max_depth));
        }
    }
}

