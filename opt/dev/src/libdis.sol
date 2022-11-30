pragma ton-solidity >= 0.65.0;

library libdis {

    // A.2 Stack manipulation primitives
    function a2_stack(byte b, byte n) internal returns (string out, uint sh) {
        sh = 1;
        // A.2.1. Basic stack manipulation primitives.
        if (b == 0x00) out = "NOP";
        else if (b == 0x01) out = "SWAP";
        else if (b < 0x10) {
            out = ppa2("XCHG S", b, 0);
        }
        else if (b == 0x10) {
            sh++;
            out = format("XCHG S{}, S{}", uint8(n) >> 4, uint8(n) & 0x0F);
        }
        else if (b == 0x11) {
            sh++;
            out = ppa("XCHG S0, S", n);
        }
        else if (b < 0x20) {
            out = ppa("XCHG S1, S", b & 0x0F);
        }
        else if (b == 0x20) out = "DUP";
        else if (b == 0x21) out = "OVER";
        else if (b > 0x21 && b < 0x30) { sh++; out = ppa2("PUSH S", b, 0x20); }
        else if (b == 0x30) out = "DROP";
        else if (b == 0x31) out = "NIP";
        else if (b > 0x31 && b < 0x40) { sh++; out = ppa2("POP S", b, 0x30); }
        // A.2.2. Compound stack manipulation primitives.
        else if (b >= 0x50 && b < 0x55) {
            sh++;
            if (b == 0x50) out = ppa("XCHG2", n);
            else if (b == 0x51) out = ppa("XCPU", n);
            else if (b == 0x52) out = ppa("PUXC", n);
            else if (b == 0x53) out = ppa("PUSH2", n);
            else if (b == 0x54) { sh++; out = ppa("WEIRD STACK OP ", n); }
        }
        // A.2.3. Exotic stack manipulation primitives.
        else if (b >= 0x55 && b <= 0x6D) {
            if (b == 0x55) {
                sh++;
                if (n == 0x13) out = "ROT2";
                else if (n > 0x00 && n < 0x10) out = ppa("ROLL ", n);
                else if (uint8(n) % 16 == 0) out = ppa("ROLLREV ", n >> 4);
                else out = ppa("BLKSWAP ", n);
            }
            else if (b == 0x56) { sh++; out = ppa("PUSH S", n); }
            else if (b == 0x57) { sh++; out = ppa("POP S", n); }
            else if (b == 0x58) out = "ROT";
            else if (b == 0x59) out = "ROTREV";
            else if (b == 0x5A) out = "SWAP2";
            else if (b == 0x5B) out = "DROP2";
            else if (b == 0x5C) out = "DUP2";
            else if (b == 0x5D) out = "OVER2";
            else if (b == 0x5E) { sh++; out = ppa("REVERSE ", n); }
            else if (b == 0x5F) {
                sh++;
                if (n < 0x10) out = ppa("BLKDROP ", n);
                else out = ppa("BLKPUSH ", n);
            }
            else if (b == 0x60) out = "PICK";
            else if (b == 0x61) out = "ROLLX";
            else if (b == 0x62) out = "ROLLREVX";
            else if (b == 0x63) out = "BLKSWX";
            else if (b == 0x64) out = "REVX";
            else if (b == 0x65) out = "DROPX";
            else if (b == 0x66) out = "TUCK";
            else if (b == 0x67) out = "XCHGX";
            else if (b == 0x68) out = "DEPTH";
            else if (b == 0x69) out = "CHKDEPTH";
            else if (b == 0x6A) out = "ONLYTOPX";
            else if (b == 0x6B) out = "ONLYX";
            else if (b == 0x6C) {
                sh++;
                if (n >= 0x10) out = ppa("BLKDROP2 ", n);
                else out = "RES STACK OPS";
            }
            else out = uk("EXO STACK", b);
        }
        else out = uk("STACK", b);
    }

    // A.3 Tuple, List, and Null primitives
    function a3_tuple(byte b, byte n) internal returns (string out, uint sh) {
        sh = 1;
        // A.3.1. Null primitives.
        if (b == 0x6D) out = "NULL";
        else if (b == 0x6E) out = "ISNULL";
        // A.3.2. Tuple primitives.
        // 6F
        else if (b == 0x6F) {
            sh++;
            out = uk("TUP", n);
        }
        else out = uk("TUPLE", b);
    }

    // A.4 Constant, or literal primitives
    function a4_constant(bytes bb) internal returns (string out, uint sh) {
        (byte b, byte n, byte na) = (bb[0], bb[1], bb[2]);
        sh = 1;
        // A.4.1. Integer and boolean constants.
        if (b >= 0x70 && b < 0x80) {
            out = ppa2("PUSHINT ", b, 0x70);
        }
        else if (b >= 0x80 && b < 0x86) {
            sh++;
            out = ppa("PUSHINT ", n);
//            out.append(format("<< {:X} {:X} {:X} >>", uint8(b), uint8(n), uint8(na)));
            if (b == 0x80) out = ppa("PUSHINT ", n);
//            else if (b == 0x81 && n == 0xFC && na == 0x18) out.append("-1000");
            else if (b == 0x81) {
                sh++;
                out = format("PUSHINT {}", (uint(uint8(n)) << 8) + uint8(na));
            }
            else if (b == 0x82) {
                uint len = uint8(n) >> 3;
                uint nb = 8 * len + 19;
                uint nbts = nb / 8;
//                uint msb3 = b1 & 0x07;
//                out.append(format("<<< {:X} {:X} {:X} l{} {} {} ms{} b1{} >>>", uint8(b), uint8(n), uint8(na), len, nb, nbts, msb3, b1));
                TvmBuilder d;
                for (uint i = 0; i < nbts; i++)
                    d.storeUnsigned(uint8(bb[i + 2]), 8);
                TvmSlice s1 = d.toSlice();
                out = format("PUSHINT {}", s1.loadUnsigned(s1.bits()));
                sh += nbts;
            }
//            else if (b == 0x82) out = 1005F5E100 — PUSHINT 108.
            else if (b == 0x83) {
                if (n == 0xFF) out = "PUSHNAN";
                else out = ppa1("PUSHPOW2", n);
            }
            else if (b == 0x84) out = ppa1("PUSHPOW2DEC", n);
            else if (b == 0x85) out = ppa1("PUSHNEGPOW2", n);
            else if (b < 0x88) out = ppa("RES INT", n);
        }
        // A.4.2. Constant slices, continuations, cells, and references.
        else if (b == 0x88) out = "PUSHREF";
        else if (b == 0x89) out = "PUSHREFSLICE";
        else if (b == 0x8A) out = "PUSHREFCONT";
        else if (b == 0x8B) {
            sh++;
            out = "PUSHSLICE ";
            if (n == 0x08) out.append("EMPTY");
            else if (n == 0x04) out.append("0");
            else if (n == 0x0C) out.append("1");
            else {
                sh++;
                out.append(format("{} {}{}", uint8(n) >> 4, uint8(n) & 0xF, uint8(na)));
            }
        }
        else if (b == 0x8C) {
            sh++;
            out = ppa("PUSHSLICE ", n);
        }
        else if (b == 0x8D) {
            sh++;
            sh++;
            out = ppa("PUSHSLICE ", n);
        }
        else if (b >= 0x8E && b < 0x90) {
            sh++;
            out = "PUSHCONT";
//            sh++;
//            out.append(format("< {:X} {:X} {:X} >", uint8(b), uint8(n), uint8(na)));
//            out.append(format("{}r {}b {}", uint8(b) % 16, uint8(n), uint8(na)));
        }
        else if (b < 0xA0) {
            sh++;
            out = "PUSHCONT";
//            out.append(format("< {:X} {:X} {:X} >", uint8(b), uint8(n), uint8(na)));
//            sh++;
//            cnt = uint8(b) % 16;
//            out.append(format("{}b {}{}", uint8(b) % 16, uint8(n), uint8(na)));
        }
        else out = uk("CONSTANT", b);
    }

    // A.5 Arithmetic primitives
    function a5_arithmetic(byte b, byte n, byte na) internal returns (string out, uint sh) {
        sh = 1;
        // A.5.1. Addition, subtraction, multiplication.
        if (b == 0xA0) out = "ADD";
        else if (b == 0xA1) out = "SUB";
        else if (b == 0xA2) out = "SUBR";
        else if (b == 0xA3) out = "NEGATE";
        else if (b == 0xA4) out = "INC";
        else if (b == 0xA5) out = "DEC";
        else if (b == 0xA6) { sh++; out = ppa1("ADDCONST", n); }
        else if (b == 0xA7) { sh++; out = ppa1("MULCONST", n); }
        else if (b == 0xA8) out = "MUL";
        // A.5.2. Division.
        else if (b == 0xA9) {
            sh++;
            if (n == 0x04) out = "DIV";// (x y – q := bx=yc).
            else if (n == 0x05) out = "DIVR";// (x y – q0 := bx=y + 1=2c).
            else if (n == 0x06) out = "DIVC";// (x y – q00 := dx=ye).
            else if (n == 0x08) out = "MOD";// (x y – r), where q := bx=yc, r := x mod y := x 􀀀 yq.
            else if (n == 0x0C) out = "DIVMOD";// (x y – q r), where q := bx=yc, r := x 􀀀 yq.
            else if (n == 0x0D) out = "DIVMODR";// (x y – q0 r0), where q0 := bx=y + 1=2c, r0 := x 􀀀 yq0.
            else if (n == 0x0E) out = "DIVMODC";// (x y – q00 r00), where q00 := dx=ye, r00 := x 􀀀 yq00.
            else if (n == 0x24) out = "RSHIFT";//: (x y – bx  2􀀀yc) for 0  y  256.
            else if (n == 0x34) { sh++; out = ppa1("RSHIFT", na); }// tt + 1: (x – bx  2􀀀tt􀀀1c).
            else if (n == 0x38) { sh++; out = ppa1("MODPOW2", na); } // tt + 1: (x – x mod 2tt+1).
            else if (n == 0x85) out = "MULDIVR";// (x y z – q0), where q0 = bxy=z + 1=2c.
            else if (n == 0x8C) out = "MULDIVMOD";// (x y z – q r), where q := bx  y=zc, r := x  y mod z
            else if (n == 0xA4) out = "MULRSHIFT";// (x y z – bxy  2􀀀zc) for 0  z  256.
            else if (n == 0xA5) out = "MULRSHIFTR";// (x y z – bxy  2􀀀z + 1=2c) for 0  z  256.
            else if (n == 0xB4) out = "MULRSHIFT";// tt + 1 (x y – bxy  2􀀀tt􀀀1c).
            else if (n == 0xB5) out = "MULRSHIFTR";// tt + 1 (x y – bxy  2􀀀tt􀀀1 + 1=2c).
            else if (n == 0xC4) out = "LSHIFTDIV";// (x y z – b2zx=yc) for 0  z  256.
            else if (n == 0xC5) out = "LSHIFTDIVR";// (x y z – b2zx=y + 1=2c) for 0  z  256.
            else if (n == 0xD4) out = "LSHIFTDIV";// tt + 1 (x y – b2tt+1x=yc).
            else if (n == 0xD5) out = "LSHIFTDIVR";// tt + 1 (x y – b2tt+1x=y + 1=2c).
            else out = uk("DIV", n);
        }
        // A.5.3. Shifts, logical operations.
        else if (b == 0xAA) { sh++; out = ppa1("LSHIFT", n); }
        else if (b == 0xAB) { sh++; out = ppa1("RSHIFT", n); }
        else if (b == 0xAC) out = "LSHIFT";
        else if (b == 0xAD) out = "RSHIFT";
        else if (b == 0xAE) out = "POW2";
        else if (b == 0xAF) out = "RESEVED";
        else if (b == 0xB0) out = "AND";
        else if (b == 0xB1) out = "OR";
        else if (b == 0xB2) out = "XOR";
        else if (b == 0xB3) out = "NOT";
        else if (b == 0xB4) out = ppa1("FITS", n);
        else if (b == 0xB5) out = ppa1("UFITS", n);
        else if (b == 0xB6) {
            if (n == 0x00) out = "FITSX";
            else if (n == 0x01) out = "UFITSX";
            else if (n == 0x02) out = "BITSIZE";
            else if (n == 0x03) out = "UBITSIZE";
            else if (n == 0x08) out = "MIN";
            else if (n == 0x09) out = "MAX";
            else if (n == 0x0A) out = "MINMAX";
            else if (n == 0x0B) out = "ABS";
            else out = uk("SHIFT", n);
        }
        // A.5.4. Quiet arithmetic primitives.
        // xx — QUIET prefix, transforming any arithmetic operation into its
        else if (b == 0xB7) {
            if (n == 0xA0) out = "QADD";
            else if (n == 0xA9 && na == 0x04) out = "QDIV";
            else if (n == 0xB0) out = "QAND";
            else if (n == 0xB1) out = "QOR";
            else if (n == 0xB5 && na == 0x07) out = "QUFITS 8";
        }
        else out = uk("ARITH", b);
        if (b >= 0xB4)
            sh++;
    }

    // A.6.1. Integer comparison.
    function int_comparison(byte b, byte n) internal returns (string out, uint sh) { // C7
        sh = 1;
        if (b == 0xB8) out = "SGN";
        else if (b == 0xB9) out = "LESS";
        else if (b == 0xBA) out = "EQUAL";
        else if (b == 0xBB) out = "LEQ";
        else if (b == 0xBC) out = "GREATER";
        else if (b == 0xBD) out = "NEQ";
        else if (b == 0xBE) out = "GEQ";
        else if (b == 0xBF) out = "CMP";
        else if (b == 0xC0) out = ppia("EQINT", n);
        else if (b == 0xC2) out = ppia("GTINT", n);
        else if (b == 0xC3) out = ppia("NEQINT", n);
        else if (b == 0xC4) out = "ISNAN";
        else if (b == 0xC5) out = "CHKNAN";
        else if (b == 0xC6) out = "RSRV INT COMP";
        else out = uk("INT COMP", n);
        if (b == 0xC0 || b == 0xC2 || b == 0xC3)
            sh++;
    }

    // A.6.2. Other comparison.
    function other_comparison(byte n) internal returns (string out) { // C7
        // 00 - 13
        if (n == 0x00) out = "SEMPTY";
        else if (n == 0x01) out = "SDEMPTY";
        else if (n == 0x02) out = "SREMPTY";
        else if (n == 0x03) out = "SDFIRST";
        else if (n == 0x04) out = "SDLEXCMP";
        else if (n == 0x05) out = "SDEQ";
        else if (n == 0x08) out = "SDPFX";
        else if (n == 0x09) out = "SDPFXREV";
        else if (n == 0x0A) out = "SDPPFX";
        else if (n == 0x0B) out = "SDPPFXREV";
        else if (n == 0x0C) out = "SDSFX";
        else if (n == 0x0D) out = "SDSFXREV";
        else if (n == 0x0E) out = "SDPSFX";
        else if (n == 0x0F) out = "SDPSFXREV";
        else if (n == 0x10) out = "SDCNTLEAD0";
        else if (n == 0x11) out = "SDCNTLEAD1";
        else if (n == 0x12) out = "SDCNTTRAIL0";
        else if (n == 0x13) out = "SDCNTTRAIL1";
        else out = uk("OTHER COMP", n);
    }

    // A.6 Comparison primitives
    function a6_comparison(byte b, byte n) internal returns (string out, uint sh) {
        sh = 1;
        if (b < 0xC7)
            (out, sh) = int_comparison(b, n);
        else if (b == 0xC7) {
            sh++;
            out = other_comparison(n);
        }
        else out = uk("COMP", b);
    }

    // A.7 Cell primitives
    function a7_cell(byte b, byte n, byte na) internal returns (string out, uint sh) {
        sh = 1;
        // A.7.1. Cell serialization primitives
        if (b >= 0xC8 && b < 0xD0) {
            if (b == 0xC8) out = "NEWC";
            else if (b == 0xC9) out = "ENDC";
            else if (b == 0xCA) { sh++; out = ppia("STI", n); }
            else if (b == 0xCB) { sh++; out = ppa1("STU", n); }
            else if (b == 0xCC) out = "STREF";
            else if (b == 0xCD) out = "STREFBR";
            else if (b == 0xCE) out = "STSLICE";
            else if (b == 0xCF) {
                sh++;
                if (n == 0x00) out = "STIX";
                else if (n == 0x01) out = "STUX";
                else if (n == 0x02) out = "STIXR";
                else if (n == 0x03) out = "STUXR";
                else if (n == 0x04) out = "STIXQ";
                else if (n == 0x05) out = "STUXQ";
                else if (n == 0x06) out = "STIXRQ";
                else if (n == 0x07) out = "STUXRQ";
//                else if (n == 0x08)cc — a longer version of STI cc + 1.
//                else if (n == 0x09)cc — a longer version of STU cc + 1.
                else if (n == 0x0A) { sh++; out = ppa1("STIR", na); }
                else if (n == 0x0B) { sh++; out = ppa1("STUR", na); }
                else if (n == 0x0C) { sh++; out = ppa1("STIQ", na); }
                else if (n == 0x0D) { sh++; out = ppa1("STUQ", na); }
                else if (n == 0x0E) { sh++; out = ppa1("STIRQ", na); }
                else if (n == 0x0F) { sh++; out = ppa1("STURQ", na); }
//                else if (n == 0x10) — a longer version of STREF (c b – b0).
                else if (n == 0x11) out = "STBREF";
//                else if (n == 0x12) — a longer version of STSLICE (s b – b0).
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
            }
            else out = uk("CELL SER", n);
        }
        // A.7.2. Cell deserialization primitives.
        else if (b == 0xD0) out = "CTOS";
        else if (b == 0xD1) out = "ENDS";
        else if (b == 0xD2) { sh++; out = ppa1("LDI", n); }
        else if (b == 0xD3) { sh++; out = ppa1("LDU", n); }
        else if (b == 0xD4) out = "LDREF";
        else if (b == 0xD5) out = "LDREFTOS";
        else if (b == 0xD6) { sh++; out = ppa1("LDSLICE", n); }
        else if (b == 0xD7) {
            sh++;
            if (n == 0x00) out = "LDIX";
            else if (n == 0x01) out = "LDUX";
            else if (n == 0x02) out = "PLDIX";
            else if (n == 0x03) out = "PLDUX";
            else if (n == 0x04) out = "LDIXQ";
            else if (n == 0x05) out = "LDUXQ";
            else if (n == 0x06) out = "PLDIXQ";
            else if (n == 0x07) out = "PLDUXQ";
            else if (n < 0x10) {
                sh++;
                if (n == 0x08) out = "LDI ";
                else if (n == 0x09) out = "LDU ";
                else if (n == 0x0A) out = "PLDI ";
                else if (n == 0x0B) out = "PLDU ";
                else if (n == 0x0C) out = "LDIQ ";
                else if (n == 0x0D) out = "LDUQ ";
                else if (n == 0x0E) out = "PLDIQ ";
                else if (n == 0x0F) out = "PLDUQ ";
                out = ppa2(out, na, -1);
            }
            else if (n == 0x18) out = "LDSLICEX";
            else if (n == 0x49) out = "SBITS";
            else out = uk("LD", n);
        }
        else out = uk("CELL", b);
    }

    // A.8 Continuation and control flow primitives
    function a8_continuation(byte b, byte n, byte na) internal returns (string out, uint sh) {
        sh = 1;
        na;
        // A.8.1. Unconditional control flow primitives.
        // D8 - DC
        if (b == 0xD8) out = "CALLX";
        else if (b == 0xD9) out = "JMPX";
        else if (b == 0xDA) { sh++; out = ppa("CALLXARGS", n); }
        else if (b == 0xDB) {
            sh++;
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
        else if (b >= 0xDC && b < 0xE4) {
            if (b == 0xDC) out = "IFRET";
            else if (b == 0xDD) out = "IFNOTRET";
            else if (b == 0xDE) out = "IF";
            else if (b == 0xDF) out = "IFNOT";
            else if (b == 0xE0) out = "IFJMP";
            else if (b == 0xE1) out = "IFNOTJMP";
            else if (b == 0xE2) out = "IFELSE";
            else if (b == 0xE3) {
                sh++;
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
                else out = uk("COND", n);
            }
        }
        else if (b == 0xE4) out = "REPEAT";
        else if (b == 0xE5) out = "REPEATEND";
        else if (b == 0xE6) out = "UNTIL";
        else if (b == 0xE7) out = "UNTILEND";
        else if (b == 0xE8) out = "WHILE";
        else if (b == 0xE9) out = "WHILEEND";
        else if (b == 0xEA) out = "AGAIN";
        else if (b == 0xEB) out = "AGAINEND";
        else if (b == 0xED) {
            sh++;
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
        else if (b == 0xEE) {
            sh++;
            out = format("BLESSARGS {} {}", uint8(n) / 16, uint8(n) % 16);
        }
        // A.8.7. Dictionary subroutine calls and jumps.
        else if (b >= 0xF0) {
            sh++;
            if (b == 0xF0) out = ppa("CALL ", n);
            else if (b == 0xF1) {
                if (n < 0x40) out = ppa("CALL ", n);
                else if (n < 0x80) out = ppa2("JMP ", n, 0x40);
                else if (n < 0xC0) out = ppa2("PREPARE ", n, 0x80);
                else out = uk("CALL ", n);
            }
            else out = uk("CALL", b);
//            out.append(format("< {:X} {:X} {:X} >", uint8(b), uint8(n), uint8(na)));
        }
        else out = uk("CONT", b);
    }

    // A.9 Exception generating and handling primitives
    function a9_exception(byte b, byte n, byte na) internal returns (string out, uint sh) {
        sh = 2;
        // A.9.1. Throwing exceptions
        if (b == 0xF2) {
            if (n >= 0xC0 && n < 0xF0)
                sh++;
            if (n < 0x40) out = ppa("THROW ", n);
            else if (n < 0x80) out = ppa2("THROWIF ", n, 0x40);
            else if (n < 0xC0) out = ppa2("THROWIFNOT ", n, 0x80);
            else if (n < 0xC8) out = ppa3("THROW", n, na, 0xC0);
            else if (n < 0xE8) out = ppa3("THROWIFNOT", n, na, 0xE0);
            else out = uk("THROW", n);
        }
        else out = uk("EXCEPTION", b);
    }

    // A.10.11. Special Get dictionary and prefix code dictionary operations, and constant dictionaries
    function a10_11_special_get_dictionary(byte n, byte na) internal returns (string out, uint sh) {
        sh = 2;
        if (n == 0xA0) out = "DICTIGETJMP";
        else if (n == 0xA1) out = "DICTUGETJMP";
        else if (n == 0xA2) out = "DICTIGETEXEC";
        else if (n == 0xA3) out = "DICTUGETEXEC";
        else if (n < 0xA8) { sh++; out = ppa3("DICTPUSHCONST", n, na, 0xA4); }
        else if (n == 0xA8) out = "PFXDICTGETQ";
        else if (n == 0xA9) out = "PFXDICTGET";
        else if (n == 0xAA) out = "PFXDICTGETJMP";
        else if (n == 0xAB) out = "PFXDICTGETEXEC";
        else if (n == 0xAE) { sh++; out = ppa3("PFXDICTCONSTGETJMP", n, na, 0xAC); }
        else if (n == 0xBC) out = "DICTIGETJMPZ";
        else if (n == 0xBD) out = "DICTUGETJMPZ";
        else if (n == 0xBE) out = "DICTIGETEXECZ";
        else if (n == 0xBF) out = "DICTUGETEXECZ";
        else out = uk("SPDICT", n);
    }
    // A.10 Dictionary manipulation primitives
    function a10_dictionary(byte b, byte n, byte na) internal returns (string out, uint sh) {
        sh = 1;
        // F4 - F7?
        // A.10.2. Dictionary serialization and deserialization.
        if (b == 0xF4) {
            sh++;
            // 00 - BF
            if (n == 0x05) out = "PLDDICT";
            else if (n == 0x0E) out = "DICTUGET";
            else if (n >= 0xA0 && n < 0xC0) (out, sh) = a10_11_special_get_dictionary(n, na);
            else out = uk("DICT", n);
        }
        else out = uk("DICT", b);
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

//        if (n == 0x00) out = "ACCEPT";
//        else if (n == 0x01) out = "SETGASLIMIT";
//        else if (n == 0x02) out = "BUYGAS";
//        else if (n == 0x04) out = "GRAMTOGAS";
//        else if (n == 0x05) out = "GASTOGRAM";
//        else if (n == 0x0F) out = "COMMIT";
//        else out = uk("GAS", n);
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
//        if (n == 0x00) out = "HASHCU";
//        else if (n == 0x01) out = "HASHSU";
//        else if (n == 0x02) out = "SHA256U";
//        else if (n == 0x10) out = "CHKSIGNU";
//        else if (n == 0x11) out = "CHKSIGNS";
//        // 40 - 43
//        else if (n == 0x40) out = "CDATASIZEQ";
//        else if (n == 0x41) out = "CDATASIZE";
//        else if (n == 0x42) out = "SDATASIZEQ";
//        else if (n == 0x43) out = "SDATASIZE";
//        else out = uk("CRYPTO", n);
    }

    // A.11 Application-specific primitives
    function a11_application(byte b, byte n) internal returns (string out, uint sh) {
        sh = 1;
        // F8 - FB
        if (b == 0xF8) {
            sh++;
            if (n < 0x10) out = gas_related(n);
            else if (n < 0x20) out = pseudo_random(n);
            else if (n < 0x40) out = config(n);
            else out = global(n);
        } else if (b == 0xF9) {
            sh++;
            out = crypto(n);
//        } else out = format("{:X}", uint8(b));
        }
        else out = uk("APP", b);
    }

    function a12_debug(byte n) internal returns (string out, uint sh) {
        sh = 2;
        if (n == 0x00) out = "DUMPSTK";
        else if (n < 0xF0) out = ppa("DEBUG", n);
        else out = uk("DEBUG", n);
    }

    function a13_codepage(byte n) internal returns (string out, uint sh) {
        sh = 2;
        if (n == 0x00) out = "SETCP0";
        else if (n < 0xF0) out = ppa("SETCP", n);
        else out = uk("CODEPAGE", n);
    }

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
        uint len = bb.length;
        uint pos;
        byte b;
        byte n;
        byte na;
        string sout;
        uint sh;
        while (pos < len) {
            b = bb[pos];
            n = pos + 1 < len ? bb[pos + 1] : byte(0x00);
            na = pos + 2 < len ? bb[pos + 2] : byte(0x00);
            if (b < 0x6D) (sout, sh) = a2_stack(b, n);
            else if (b < 0x70) (sout, sh) = a3_tuple(b, n);
            else if (b < 0xA0) (sout, sh) = a4_constant(bb[pos : ]);
            else if (b < 0xB8) (sout, sh) = a5_arithmetic(b, n, na);
            else if (b < 0xC8) (sout, sh) = a6_comparison(b, n);
            else if (b < 0xD8) (sout, sh) = a7_cell(b, n, na);
            else if (b < 0xF2) (sout, sh) = a8_continuation(b, n, na);
            else if (b < 0xF4) (sout, sh) = a9_exception(b, n, na);
            else if (b < 0xF8) (sout, sh) = a10_dictionary(b, n, na);
            else if (b < 0xFE) (sout, sh) = a11_application(b, n);
            else if (b < 0xFF) (sout, sh) = a12_debug(n);
            else if (b == 0xFF) (sout, sh) = a13_codepage(n);
            pos += sh;
            res.push(sout);
        }
    }

    /*function _dda2(bytes bb, string delim, uint indent) internal returns (string out) {
        uint len = bb.length;
        if (len == 0)
            return "";
        uint pos;       // position marker
        string sout;    // instruction to print
        string stabs;   // current indentation
        uint sh;        // instruction byte size
        uint clb;       // current indent region length
        uint[] subr;    // indent stack
        uint sd;        // indent depth
        byte b;
        byte n;
        byte na;
        while (pos < len) {
            uint cnt;
            b = bb[pos];
            n = pos + 1 < len ? bb[pos + 1] : byte(0x00);
            na = pos + 2 < len ? bb[pos + 2] : byte(0x00);
            if (b < 0x6D) (sout, sh) = a2_stack(b, n);
            else if (b < 0x70) (sout, sh) = a3_tuple(b, n);
            else if (b < 0xA0) (sout, sh, cnt) = a4_constant(bb[pos : ]);
            else if (b < 0xB8) (sout, sh) = a5_arithmetic(b, n, na);
            else if (b < 0xC8) (sout, sh) = a6_comparison(b, n);
            else if (b < 0xD8) (sout, sh) = a7_cell(b, n, na);
            else if (b < 0xF2) (sout, sh) = a8_continuation(b, n, na);
            else if (b < 0xF4) (sout, sh) = a9_exception(b, n, na);
            else if (b < 0xF8) (sout, sh) = a10_dictionary(b, n);
            else if (b < 0xFE) (sout, sh) = a11_application(b, n);
            else if (b < 0xFF) (sout, sh) = a12_debug(n);
            else if (b == 0xFF) (sout, sh) = a13_codepage(n);

            out.append(stabs);

            if (is_ref(b, n))
                sout.append(" {" + delim + stabs + "<REF>" + delim + stabs + "}");

            if (cnt > 0) {
                clb = pos + cnt;
                subr.push(clb);
                sd++;
                if (indent > 0)
                    stabs.append("\t");
                sout.append(" {");
            }

            if (clb > 0) {
                if (clb <= pos) {
                    subr.pop();
                    if (sd > 0) {
                        sd--;
                        if (indent > 0)
                            stabs = stabs.substr(0, sd);
                    }
                    sout.append(delim + stabs + "}");
                    clb = subr.empty() ? 0 : subr[sd - 1];
                }
            }
            pos += sh;
            out.append(sout + delim);
        }
    }*/

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

}