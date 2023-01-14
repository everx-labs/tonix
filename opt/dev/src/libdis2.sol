pragma ton-solidity >= 0.65.0;

library libdis2 {

    function is_ref(byte b, byte n) internal returns (bool res) {
        if ((b == 0xDB && n >= 0x3C && n <= 0x3E) ||
            (b == 0xE3 && (n <= 0x03 || n >= 0x0D && n < 0x10)))
                return true;
        return false;
    }
    function dda(bytes bb) internal returns (string out) {
        return _dda(bb, "\n");
    }
    function _dda(bytes bb, string delim) internal returns (string out) {
        string[] res = _dda3(bb);
        for (uint i = 0; i < res.length; i++)
            out.append(res[i] + (i + 1 < res.length ? delim : ""));
    }
    function _dda3(bytes bb) internal returns (string[] res) {
        uint b1 = 0x00000FF7F3337370FF0FF13F00000700FFFF6FFF3F000000FFFFFFFFFFFCFFFF;
        uint b2 = 0xFFEBF0080C4C0C8F00700EC00000003900009000C0EFFFFF0000000000030000;
        uint b3 = 0x001400000080800000800000FFFFF8C600000000001000000000000000000000;
        uint b4 = 0x000000000000000000000000FFFFF80200000000000000000000000000000000; // 8: 2 B C D E F; 9
        uint len = bb.length;
        uint pos;
        string t;
        while (pos < len) {
            byte b = bb[pos++];
            uint op = uint8(b);
            uint v = 1 << op;
            if ((v & b1) > 0) {
                res.push(f1(b));
                continue;
            }
            byte n = bb[pos++];
            if ((v & b2) > 0)
                t = f2(b, n);
            else {
                uint sh = (v & b3) > 0 ? extra_size(b, n) : 0;
                if ((v & b4) > 0) {
                    (uint bl, uint nb, uint nr) = arg_size(b, n);
                    res.push(format("({}|{}>{})", bl, nb, nr));
                    if (nb > 0) {
//                        res.push(bb[pos : pos + bl]);
                        t = fv(b, n, bl, bb[pos : pos + bl]);
                        pos += bl;
                    }
                }
                else if (sh == 0) t = f2(b, n);
                else if (sh == 1) t = f3(b, n, bb[pos++]);
                else {
                    t = fv(b, n, sh, bb[pos : pos + sh]);
                    pos += sh;
                }
            }
            res.push(t);
        }
    }

    function f1(byte b) internal returns (string t) {
        t = "? f1 ?";
        (uint b1, uint b2) = math.divmod(uint8(b), 16);
        if (b1 < 4) {
            if (b2 == 0) {
                string[4] a0 = ["NOP", "XCHG", "DUP", "DROP"];
                t = a0[b1];
            }
            else if (b2 == 1) {
                string[4] a1 = ["SWAP", "XCHG S0,", "OVER", "NIP"];
                t = a1[b1];
            }
            else {
                string[4] bs = ["XCHG", "XCHG S1,", "PUSH", "POP"];
                t = bs[b1] + psd(b2);
            }
        }
        else if (b1 == 0x05) { // 3F00
            t = b2 == 8 ? "ROT" : b2 == 9 ? "ROTREV" : b2 == 10 ? "SWAP2" : b2 == 11 ? "DROP2" : b2 == 12 ? "DUP2" : b2 == 13 ? "OVER2" : uk("5", b);
        }
        else if (b1 == 0x06) { // 6FFF
            t = b2 == 0 ? "PICK" : b2 == 1 ? "ROLLX" : b2 == 2 ? "ROLLREVX" : b2 == 3 ? "BLKSWX" : b2 == 4 ? "REVX" : b2 == 5 ? "DROPX" :
                b2 == 6 ? "TUCK" : b2 == 7 ? "XCHNGX" : b2 == 8 ? "DEPTH" : b2 == 9 ? "CHKDEPTH" : b2 == 10 ? "ONLYTOPX" : b2 == 11 ? "ONLYX" :
                b2 == 13 ? "NULL" : b2 == 14 ? "ISNULL" : uk("6", b);
        }
        else if (b1 == 0x07) t = "PUSHINT " + pia(b2);
        else if (b1 == 0x08) {
            t = b2 == 8 ? "PUSHREF" : b2 == 9 ? "PUSHREFSLICE" : b2 == 10 ? "PUSHREFCONT" : uk("8", b);
        }
        else if (b1 == 0x09) t = "PUSHCONT";
        else if (b1 == 0x0a) { // F13F
            t = b2 == 0 ? "ADD" : b2 == 1 ? "SUB" : b2 == 2 ? "SUBR" : b2 == 3 ? "NEGATE" : b2 == 4 ? "INC" : b2 == 5 ? "DEC" : b2 == 8 ? "MUL" :
                b2 == 12 ? "LSHIFT" : b2 == 13 ? "RSHIFT" : b2 == 14 ? "POW2" : b2 == 15 ? "RESERVED" : uk("A", b);
        }
        else if (b1 == 0x0b) { // FF0F
            t = b2 == 0 ? "AND" : b2 == 1 ? "OR" : b2 == 2 ? "XOR" : b2 == 3 ? "NOT" : b2 == 8 ? "SGN" : b2 == 9 ? "LESS" : b2 == 10 ? "EQUAL" :
                b2 == 11 ? "LEQ" : b2 == 12 ? "GREATER" : b2 == 13 ? "NEQ" : b2 == 14 ? "GEQ" : b2 == 15 ? "CMP" : uk("B", b);
        }
        else if (b1 == 0x0c) { // 7370
            t = b2 == 4 ? "ISNAN" : b2 == 5 ? "CHKNAN" : b2 == 6 ? "RSRVINTCOMP" : b2 == 8 ? "NEWC" : b2 == 9 ? "ENDC" :
                b2 == 12 ? "STREF" : b2 == 13 ? "STREFBR" : b2 == 14 ? "STSLICE" : uk("C", b);
        }
        else if (b1 == 0x0d) { // F333
            t = b2 == 0 ? "CTOS" : b2 == 1 ? "ENDS" : b2 == 4 ? "LDREF" : b2 == 5 ? "LDREFTOS" : b2 == 7 ? "CALLX" : b2 == 8 ? "JMPX" :
                b2 == 12 ? "IFRET" : b2 == 13 ? "IFNOTRET" : b2 == 14 ? "IF" : b2 == 15 ? "IFNOT" : uk("D", b);
        }
        else if (b1 == 0x0e) { // 0FF7
            t = b2 == 0 ? "IFJMP" : b2 == 1 ? "IFNOTJMP" : b2 == 2 ? "IFELSE" : b2 == 4 ? "REPEAT" : b2 == 5 ? "REPEATEND" : b2 == 6 ? "UNTIL" :
                b2 == 7 ? "UNTILEND" : b2 == 8 ? "WHILE" : b2 == 9 ? "WHILEEND" : b2 == 10 ? "AGAIN" : b2 == 11 ? "AGAINEND" : uk("E", b);
        }
    }
    function f2(byte b, byte n) internal returns (string t) {
        (uint b1, uint b2) = math.divmod(uint8(b), 16);
        (uint n1, uint n2) = math.divmod(uint8(n), 16);
        t = format("? f2 ? {:X}{:X}", uint8(b), uint8(n));
        if (b1 == 0x04) t = "XCHG3" + psd(b2) + "," + psd(n1) + "," + psd(n2);
        else if (b1 == 0x05) { // C0EF
            if (b2 < 4) {
                t = b2 == 0 ? "XCHG2" : b2 == 1 ? "XCPU" : b2 == 2 ? "PUXC" : "PUSH2";
                t.append(psd(n1) + "," + psd(n2));
            }
            else if (b2 == 5) t = format("BLKSWAP {}, {}", n1 + 1, n2 + 1);
            else if (b2 == 6) t = ppa("PUSH S", n);
            else if (b2 == 7) t = ppa("POP S", n);
            else if (b2 == 14) t = format("REVERSE {}, {}", n1 + 2, n2);
            else if (b2 == 15) {
                if (n1 == 0) t = ppa("BLKDROP ", n);
                else t = format("BLKPUSH {}, {}", n1, n2);
            }
            else t = uk("5", b);
        }
        else if (b1 == 0x06) { // 9000
            if (b2 == 0x0C) t = "BLKDROP2" + psd(n1) + "," + psd(n2);
            else if (b2 == 0x0F) t = todo("STACK", b, n);
            else t = uk("6", b);
        }
        else if (b1 == 0x08) { // 0039
            if (b2 == 0) t = ppia("PUSHINT", n);
            else if (b2 == 3) t = ppa1("PUSHPOW2", n);
            else if (b2 == 4) t = ppa1("PUSHPOW2DEC", n);
            else if (b2 == 5) t = ppa1("PUSHNEGPOW2", n);
            else if (b2 == 6 || b2 == 7) t = "RESVINT";
            else t = uk("8", b);
        }
        else if (b1 == 0x0a) { // 0EC0
            if (b2 == 6) t = ppia("ADDCONST", n);
            else if (b2 == 7) t = ppia("MULCONST", n);
            else if (b2 == 9) t = division(n);
            else if (b2 == 10) t = ppa1("LSHIFT", n);
            else if (b2 == 11) t = ppa1("RSHIFT", n);
            else t = uk("A", b);
        }
        else if (b1 == 0x0b) { // 0070
            if (b2 == 4) t = ppia("FITS", n);
            else if (b2 == 5) t = ppa1("UFITS", n);
            else t = uk("B", b);
        }
        else if (b1 == 0x0c) { // 0C8F
            if (b2 < 4) {
                string[4] cc = ["EQINT", "LESSINT", "GTINT", "NEQINT"];
                t = ppia(cc[b2], n);
            }
            else if (b2 == 7) t = cmp_other(n);
            else if (b2 == 10) t = ppia("STI", n);
            else if (b2 == 11) t = ppa1("STU", n);
            else if (b2 == 15) t = cell_st(n);
            else t = uk("C", b);
        }
        else if (b1 == 0x0d) { // 0C4C
            if (b2 == 2) t = ppia("LDI", n);
            else if (b2 == 3) t = ppa1("LDU", n);
            else if (b2 == 7) t = cell_ld(n);
            else if (b2 == 10) t = ppa1("CALLXARGS", n);
            else if (b2 == 11) t = uncond_cf(n);
            else t = uk("D", b);
        }
        else if (b1 == 0x0e) { // F008
            if (b2 == 3) t = cond_cf(n);
            else if (b2 == 13) t = conts(n);
            else if (b2 == 14) t = todo("BLESSARGS", b, n);
            else t = uk("E", b);
        }
        else if (b1 == 0x0f) { // F008
            if (b2 == 0) t = ppa("CALL", n);
            else if (b == 0xF2) t = a9_exception(n);
            else if (b == 0xF4) t = a10_dictionary(n);
            else if (b2 >= 0x08 && b2 <= 0x0b) t = a11_application(b, n);
            else if (b2 == 0x0E) t = a12_debug(n);
            else if (b2 == 0x0F) t = a13_codepage(n);
            else t = uk("F", b);
        }
    }

    function arg_size(byte b, byte n) internal returns (uint bl, uint nb, uint nr) {
        if (b == 0x82) {
            bl = uint8(n) >> 3;
            nb = 8 * bl + 19;
        } else if (b == 0x8B) {
            bl = uint8(n) >> 4;
            nb = 8 * bl + 4;
        } else if (b == 0x8C) {
            nr = (uint8(n) >> 6) + 1;
            bl = uint8(n) & 0x1F;
            nb = 8 * bl + 1;
        } else if (b == 0x8D) {
            nr = uint8(n) >> 6;
            bl = uint8(n) & 0x1F;
            nb = 8 * bl + 6;
        } else if (b == 0x8E) {
            bl = uint8(n) & 0x7F;
            nr = uint8(n) >> 7;
            nb = 8 * bl + 4; // ???
        } else if (b == 0x8F) {
            bl = uint8(n) & 0x7F;
            nr = (uint8(n) >> 7) + 2;
            nb = 8 * bl + 4; // ???
        } else if (b >= 0x90 && b < 0xA0) {
            bl = uint8(b) >> 4;
            nb = 8 * bl + 4; // ???
        }
    }

    function extra_size(byte b, byte n) internal returns (uint sh) {
        if (b == 0x54 && n < 0x80) sh++;
        else if (b == 0x81) sh++;
        else if (b == 0x82) {
            uint len = uint8(n) >> 3;
            uint nb = 8 * len + 19;
            sh = nb / 8;
        }
        else if (b == 0x8B) {
            uint len = uint8(n) >> 4;
            uint nb = 8 * len + 4;
            sh = nb / 8;
        }
        else if (b == 0x8C) sh++;
        else if (b == 0x8D) sh++;
        else if (b == 0x8E) {
//            out.append(format("< {:X} {:X} {:X} >", uint8(b), uint8(n), uint8(na)));
        }
//        else if (b == 0xB7) t = todo("QUIET", b, n);
        else if (b == 0xA9 && (n == 0x34 || n == 0x38 || n == 0xB4 || n == 0xB5 || n == 0xD4 || n == 0xD5)) sh++;
        else if (b == 0xCF && (n >= 0x08 && n < 0x10 || n == 0x38 || n == 0x3C)) sh++;
        else if (b == 0xD7 && (n >= 0x08 && n < 0x10 || n >= 0x1C && n < 0x20 || n >= 0x28 && n < 0x30)) sh++;
        else if (b == 0xF2 && n >= 0xC0 && n < 0xF0) sh++;
        else if (b == 0xF4 && (n >= 0xA4 && n < 0xA8 || n >= 0xAC && n < 0xAE)) sh++;
    }
    function fv(byte b, byte n, uint sh, bytes bb) internal returns (string t) {
        t = format("? fv ? {:X}{:X}", uint8(b), uint8(n));
        if (b > 0x80 && b < 0xA0) t = const_ints(b, n, sh, bb); // F8C6
    }
    function f3(byte b, byte n, byte na) internal returns (string t) {
        t = format("? f3 ? {:X}{:X}", uint8(b), uint8(n));
        if (b == 0x54) t = todo("COMP STACK", b, n);
        else if (b > 0x80 && b < 0x90) t = const_ints3(b, n, na); // F8C6
        else if (b == 0xA9) t = div3(n, na);
        else if (b == 0xB7) t = todo("QUIET", b, n);
        else if (b == 0xCF) t = cell_st3(n, na);
        else if (b == 0xD7) t = cell_ld3(n, na);
        else if (b == 0xF2) t = throw3(n, na);
        else if (b == 0xF4) t = dict_const3(n, na);
    }

    function fo(byte b) internal returns (string t) {
        t = format("? fo ? {:X}", uint8(b));
    }

    function const_ints3(byte b, byte n, byte na) internal returns (string t) {
        (uint b1, uint b2) = math.divmod(uint8(b), 16);
        // A.4.1. Integer and boolean constants.
        if (b1 != 0x08) t = uk("8", b);
        else if (b2 == 1) t = format("PUSHINT {}", (uint(uint8(n)) << 8) + uint8(na));
        else if (b2 == 0x0b) {
            t = "PUSHSLICE ";
            if (n == 0x08) t.append("EMPTY");
            else if (n == 0x04) t.append("0");
            else if (n == 0x0C) t.append("1");
            else t.append(format("{} {}{}", uint8(n) >> 4, uint8(n) & 0xF, uint8(na)));
        }
        else if (b2 == 0x0c) t = ppa("PUSHSLICE ", n);
        else if (b2 == 0x0d) t = ppa("PUSHSLICE ", n);
        else if (b2 >= 0x0e) t = "PUSHCONT";
    }

    function const_ints(byte b, byte n, uint sh, bytes bb) internal returns (string t) {
        byte na;
        if (sh > 0) na = bb[0];
        (uint b1, uint b2) = math.divmod(uint8(b), 16);
        // A.4.1. Integer and boolean constants.
        if (b1 == 0x09) {
            t = "PUSHCONT { " + string(bb) + " }";
        }
        else if (b1 != 0x08) t = uk("8", b);
        else if (b2 == 1) t = format("PUSHINT {}", (uint(uint8(n)) << 8) + uint8(na));
        else if (b2 == 2) {
            uint len = uint8(n) >> 3;
            uint nb = 8 * len + 19;
            uint nbts = nb / 8;
            TvmBuilder d;
            for (uint i = 0; i < nbts; i++)
                d.storeUnsigned(uint8(bb[i]), 8);
            TvmSlice s1 = d.toSlice();
            t = format("PUSHINT {}", s1.loadUnsigned(s1.bits()));
        }
        else if (b2 == 0x0b) {
            t = "PUSHSLICE ";
            if (n == 0x08) t.append("EMPTY");
            else if (n == 0x04) t.append("0");
            else if (n == 0x0C) t.append("1");
            else t.append(format("{} {}{}", uint8(n) >> 4, uint8(n) & 0xF, uint8(na)));
        }
//        else if (b2 == 0x0c) t = ppa("PUSHSLICE ", n);
//        else if (b2 == 0x0d) t = ppa("PUSHSLICE ", n);
//        else if (b2 >= 0x0e) t = "PUSHCONT";
        else if (b2 == 0x0c) t = "PUSHSLICE " + string(bb);
        else if (b2 == 0x0d) t = "PUSHSLICE " + string(bb);
        else if (b2 >= 0x0e) t = "PUSHCONT { " + string(bb) + " }";
    }
    // A.6.2. Other comparison.
    function cmp_other(byte b) internal returns (string out) {
        uint n = uint8(b);
        return n == 0 ? "SEMPTY" : n == 1 ? "SDEMPTY" : n == 2 ? "SREMPTY" : n == 3 ? "SDFIRST" : n == 4 ? "SDLEXCMP" : n == 5 ? "SDEQ" :
            n == 8 ? "SDPFX" : n == 9 ? "SDPFXREV" : n == 10 ? "SDPPFX" : n == 11 ? "SDPPFXREV" : n == 12 ? "SDSFX" : n == 13 ? "SDSFXREV" :
            n == 14 ? "SDPSFX" : n == 15 ? "SDPSFXREV" : n == 16 ? "SDCNTLEAD0" : n == 17 ? "SDCNTLEAD1" : n == 18 ? "SDCNTTRAIL0" :
            n == 19 ?  "SDCNTTRAIL1" : uk("OTHER COMP", b);
    }

    // A.5.2. Division.
    function division(byte n) internal returns (string out) {
        if (n == 0x04) out = "DIV";// (x y – q := bx=yc).
        else if (n == 0x05) out = "DIVR";// (x y – q0 := bx=y + 1=2c).
        else if (n == 0x06) out = "DIVC";// (x y – q00 := dx=ye).
        else if (n == 0x08) out = "MOD";// (x y – r), where q := bx=yc, r := x mod y := x 􀀀 yq.
        else if (n == 0x0C) out = "DIVMOD";// (x y – q r), where q := bx=yc, r := x 􀀀 yq.
        else if (n == 0x0D) out = "DIVMODR";// (x y – q0 r0), where q0 := bx=y + 1=2c, r0 := x 􀀀 yq0.
        else if (n == 0x0E) out = "DIVMODC";// (x y – q00 r00), where q00 := dx=ye, r00 := x 􀀀 yq00.
        else if (n == 0x24) out = "RSHIFT";//: (x y – bx  2􀀀yc) for 0  y  256.
        else if (n == 0x85) out = "MULDIVR";// (x y z – q0), where q0 = bxy=z + 1=2c.
        else if (n == 0x8C) out = "MULDIVMOD";// (x y z – q r), where q := bx  y=zc, r := x  y mod z
        else if (n == 0xA4) out = "MULRSHIFT";// (x y z – bxy  2􀀀zc) for 0  z  256.
        else if (n == 0xA5) out = "MULRSHIFTR";// (x y z – bxy  2􀀀z + 1=2c) for 0  z  256.
        else if (n == 0xC4) out = "LSHIFTDIV";// (x y z – b2zx=yc) for 0  z  256.
        else if (n == 0xC5) out = "LSHIFTDIVR";// (x y z – b2zx=y + 1=2c) for 0  z  256.
        else out = uk("DIV", n);
    }

    function div3(byte n, byte na) internal returns (string out) {
        if (n == 0x34) out = ppa1("RSHIFT", na);
        else if (n == 0x38) out = ppa1("MODPOW2", na);
        else if (n == 0xB4) out = ppa1("MULRSHIFT", na);
        else if (n == 0xB5) out = ppa1("MULRSHIFTR", na);
        else if (n == 0xD4) out = ppa1("LSHIFTDIV", na);
        else if (n == 0xD5) out = ppa1("LSHIFTDIVR", na);
        else out = uk("DIV3", n);
    }
    function cell_st3(byte n, byte na) internal returns (string out) {
        if (n == 0x0A) out = ppa1("STIR", na);
        else if (n == 0x0B) out = ppa1("STUR", na);
        else if (n == 0x0C) out = ppa1("STIQ", na);
        else if (n == 0x0D) out = ppa1("STUQ", na);
        else if (n == 0x0E) out = ppa1("STIRQ", na);
        else if (n == 0x0F) out = ppa1("STURQ", na);
        else out = uk("ST3", n);
    }
    function cell_ld3(byte n, byte na) internal returns (string out) {
        if (n == 0x08) out = "LDI ";
        else if (n == 0x09) out = "LDU ";
        else if (n == 0x0A) out = "PLDI ";
        else if (n == 0x0B) out = "PLDU ";
        else if (n == 0x0C) out = "LDIQ ";
        else if (n == 0x0D) out = "LDUQ ";
        else if (n == 0x0E) out = "PLDIQ ";
        else if (n == 0x0F) out = "PLDUQ ";
        out = out.empty() ? uk("LD 3", n) : ppa2(out, na, -1);
    }

    function throw3(byte n, byte na) internal returns (string out) {
        if (n < 0xC8) out = ppa3("THROW", n, na, 0xC0);
        else if (n < 0xE8) out = ppa3("THROWIFNOT", n, na, 0xE0);
        else out = uk("THROW 3", n);
    }

    function dict_const3(byte n, byte na) internal returns (string out) {
        if (n < 0xA8) out = ppa3("DICTPUSHCONST", n, na, 0xA4);
        else if (n == 0xAE) out = ppa3("PFXDICTCONSTGETJMP", n, na, 0xAC);
        else out = uk("DICT CONST 3", n);
    }

    function cell_st(byte n) internal returns (string out) {
        if (n == 0x00) out = "STIX";
        else if (n == 0x01) out = "STUX";
        else if (n == 0x02) out = "STIXR";
        else if (n == 0x03) out = "STUXR";
        else if (n == 0x04) out = "STIXQ";
        else if (n == 0x05) out = "STUXQ";
        else if (n == 0x06) out = "STIXRQ";
        else if (n == 0x07) out = "STUXRQ";
        else if (n == 0x10) out = "STREF";
        else if (n == 0x11) out = "STBREF";
        else if (n == 0x12) out = "STSLICE";
        else if (n == 0x13) out = "STB";
        else if (n == 0x14) out = "STREFR";
        else if (n == 0x15) out = "STBREFR";
        else if (n == 0x16) out = "STSLICER";
        else if (n == 0x17) out = "STBR";
        else if (n == 0x18) out = "STREFQ";
        else if (n == 0x19) out = "STBREFQ";
        else if (n == 0x1A) out = "STSLICEQ";
        else if (n == 0x1B) out = "STBQ";
        else if (n == 0x1C) out = "STREFRQ";
        else if (n == 0x1D) out = "STBREFRQ";
        else if (n == 0x1E) out = "STSLICERQ";
        else if (n == 0x1F) out = "STBRQ";
        else if (n == 0x20) out = "STREFCONST";
        else if (n == 0x21) out = "STREF2CONST";
        else if (n == 0x23) out = "ENDXC";
        else if (n == 0x28) out = "STILE4";
        else if (n == 0x29) out = "STULE4";
        else if (n == 0x2A) out = "STILE8";
        else if (n == 0x2B) out = "STULE8";
        else if (n == 0x30) out = "BDEPTH";
        else if (n == 0x31) out = "BBITS";
        else if (n == 0x32) out = "BREFS";
        else if (n == 0x33) out = "BBITREFS";
        else if (n == 0x35) out = "BREMBITS";
        else if (n == 0x36) out = "BREMREFS";
        else if (n == 0x37) out = "BREMBITREFS";
//                else if (n == 0x38)cc — BCHKBITS cc + 1 (b –), checks whether cc + 1 bits can be
//                else if (n == 0x39) out = "BCHKBITS";// (b x – ), checks whether x bits can be stored into b,
//                else if (n == 0x3A) out = "BCHKREFS";// (b y – ), checks whether y references can be stored
//                else if (n == 0x3B) out = "BCHKBITREFS";// (b x y – ), checks whether x bits and y references
//            else if (n = 0x3C)cc — BCHKBITSQ cc + 1 (b – ?), checks whether cc + 1 bits can be
//            else if (n = 0x3D) — BCHKBITSQ (b x – ?), checks whether x bits can be stored into
//            else if (n = 0x3E) — BCHKREFSQ (b y – ?), checks whether y references can be stored
//            else if (n = 0x3F) — BCHKBITREFSQ (b x y – ?), checks whether x bits and y references
//            else if (n = 0x40) — STZEROES (b n – b0), stores n binary zeroes into Builder b.
//            else if (n = 0x41) — STONES (b n – b0), stores n binary ones into Builder b.
//            else if (n = 0x42) — STSAME (b n x – b0), stores n binary xes (0  x  1) into
//            else if (n = 0xC0)_xysss — STSLICECONST sss (b – b0), stores a constant subslice
//            else if (n = 0x81) — STSLICECONST ‘0’ or STZERO (b – b0), stores one binary zero.
//            else if (n = 0x83) — STSLICECONST ‘1’ or STONE (b – b0), stores one binary one.
        else if (n == 0x83) out = "STONE";
//            else if (n = 0xA2) — equivalent to STREFCONST.
//            else if (n = 0xA3) — almost equivalent to STSLICECONST ‘1’; STREFCONST.
//            else if (n = 0xC2) — equivalent to STREF2CONST.
//            else if (n = 0xE2) — STREF3CONST.
        else out = uk("CELL SER", n);
    }

    function cell_ld(byte n) internal returns (string out) {
        if (n == 0x00) out = "LDIX";
        else if (n == 0x01) out = "LDUX";
        else if (n == 0x02) out = "PLDIX";
        else if (n == 0x03) out = "PLDUX";
        else if (n == 0x04) out = "LDIXQ";
        else if (n == 0x05) out = "LDUXQ";
        else if (n == 0x06) out = "PLDIXQ";
        else if (n == 0x07) out = "PLDUXQ";
        else if (n == 0x18) out = "LDSLICEX";
        else if (n == 0x49) out = "SBITS";
        else out = uk("LD", n);
    }
    // A.8.1. Unconditional control flow primitives.
    function uncond_cf(byte n) internal returns (string out) {
        if (n == 0x30) out = "RET";
        else if (n == 0x31) out = "RETALT";
        else if (n == 0x32) out = "BRANCH";
        else if (n == 0x34) out = "CALLCC";
        else if (n == 0x35) out = "JMPXDATA";
        else if (n == 0x38) out = "CALLXVARARGS";
        else if (n == 0x39) out = "RETVARARGS";
        else if (n == 0x3A) out = "JMPXVARARGS";
        else if (n == 0x3B) out = "CALLCCVARARGS";
        else if (n == 0x3C) out = "CALLREF";
        else if (n == 0x3D) out = "JMPREF";
        else if (n == 0x3E) out = "JMPREFDATA";
        else out = uk("UNCOND CF", n);
    }

    // A.8.2. Conditional control flow primitives.
    function cond_cf(byte n) internal returns (string out) {
        if (n == 0x00) out = "IFREF";
        else if (n == 0x01) out = "IFNOTREF";
        else if (n == 0x02) out = "IFJMPREF";
        else if (n == 0x03) out = "IFNOTJMPREF";
        else if (n == 0x04) out = "CONDSEL";
        else if (n == 0x05) out = "CONDSELCHK";
        else if (n == 0x08) out = "IFRETALT";
        else if (n == 0x09) out = "IFNOTRETALT";
        else if (n == 0x0D) out = "IFREFELSE";
        else if (n == 0x0E) out = "IFELSEREF";
        else if (n == 0x0F) out = "IFREFELSEREF";
        else if (n == 0x14) out = "REPEATBRK";
        else if (n == 0x15) out = "REPEATENDBRK";
        else if (n == 0x16) out = "UNTILBRK";
        else if (n == 0x17) out = "UNTILENDBRK";
        else if (n == 0x18) out = "WHILEBRK";
        else if (n == 0x19) out = "WHILEENDBRK";
        else if (n == 0x1A) out = "AGAINBRK";
        else if (n == 0x1B) out = "AGAINENDBRK";
        else if (n < 0x20) out = "RESV LOOPS W/BREAKS";
        // TODO:
        //9_n — IFBITJMP n
        //B_n — IFNBITJMP n
        //D_n — IFBITJMPREF n
        //F_n — IFNBITJMPREF n
        else out = uk("COND CF", n);
    }

    function conts(byte n) internal returns (string out) {
        // A.8.4. Manipulating the stack of continuations.
        if (n < 0x10) out = ppa("RETURNARGS", n);
        else if (n == 0x10) out = "RETURNVARARGS";
        else if (n == 0x11) out = "SETCONTVARARGS";
        else if (n == 0x12) out = "SETNUMVARARGS";
        else if (n < 0x1E) out = uk("STKCONT", n);
        // A.8.5. Creating simple continuations and closures.
        else if (n == 0x1E) out = "BLESS";
        else if (n == 0x1F) out = "BLESSVARARGS";
        else if (n < 0x40) out = uk("SIMPCONT", n);
        // A.8.6. Operations with continuation savelists and control registers.
        else if (n == 0x44) out = "PUSHROOT";
        else if (n == 0x54) out = "POPROOT";
        else if (n >= 0x50 && n < 0x60) out = ppa2("POPCTR C", n, 0x50);
        else out = uk("Cont/CR", n);
    }

    // A.9 Exception generating and handling primitives
    function a9_exception(byte n) internal returns (string out) {
        // A.9.1. Throwing exceptions
        if (n < 0x40) out = ppa("THROW ", n);
        else if (n < 0x80) out = ppa2("THROWIF ", n, 0x40);
        else if (n < 0xC0) out = ppa2("THROWIFNOT ", n, 0x80);
        else out = uk("THROW", n);
    }

    // A.10.11. Special Get dictionary and prefix code dictionary operations, and constant dictionaries
    function a10_11_special_get_dictionary(byte n) internal returns (string out) {
        if (n == 0xA0) out = "DICTIGETJMP";
        else if (n == 0xA1) out = "DICTUGETJMP";
        else if (n == 0xA2) out = "DICTIGETEXEC";
        else if (n == 0xA3) out = "DICTUGETEXEC";
        else if (n == 0xA8) out = "PFXDICTGETQ";
        else if (n == 0xA9) out = "PFXDICTGET";
        else if (n == 0xAA) out = "PFXDICTGETJMP";
        else if (n == 0xAB) out = "PFXDICTGETEXEC";
        else if (n == 0xBC) out = "DICTIGETJMPZ";
        else if (n == 0xBD) out = "DICTUGETJMPZ";
        else if (n == 0xBE) out = "DICTIGETEXECZ";
        else if (n == 0xBF) out = "DICTUGETEXECZ";
        else out = uk("SPDICT", n);
    }

    // A.10 Dictionary manipulation primitives
    function a10_dictionary(byte n) internal returns (string out) {
        // A.10.2. Dictionary serialization and deserialization.
        if (n == 0x05) out = "PLDDICT";
        else if (n == 0x0E) out = "DICTUGET";
        else if (n >= 0xA0 && n < 0xC0) out = a10_11_special_get_dictionary(n);
        else out = uk("DICT", n);
    }

    // A.11.2. Gas-related primitives
    function gas_related(byte n) internal returns (string out) { // F8
        // 00 - 0F
        mapping (byte => string) m;
        m[0x00] = "ACCEPT";
        m[0x01] = "SETGASLIMIT";
        m[0x02] = "BUYGAS";
        m[0x04] = "GRAMTOGAS";
        m[0x05] = "GASTOGRAM";
        m[0x0F] = "COMMIT";
        return m.exists(n) ? m[n] : uk("GAS", n);
    }

    // A.11.3. Pseudo-random number generator primitives.
    function pseudo_random(byte n) internal returns (string out) { // F8
        // 10 - 1F
        if (n == 0x10) out = "RANDU256";
        else if (n == 0x11) out = "RAND";
        else if (n == 0x14) out = "SETRAND";
        else if (n == 0x15) out = "ADDRAND";
        else out = uk("RAND", n);
    }

    // A.11.4. Configuration primitives
    function config(byte n) internal returns (string out) { // F8
        // 20 - 3F
        if (n == 0x23) out = "NOW";
        else if (n == 0x28) out = "MYADDR";
        else if (n > 0x20 && n < 0x30) out = ppa2("GETPARAM ", n, 0x20);
        else if (n == 0x29) out = "CONFIGROOT";
        else if (n == 0x30) out = "CONFIGDICT";
        else if (n == 0x32) out = "CONFIGPARAM";
        else if (n == 0x33) out = "CONFIGOPTPARAM";
        else out = uk("CONF", n);
    }

    // A.11.5. Global variable primitives
    function global(byte n) internal returns (string out) { // F8
        // 40 - FF
        if (n == 0x40) out = "GETGLOBVAR";
        else if (n > 0x40 && n < 0x60) out = ppa2("GETGLOB ", n, 0x40);
        else if (n == 0x60) out = "SETGLOBVAR";
        else if (n > 0x60 && n < 0x80) out = ppa2("SETGLOB ", n, 0x60);
        else out = uk("GLOBAL", n);
    }

    // A.11.6. Hashing and cryptography primitives
    function crypto(byte n) internal returns (string out) { // F9
        // 10 - 1F
        mapping (byte => string) m;
        m[0x00] = "HASHCU";
        m[0x01] = "HASHSU";
        m[0x02] = "SHA256U";
        m[0x10] = "CHKSIGNU";
        m[0x11] = "CHKSIGNS";
        m[0x40] = "CDATASIZEQ";
        m[0x41] = "CDATASIZE";
        m[0x42] = "SDATASIZEQ";
        m[0x43] = "SDATASIZE";

        return m.exists(n) ? m[n] : uk("CRYPTO", n);
    }

    // A.11 Application-specific primitives
    function a11_application(byte b, byte n) internal returns (string out) {
        // F8 - FB
        if (b == 0xF8) {
            if (n < 0x10) out = gas_related(n);
            else if (n < 0x20) out = pseudo_random(n);
            else if (n < 0x40) out = config(n);
            else out = global(n);
        } else if (b == 0xF9) {
            out = crypto(n);
        }
        else out = uk("APP", b);
    }

    function a12_debug(byte n) internal returns (string out) {
        if (n == 0x00) out = "DUMPSTK";
        else if (n < 0xF0) out = ppa("DEBUG", n);
        else out = uk("DEBUG", n);
    }

    function a13_codepage(byte n) internal returns (string out) {
        if (n == 0x00) out = "SETCP0";
        else if (n < 0xF0) out = ppa("SETCP", n);
        else out = uk("CODEPAGE", n);
    }

    function pia(uint n) internal returns (string) {
        string[16] sd = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "-5", "-4", "-3", "-2", "-1"];
        return n < 16 ? sd[n] : "!ERROR!";
    }

    function psd(uint n) internal returns (string) {
        string[16] sd = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"];
        return n < 16 ? " S" + sd[n] : "!ERROR!";
    }
    function ppa(string insn, byte arg) internal returns (string out) {
        return format("{}{}", insn, uint8(arg));
    }
    function ppia(string insn, byte arg) internal returns (string out) {
        TvmBuilder d;
        d.store(arg);
        return format("{} {}", insn, d.toSlice().loadSigned(d.bits()));
    }
    function ppa1(string insn, byte arg) internal returns (string out) {
        return format("{} {}", insn, uint16(uint8(arg)) + 1);
    }
    function ppa2(string insn, byte arg, int16 offset) internal returns (string out) {
        return format("{}{}", insn, uint8(arg) - offset);
    }

    function ppa3(string insn, byte arg1, byte arg2, int16 offset) internal returns (string out) {
        return format("{} {}", insn, (uint8(arg1) - offset << 8) + uint8(arg2));
    }

    function uk(string ctg, byte arg) internal returns (string out) {
        return format("?? {}: {:X}", ctg, uint8(arg));
    }

    function todo(string ctg, byte arg, byte arg2) internal returns (string out) {
        return format("TODO: {} {:X}{:X}", ctg, uint8(arg), uint8(arg2));
    }

}


//
//0i
//10ij
//11ii
//1i
//2i
//3i
//4ijk
//50ij
//51ij
//52ij
//53ij
//540ijk
//541ijk
//542ijk
//543ijk
//544ijk
//545ijk
//546ijk
//547ijk
//54C_
//55ij
//550i
//55i0
//56ii
//57ii
//5Eij
//5F0i
//5Fij
//6Cij
//6F1k
//6F2n
//6F3k
//6F4n
//6F5k
//6F6k
//6F7k
//6FBij
//7i
//80xx
//81xxxx
//82lxxx
//83xx
//84xx
//85xx
//8Crxxssss
//8Drxxsssss
//8F_rxxcccc
//9xccc
//A6cc
//A7cc
//A934tt
//A938tt
//A9B4tt
//A9B5tt
//A9D4tt
//A9D5tt
//AAcc
//ABcc
//B4cc
//B5cc
//B7xx
//C0yy
//C1yy
//C2yy
//C3yy
//CAcc
//CBcc
//CF08cc
//CF09cc
//CF0Acc
//CF0Bcc
//CF0Ccc
//CF0Dcc
//CF0Ecc
//CF0Fcc
//CF3Ccc
//D2cc
//D3cc
//D6cc
//D708cc
//D709cc
//D70Acc
//D70Bcc
//D70Ccc
//D70Dcc
//D70Ecc
//D70Fcc
//D714_c
//D71Ecc
//D71Fcc
//D72A_xsss
//D72E_xsss
//D74E_n
//DApr
//DB0p
//DB1p
//DB2r
//DB36pr
//E39_n
//E3B_n
//E3D_n
//E3F_n
//ECrn
//EC0n
//ECrF
//ED0p
//EErn
//EE0n
//ED4i
//ED5i
//ED6i
//ED7i
//ED8i
//ED9i
//EDAi
//EDBi
//EDCi
//EErn
//F0n
//F12_n
//F16_n
//F1A_n
//F22_nn
//F26_nn
//F2A_nn
//F2C4_nn
//F2CC_nn
//F2D4_nn
//F2DC_nn
//F2E4_nn
//F2EC_nn
//F3pr
//F4A6_n
//F4AE_n
//F82i
//F85_k
//F87_k
//FEnn
//FEFnssss
//FE0n
//FE2n
//FE3n
//FEFnssss
//FEFn00ssss
//FEFn01ssss
//FFnn
//FFFz