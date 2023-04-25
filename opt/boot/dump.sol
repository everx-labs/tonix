pragma ton-solidity >= 0.67.0;
import "disk_loader.sol";
import "libufsd.sol";

struct gti {
    uint8[] ntypes;
    TvmCell[] cc;
    mapping (uint8 => string) tnc;
}

struct ctxi {
    uint8 id;
    uint8 pid;
    gti g;
    vari[] vv;
    string tname;
}

struct vari {
    uint8 id;
    uint8 ctx;
    uint8 stp;
    string tname;
}

using libctxi for ctxi global;
library libctxi {
    function add_var(ctxi x, uint8 t, string vn) internal {
        x.vv.push(vari(uint8(x.vv.length), x.id, t, vn));
    }
}

struct stti {
    uint8 id;
    uint8 pid;
    uint8 rsz;
    uint8 bsz;
    uint8 attr;
    uint32 name;
}

using libti for gti global;

library libti {

    function get_stti(gti g, uint seg, uint off) internal returns (stti) {
        TvmSlice s = g.cc[seg].toSlice();
        if (s.bits() >= (off + 1) * 9 * 8) {
            s.skip(off * 9 * 8);
            return s.decode(stti);
        }
    }
    function derive_type(gti g, string[] tname, uint8[] ee) internal {
        stti tti = get_stti(g, 0, ee[0]);
        stti tt = tti;
        tt.id = ++g.ntypes[0];
        tt.pid = tti.id;
        bool f = (tt.attr & 1) > 0;
        uint i = f ? 2 : 4;
        if (f)
            tt.bsz = uint8(ee[1]);
        else {
            TvmBuilder b01;
            TvmBuilder b02;
            uint seg;
            bytes bn;
            uint len;
            uint32 ttv;
            uint off;
            for (uint j = 0; j < ee.length; j++) {
                if (j == 0) {
                    seg = tt.id;
                    bn = bytes(tname[0]);
                    len = bn.length;
                    ttv = uint32(libufsd._tag_name(1, seg, 0, len));
                } else {
                    stti vt = get_stti(g, 2, ee[j] - 1);
                    tt.bsz += vt.bsz;
                    tt.rsz += vt.rsz;
                    seg = vt.id;
                }
                bn = bytes(tname[j]);
                len = bn.length;
                ttv = uint32(libufsd._tag_name(j + 1, seg, off, len));
                off += len;
                b01.store(ttv);
                for (bytes1 bx0: bn)
                    b02.store(bx0);
            }
            g.ntypes.push(uint8(ee.length));
            g.cc.push(b01.toCell());
            g.cc.push(b02.toCell());
        }
        TvmBuilder b1;
        TvmBuilder b2;
        b1.store(g.cc[i].toSlice());
        b2.store(g.cc[i + 1].toSlice());

        bytes btna = bytes(tname[0]);
        tt.name = uint32(libufsd._tag_name(++g.ntypes[f ? 2 : 3], f ? 2 : 3, b2.bits() / 8, btna.length));
        b1.store(tt);
        for (bytes1 bx: btna)
            b2.store(bx);
        g.cc[i] = b1.toCell();
        g.cc[i + 1] = b2.toCell();
    }

    function init_with_base_types(gti g) internal {
       TvmBuilder b;
        for (stti t: TTI)
            b.store(t);
        g.cc.push(b.toCell());
        delete b;
        bytes bb = bytes("?TvmCelluintboolbytesstringstruct[]mapping");
        for (bytes1 b1: bb)
            b.store(b1);
        g.cc.push(b.toCell());
        uint8 nt = uint8(TTI.length);
        g.ntypes = [nt, nt, 0, 0];

        TvmCell empty;
        repeat(4)
            g.cc.push(empty);
    }

    function derive_common_types(gti g) internal {
        for (uint i = 1; i < 5; i++)
            g.derive_type([format("uint{}", i * 8)], [2, uint8(i)]);
    }

    function print_some_types(gti g, uint8 ntypes, TvmCell c1, TvmCell c2) internal returns (string out) {
        TvmSlice s1 = c1.toSlice();
        TvmSlice s2 = c2.toSlice();
        for (uint i = 0; i < ntypes; i++) {
            if (s1.bits() < 72) {
                out.append("Data shortage\n");
                break;
            }
            (uint8 id, uint8 pid, uint8 rsz, uint8 bsz, uint8 attr, uint32 tname) = s1.decode(stti).unpack();
            (uint nid, uint nseg, uint noff, uint nlen) = libufsd._name_of(tname);

            string tns = get_name(s2, noff, nlen);
            out.append(format("{}) {}\t ({})\t{}/{}\t{} {}\t\n",
                id, tns, pid, rsz, bsz, attr, (attr & 1) > 0 ? "INT" : ""));
            g.tnc[id] = tns;
//            out.append(format("id {} seg {} off {} len {}\n", nid, nseg, noff, nlen));
        }
    }
    function get_name(TvmSlice s, uint off, uint len) internal returns (string res) {
        uint16 l = uint16(len * 8);
        s.skip(off * 8);
        TvmBuilder b0;
        TvmBuilder b;
        b.storeUnsigned(s.loadUnsigned(l), l);
        b0.storeRef(b);
        res = abi.decode(b0.toCell(), string);
    }
    function print_types(gti g) internal returns (string out) {
        (uint8[] ntypes, TvmCell[] cc, ) = g.unpack();
        out.append(format("Type counters: Total {} Base {} Fixed {} Structs {}\n", ntypes[0], ntypes[1], ntypes[2], ntypes[3]));
//        for (uint i = 0; i < ntypes.length; i++)
//            out.append(format("{}) {}  ", i, ntypes[i]));
//        for (uint i = 0; i < cc.length; i++)
//            out.append(format("{}) {}  ", i, libufsd._sizeof(cc[i])));
        out.append("#) name  \tParent\tSize\tattr\tdescription\n");
        for (uint i = 1; i < 4; i++)
            out.append(g.print_some_types(ntypes[i], cc[i * 2 - 2], cc[i * 2 - 1]));
        for (uint i = 4; i < ntypes.length; i++) {
            uint nt = ntypes[i];
            TvmSlice s1 = cc[i * 2 - 2].toSlice();
            TvmSlice s2 = cc[i * 2 - 1].toSlice();
            for (uint ii = 0; ii < nt; ii++) {
                if (s1.bits() < 32) {
                    out.append("Data shortage\n");
                    break;
                }
                uint32 tname = s1.decode(uint32);
                (uint id, uint seg, uint off, uint len) = libufsd._name_of(tname);
//                out.append(format("id {} seg {} off {} len {}\n", id, seg, off, len));
                string tn = g.tnc[uint8(seg)];
                string tpx = "    ";
                if (ii == 0) {
                    stti t = libti.fetch_type(g, 2, tn);
                    if (t.pid > 2)
                        out.append(g.tnc[uint8(t.pid)] + " " + get_name(s2, off, len) + " {\n");
                } else
                    out.append(tpx + tn + " " + get_name(s2, off, len) + ";\n");
            }
            out.append("}\n");
        }

    }
    function fetch_type(gti g, uint hint, string tname) internal returns (stti) {
        TvmSlice s1 = g.cc[hint * 2 - 2].toSlice();
        TvmSlice s2 = g.cc[hint * 2 - 1].toSlice();
        uint tlen = bytes(tname).length;
        for (uint i = 0; i < g.ntypes[hint]; i++) {
            if (s1.bits() < 72)
                break;
            stti st = s1.decode(stti);
            uint32 ttname = st.name;
            if ((ttname >> 24 & 0xFF) == tlen && libufsd.get_name(ttname, s2) == tname)
                return st;
        }
    }

   stti[] constant TTI = [
//  id pid rsz bsz attr tname
stti(0, 0, 0,   0, 0, 16777216),
stti(1, 0, 4, 127, 0, 117506305),
stti(2, 0, 0,  32, 1, 67633410),
stti(3, 0, 0,   1, 0, 67895555),
stti(4, 0, 0,   1, 0, 84934916),
stti(5, 0, 1,   0, 0, 102039813),
stti(6, 0, 0,   0, 2, 102433030),
stti(7, 0, 1,   0, 4, 35717383),
stti(8, 0, 1,   0, 6, 119734536)
    ];
}

contract dump is disk_loader {

    function nono(uint64 n) external override pure returns (TvmCell depopo) {
        return abi.encode(n);
    }
    function read_ufsd() internal view returns (ufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a))
            return abi.decode(_ram[a], ufsd);
    }

    function strtok(bytes s, bytes1 c) internal pure returns (uint[] ppp) {
        uint i;
        for (bytes1 b: s) {
            if (b == c)
                ppp.push(i + 1);
            i++;
        }
    }

    function describe_type(string ss) external pure returns (gti g, string out) {
        gti gin;
        gin.init_with_base_types();
        gin.derive_common_types();
        return _describe_types(gin, ss);
    }
    function describe_types(gti gin, string ss) external pure returns (gti g, string out) {
        return _describe_types(gin, ss);
    }

    function cache_type(string s) external view returns (gti g, string out) {

    }
    function parse_type(string ss) external view returns (gti g, string out) {
        gti gin = _load_types();
        return _describe_types(gin, ss);
    }
    function _describe_types(gti gin, bytes bb) internal pure returns (gti g, string out) {
        g = gin;
        uint blen = bb.length;
        uint[] ppp = strtok(bb, '\n');
        uint pos;
        string[] stn;
        uint8[] tid;
        for (uint p: ppp) {
            bytes bbl = bb[pos : p - 1];
            uint[] ppl = strtok(bbl, ' ');
            uint pplen = ppl.length;
            if (pplen > 0) {
                bytes w1 = bbl[ : ppl[0] - 1];
                bytes w2 = pplen > 1 ? bbl[ppl[0] : ppl[1] - 1] : bbl[ppl[0] : ];
                uint w2l = w2.length;
                if (w2l > 0) {
                    if (w2[w2l - 1] == ';')
                        w2 = w2[ : w2l - 1];
                    out.append(format("{} {} {}", pplen, ppl[0], pplen > 1 ? ppl[1] : 0) + "[" + string(w1) + "] [" + string(w2) + "]\n");
                    if (pos == 0) {
                        if (w1 == "struct") {
                            tid.push(6);
                            stn.push(w2);
                        }
                    } else {
                        stti t = libti.fetch_type(g, 2, w1);
                        if (t.id == 0)
                            t = libti.fetch_type(g, 3, w1);
                        if (t.id == 0)
                            t = libti.fetch_type(g, 1, w1);
                        if (t.id > 0) {
                            tid.push(t.pid == 2 ? t.bsz : t.id);
                            stn.push(w2);
                            (uint8 id, uint8 pid, uint8 rsz, uint8 bsz, uint8 attr, uint32 tname) = t.unpack();
                            (uint nid, uint nseg, uint noff, uint nlen) = libufsd._name_of(tname);
                            string tns;// = get_name(s2, noff, nlen);
//                            out.append(format("{}) {}\t ({})\t{}/{}\t{} {}\t\n",
//                                id, tns, pid, rsz, bsz, attr, (attr & 1) > 0 ? "INT" : ""));
//                            g.tnc[id] = tns;
//                            out.append(format("id {} seg {} off {} len {}\n", nid, nseg, noff, nlen));
                        } else
                            out.append("Not found: " + string(w1) + "\n");
                    }
                }
            }
            pos = p;
            if (pos >= blen)
                break;
        }
        g.derive_type(stn, tid);
        out.append(g.print_types());
//        delete g.tnc;
    }
    function show_types() external view returns (string out) {
        gti g = _load_types();
        out.append(g.print_types());
    }
    function base_types() external pure returns (string out, ctxi x) {
        gti g;
        x;
        g.init_with_base_types();
        g.derive_common_types();
        g.derive_type(["udirent", "ft", "ino", "tag"], [6, 1, 2, 4]);
        out.append(g.print_types());
    }
    struct stot {
        uint8 id;
        uint8 pid;
        uint8 qmin;
        uint8 qmax;
        uint8 roff;
        uint16 boff;
        uint8 rsz;
        uint16 bsz;
        uint8 stype;
        string tname;
        string vname;
        string tdesc;
    }

    stot[] constant ST = [
//   id pid qmn qmx rof bof rsz bsz stp tname          vname        tdesc
stot( 0,  0, 0,  0,   0, 0, 0,   0,  0, "???",         "???",           ""),
stot( 1,  0, 1,  1,   0, 0, 0,   0,  0, "TvmCell",     "stateInit",     "state_init"),
stot( 2,  1, 1,  1,   0, 0, 1,   0,  0, "TvmCell",     "data",          "Data cell"),
stot( 3,  2, 1,  1,   0, 0, 0,   0,  0, "mapping (uint32 => TvmCell)", "_ram",     "RAM"),
stot( 4,  3, 1,  1,   1, 0, 0,  22, 12, "s_disk",      "d",             "Disk storage"),
stot( 5,  3, 1,  1,   2, 0, 0,  54, 13, "disklabel",   "l",             "Disk label"),
stot( 6,  3, 1,  1,   3, 0, 1,   8, 14, "part_table",  "pt",            "Partition table"),
stot( 7,  6, 1,  1,   0, 0, 0,  12,  0, "partition[]", "d_partitions",  "Partitions"),
stot( 8,  7, 1,  8,   0, 1, 0,  12,  0, "partition",   "p",             "Partition"),
stot( 9,  3, 1,  1,   5, 0, 0,  31, 15, "ufsb",        "sb",            "Superblock"),
stot(10,  3, 1,  1,   6, 0, 2, 124, 16, "ufsd",        "ud",            "UFS disk"),
stot(11,  3, 4,  4,   7, 0, 0,  96, 17, "ug",          "g",             "Cylinder group"),
stot(12,  3, 1,  1,  19, 0, 1,   4, 21, "udinode[]",   "dis",           "Inodes"),
stot(13, 12, 0, 96,   0, 1, 0,  20, 19, "udinode",     "di",            "Inode"),
stot(14,  3, 0, 10, 252, 0, 3,   0,  3, "uodir",       "uod",           "Open dir"),
stot(15, 14, 1,  1,   0, 1, 1,  20, 20, "udirent[]",   "det",           "Dirent tags"),
stot(16, 15, 2,  0,   1, 0, 1,   7,  0, "udirent",     "de",            "Dir entry"),
stot(17, 14, 2,  0,   2, 0, 1,  20,  1, "bytes1[]",    "des",           "Dirent strings")
    ];

    function cindex(uint8 t) internal pure returns (uint i) {
        for (stot st: ST)
            if (t == st.stype)
                return st.id;
    }
    function pcmp(uint8 t, TvmCell c) external view returns (string out) {
        return _pcmp(t, c);
    }

    function _pstv(uint8 id) internal view returns (string pv) {
        stot pst = ST[id];
        return pst.id == 0 ? "-" : pst.vname;
//        if (pst.id == 0)
//            return "-";
//        pv = pst.vname;
    }
    function pty() external view returns (string out) {
        for (stot st: ST) {
            if (st.tdesc.empty() || st.pid == 0)
                continue;

            string stv;

            bool fdec = st.roff > 0;
            bool find = st.boff > 0;
            bool fran = st.qmax > 1;
            uint ist = fdec ? st.roff - 1 : find ? st.boff - 1 : 0;
            uint iend = fran ? st.qmax - 1 + ist : ist;

            if (fdec)
                stv = "abi.decode(";
            if (fdec || find)
                stv.append(_pstv(st.pid) + format("[{}", ist));
            if (fran)
                stv.append(format("..{}", iend));
            if (fdec || find)
                stv.append("]");
            if (fdec)
                stv.append(", " + st.tname + ")");
            if (!fdec && !fran)
                stv.append(ST[st.pid].vname + "." + st.vname);
            out.append("    " + st.tname + " " + st.vname + " = " + stv + ";\n");
        }
    }
    function print_stot(stot st) internal view returns (string out) {
        (uint8 id, uint8 pid, uint8 qmin, uint8 qmax, uint8 roff, uint16 boff, uint8 rsz, uint16 bsz, uint8 stype, string tname, string vname, string tdesc) = st.unpack();
        string stp = ST[pid].tname;
        out.append(format("{}) {} {} {} parent {} #{}-{} Offset {}r/{}b Size {}r/{}b stype {}\n",
            id, tdesc, tname, vname, stp, qmin, qmax, roff, boff, rsz, bsz, stype));
    }
    function _pcmp(uint8 t, TvmCell c) internal view returns (string out) {
        ufsd ud = read_ufsd();
        (uint nc, uint nb, uint nr) = c.dataSize(200);
        uint cid = cindex(t);
        out.append(format("t {} nc {} nb {} nr {} cid {}\n", t, nc, nb, nr, cid));
        bool f = false;
        if (cid > 0) {
            stot st = ST[cid];
            out.append(print_stot(st));
            if (st.pid == 4)
                f = c != _ram[st.roff];
            out.append(st.tname + ": " + (f ? "differs" : "identical"));
        } else
            out.append("not found");
        out.append("\n");
        if (!f)
            return out;

        if (t == 16) {
//            out.append("UFS disk: ");
//            if (c == _ram[UUDISK_LOC])
//                return out + "identical\n";
//            out.append("differs\n");
            ufsd d = abi.decode(c, ufsd);
            out.append(libufsd.print_disk_header(d));
            out.append(libufsd.print_ug(d.cg));
            out.append(libufsd.print_sb(d.fs));
            out.append("==========\n");
            out.append(libufsd.print_disk_header(ud));
            out.append(libufsd.print_ug(ud.cg));
            out.append(libufsd.print_sb(ud.fs));
        } else if (t == 21) {
//            out.append("Inode block: ");
//            if (c == _ram[ud.inoblock])
//                return out + "identical\n";
//            out.append("differs\n");
            udinode[] ndis = abi.decode(c, udinode[]);
            udinode[] cdis = abi.decode(_ram[ud.inoblock], udinode[]);
            for (uint i = 0; i < ndis.length; i++) {
                udinode nd = ndis[i];
                if (i < cdis.length) {
                    if (nd.mtime != cdis[i].mtime) {
                        out.append("> " + libufsd.print_udino(nd));
                        out.append("< " + libufsd.print_udino(cdis[i]));
                    }
                } else
                    out.append("+ " + libufsd.print_udino(nd));
            }
//            out.append("==========\n");
//            for (udinode di: ndis)
//                out.append(libufsd.print_udino(di));
//            for (udinode di: cdis)
//                out.append(libufsd.print_udino(di));
        }
    }
    function pp(uint8 t, TvmCell c) external pure returns (string out) {
        if (t == 0)
            out.append("Invalid content type");
        else if (t == 1)
            out = libufsd.print_strings(c.toSlice());
        else if (t == 3) {
            out = libufsd.print_dir(abi.decode(c, uodir));
        } else if (t == 11)
            out = libufs.print_disk(abi.decode(c, uufsd));
        else if (t == 12)
            out = (libpart.print_disk(abi.decode(c, s_disk)));
        else if (t == 13)
            out = libpart.print_label(abi.decode(c, disklabel));
        else if (t == 14)
            out.append(libpart.print_part_table(abi.decode(c, part_table)));
        else if (t == 15)
            out.append(libsb.print_sb(abi.decode(c, fsb)));
        else if (t == 16) {
            ufsd d = abi.decode(c, ufsd);
            out.append(libufsd.print_disk_header(d));
            out.append(libufsd.print_ug(d.cg));
            out.append(libufsd.print_sb(d.fs));
        } else if (t == 17) {
            ug g = abi.decode(c, ug);
            out.append(libufsd.print_ug(g));
        } else if (t == 18) {
            ufsb sb = abi.decode(c, ufsb);
            out.append(libufsd.print_sb(sb));
        } else if (t == 19) {
            udinode di = abi.decode(c, udinode);
            out.append(libufsd.print_udino(di));
        } else if (t == 20) {
//            udirent[] des = abi.decode(c, udirent[]);
//            for (udirent de: des)
//                out.append(libufsd.print_de(de));
        } else if (t == 21) {
            udinode[] dis = abi.decode(c, udinode[]);
            for (udinode di: dis)
                out.append(libufsd.print_udino(di));
        }
    }
    function pm(uint8 t, mapping (uint32 => TvmCell) mm) external pure returns (string out) {
        if (t == 0)
            out.append("Invalid content type\n");
        for ((uint32 a, TvmCell c): mm) {
            out.append(format("[{}] ", a));
            if (t == 2) {
                if (libufsd._sizeof(c) == 20) {
                    udinode di = abi.decode(c, udinode);
                    out.append(_pi(t, c, mm[di.db1], mm[di.db2]));
                }
            }
        }
    }

    function pi(uint8 t, TvmCell dic, TvmCell dc1, TvmCell dc2) external pure returns (string out) {
        return _pi(t, dic, dc1, dc2);
    }
    function _pi(uint8 t, TvmCell dic, TvmCell dc1, TvmCell dc2) internal pure returns (string out) {
        if (t == 0)
            out.append("Invalid content type\n");
        else if (t == 2) {
            if (libufsd._sizeof(dic) == 20) {
//                udinode di = abi.decode(dic, udinode);
                uodir uod = uodir(dic, dc1, dc2);
                out.append(libufsd.print_dir(uod));
//                out.append(libufsd.print_udino(di));
//                if (libfs.S_ISDIR(di.mode)) {
//                    udirent[] des = abi.decode(dc1, udirent[]);
//                    TvmSlice stas = dc2.toSlice();
//                    for (udirent de: des)
//                        out.append(libufsd.print_de(de, stas) + "\n");
//                }
            }
        }
    }
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out) {
        (bool fa, bool fb, bool fc, bool fd) = libflags.flags_set(flags, "abcd");
        uufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m = _ram;//libvmem.mmap(_ram, 0, 4);
        mapping (uint32 => TvmCell) m0 = _ram;//libvmem.mmap(_ram, 0, 4);
        string arg = args.length > 0 ? args[0] : "";
        out.append(libvmem.dump_mem(m0));
        (s_disk d, disklabel l, part_table pt) = read_disk();
        fsb f = read_sb(pt.d_partitions[0]);
        if (arg == "ufs") out.append(libufs.print_disk(ud));
        else if (arg == "ud") out.append(libufs.print_disk_header(ud));

        if (arg == "label") out.append(libpart.print_label(l));
        else if (arg == "disk") out.append(libpart.print_disk(d));
        else if (arg == "part") out.append(libpart.print_part_table(pt));
        else if (arg == "sb") out.append(libsb.print_sb(f));
        else if (arg == "cg") {
            uint16 i;
            repeat (f.ncg) {
                cg g = abi.decode(m[f.cblkno + i], cg);
//                cg g = libufs.fetch_cg(f, m, i);
                out.append(libsb.print_cg(f, g));
                i++;
            }
        } else if (arg == "inodes") {
            vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
            out.append("USER\tTYPE   DEVICE SIZE/OFF  NODE\n");
            while (!vino.empty()) {
                TvmSlice s = vino.pop();
                if (s.bits() >= 248) {
                    dinode dd = s.decode(dinode);
//                    out.append(libfattr.print_mode(dd.di_mode));
    //                out.append(libsb.print_dino(dd));
                    out.append(libfdt.print_dino_lsof(dd));
                } else
                    out.append("Thin ino\n");
            }
        }

        out.append(libvmem.dump_bin(m));
//        uufsd ud = read_ufs_disk();
//        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, ud.d_fsb.cblkno, 20);
//        out.append(libufs.print_disk(ud));

//        vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
//        out.append("USER\tTYPE   DEVICE SIZE/OFF  NODE\n");
//        while (!vino.empty()) {
//            TvmSlice s = vino.pop();
//            if (s.bits() >= 248) {
//                dinode dd = s.decode(dinode);
//                out.append(libfattr.print_mode(dd.di_mode));
////                out.append(libsb.print_dino(dd));
//                out.append(libfdt.print_dino_lsof(dd));
//            } else
//                out.append("Thin ino\n");
//        }
//        fs_summary_info fsi;
////	    uint8[]	si_contigdirs;	// # of contig. allocated dirs
//	    csum[] si_csp;		    // cg summary info buffer
////	    uint32[] si_maxcluster;	// max cluster in each cyl group
////	    uint16 si_active;		// used by snapshots to track fs
//        fsi.si_contigdirs.push(2);
//        si_csp.push(ud.d_cg.cg_cs);
//        fsi.si_csp = si_csp;
//        out.append(libsb.print_fsi(fsi));
//        out.append(libufs.print_disk(ud));
        if (fa) {
//            out.append(libcgfs.print_cgs(m));
        }
//        m.mkdefsb();
//        out.append("\n=======\n");
//        out.append(m.print_sb());
//        m.mksub(FT_DIR, ROOT_DIR, ["bin", "dev", "etc", "home", "mnt", "usr", "var"]);
//        out.append("\n=======\n");
//        out.append(m.print_sb());
        if (fb) {
//            TvmSlice s = m[3].toSlice();
//            out.append(libvmem.dump_slice(s));
        }
        if (fb) {}
        if (fc) {
//            out.append(libvmem.dump_slices(m));
        }
        if (fd) {}

    }
    function read_sb(partition p) internal view returns (fsb) {
        uint32 a = p.p_offset;
        if (_ram.exists(a))
            return abi.decode(_ram[a], fsb);
    }

    function immap(mapping (uint32 => TvmCell) m) external accept {
        for ((uint32 a, TvmCell c): m)
            if (_ram[a] != c)
                _ram[a] = c;
    }
    function bcmp(mapping (uint32 => TvmCell) m) external view returns (string out) {
        out.append(libufsd.bcmp(_ram, m));
    }

    function store_types(gti g) external accept {
        _ram[TYPE_COUNTERS] = abi.encode(g.ntypes);
        TvmCell[] cc = g.cc;
        for (uint32 i = 0; i < cc.length; i++) {
            if (_ram[i + TYPE_DATA] != cc[i])
                _ram[i + TYPE_DATA] = cc[i];
        }
    }

    function _load_types() internal view returns (gti g) {
        g.ntypes = abi.decode(_ram[TYPE_COUNTERS], uint8[]);
        TvmCell[] cc;
        uint32 i = TYPE_DATA;
        while (_ram.exists(i)) {
            cc.push(_ram[i]);
            i++;
        }
        g.cc = cc;
    }
    uint32 constant TYPE_COUNTERS = 0xDEADF000;
    uint32 constant TYPE_DATA = 0xDEADF00D;
}


//uint32 t1 =  uint32(libufsd._tag_name(0, 0,  0, 1));
//uint32 t2 =  uint32(libufsd._tag_name(1, 1,  1, 7));
//uint32 t3 =  uint32(libufsd._tag_name(2, 1,  8, 4));
//uint32 t4 =  uint32(libufsd._tag_name(3, 1, 12, 4));
//uint32 t5 =  uint32(libufsd._tag_name(4, 1, 16, 5));
//uint32 t6 =  uint32(libufsd._tag_name(5, 1, 21, 6));
//uint32 t7 =  uint32(libufsd._tag_name(6, 1, 27, 6));
//uint32 t8 =  uint32(libufsd._tag_name(7, 1, 33, 2));
//uint32 t9 =  uint32(libufsd._tag_name(8, 1, 35, 7));
//out.append(format("{}\n {}\n {}\n {}\n {}\n {}\n {}\n {}\n {}\n",  t1, t2, t3, t4, t5, t6, t7, t8, t9));

//struct sti {
//    uint8 id;
//    uint8 pid;
//    uint8 rsz;
//    uint16 bsz;
//    uint16 attr;
//    string tname;
//    string tdesc;
//}
//    function print_sti(sti st) internal returns (string out) {
//        (uint8 id, uint8 pid, uint8 rsz, uint16 bsz, uint16 attr, string tname, string tdesc) = st.unpack();
//        string sa = (attr & 1) > 0 ? "INT" : "";
//        if ((attr & 2) > 0) {
//            uint tv = attr >> 1 & 3;
//            if (tv == 1)
//                sa.append(TI[6].tname);
//            if (tv == 2)
//                sa.append(TI[7].tname);
//            if (tv == 3)
//                sa.append(TI[8].tname);
//        }
//        string pname = pid > 0 ? TI[pid].tname : "none";
//        out.append(format("{}) {}\t({})\t{}/{}\t{} {}\t{}\n",
//            id, tname, pname, rsz, bsz, attr, sa, tdesc));
//    }
//   sti[] constant TI = [
//// id pd rsz bsz attr tname     tdesc
//sti(0, 0, 0,   0, 0, "?????" ,  "Error"),
//sti(1, 0, 4, 127, 0, "TvmCell", "Cell containing arbitrary data"),
//sti(2, 0, 0,  32, 1, "uint",    "Unsigned integer"),
//sti(3, 0, 0,   1, 0, "bool",    "Boolean"),
//sti(4, 0, 0,   1, 0, "bytes",   "Bytes array"),
//sti(5, 0, 1,   0, 0, "string",  "Dynamic sized string"),
//sti(6, 0, 0,   0, 2, "struct",  "Structure"),
//sti(7, 0, 1,   0, 4, "[]",      "Dynamic sized array"),
//sti(8, 0, 1,   0, 6, "mapping", "Mapping")
//    ];