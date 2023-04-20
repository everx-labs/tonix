pragma ton-solidity >= 0.67.0;

import "ti.h";

struct sti {
    uint8 id;
    uint8 pid;
    vari[] vv;
    string[] ss;
}

struct gti {
    uint8 no;
    uint8 nt;
    stt[] tt;
    string[] ss;
    sti[] tti;
    mapping (uint => uint8) tnc;
}

using libti for gti global;

library libti {

    uint8 constant NONE   = 0;
    uint8 constant CELL   = 1;
    uint8 constant UINT   = 2;
    uint8 constant BOOL   = 3;
    uint8 constant BYTES  = 4;
    uint8 constant STRING = 5;
    uint8 constant STRUCT = 6;
    uint8 constant ARRAY  = 7;
    uint8 constant MAP    = 8;
    uint8 constant ENUM   = 9;

   stt[] constant TI = [
//     id pid rsz bsz nl nr noff attr
stt(  NONE, 0, 0,   0, 0, 0,   0, NONE),
stt(  CELL, 0, 4, 127, 7, 1,   0, CELL),
stt(  UINT, 0, 0,   1, 4, 1,   7, UINT),
stt(  BOOL, 0, 0,   1, 4, 1,  11, BOOL),
stt( BYTES, 0, 0,   8, 5, 1,  15, BYTES),
stt(STRING, 0, 1,   0, 6, 1,  20, STRING),
stt(STRUCT, 0, 0,   0, 6, 1,  26, STRUCT),
stt( ARRAY, 0, 1,   0, 2, 1,  32, ARRAY),
stt(   MAP, 0, 1,   0, 7, 1,  34, MAP),
stt(  ENUM, 0, 0,   1, 4, 1,  41, ENUM)
    ];
    string[] constant TN = ["", "TvmCell", "uint", "bool", "bytes", "string", "struct", "[]", "mapping", "enum"];

    function with_base() internal returns (gti g) {
        g.no = 1;
        g.nt = uint8(TI.length);
        g.tt = TI;
        g.ss = TN;
        for (uint i = 0; i < g.nt; i++)
            g.tnc[tvm.hash(g.ss[i])] = uint8(i);
    }

    function derive_fixed_length_type(gti g, uint8 t, uint8[] ex) internal {
        for (uint8 i: ex) {
            string tn0 = format("{}{}", TN[t], i * 8 / TI[t].bsz);
            stt tt = stt(g.nt, t, 0, i, uint8(tn0.byteLength()), 1, 0, TI[t].id);
            g.tt.push(tt);
            g.ss.push(tn0);
            g.tnc[tvm.hash(tn0)] = tt.id;
            g.nt++;
        }
    }

    function print_types(gti g) internal returns (string out) {
        (uint8 no, uint8 nt, stt[] tt, bytes[] ss, sti[] ti, ) = g.unpack();
        out.append(format("Group #{}, {} total types, {} names, {} custom types\n", no, nt, ss.length, ti.length));
        for (uint i = 0; i < nt; i++) {
            (uint8 id, uint8 pid, uint8 rsz, uint8 bsz, , , , uint8 attr) = tt[i].unpack();
            uint8 nl = tt[i].nl;
            string tns = ss[i];
            if (nl < 4)
                tns.append("\t");
            string sat = (attr & 0xF) > 0 ? TN[attr] : "";
            out.append(format("{:2}) {}\t ({})\t{}/{}\t{} {}\t\n",
                id, tns, pid, rsz, bsz, attr, sat));
        }
        for (sti t: ti) {
            (uint8 id, uint8 pid, vari[] vv, string[] ssi) = t.unpack();
//            out.append(format("id {} pid {} {} vars {} names\n", id, pid, vv.length, ssi.length));
            out.append(string(ss[pid]) + " " + string(ss[id]) + " {\n");
            for (uint i = 0; i < vv.length; i++)
                out.append("    " + string(ss[vv[i].pid]) + " " + ssi[i] + ";\n");
            out.append("}\n");
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

    function gen_print(gti g, string name) internal returns (string out) {
        out.append("pragma ton-solidity >= 0.67.0;\n\n");
        (, , stt[] tt, bytes[] ss, sti[] ti, ) = g.unpack();
        for (sti t: ti) {
            (uint8 id, uint8 pid, vari[] vv, string[] ssi) = t.unpack();
            out.append(string(ss[pid]) + " " + string(ss[id]) + " {\n");
            for (uint i = 0; i < vv.length; i++)
                out.append("    " + string(ss[vv[i].pid]) + " " + ssi[i] + ";\n");
            out.append("}\n\n");
        }

        string libname = "lib" + name;
        out.append("library " + libname + " {\n\n");

        tt;
        for (sti t: ti) {
            (uint8 id, , vari[] vv, string[] ssi) = t.unpack();
            out.append("    function print_" + string(ss[id]) + "(" + string(ss[id]) + " val) internal returns (string out) {\n        (");
            for (uint i = 0; i < vv.length; i++)
                out.append(((vv[i].attr & 2) == 0 ? string(ss[vv[i].pid]) + " " + ssi[i] : " ") + (i + 1 < vv.length ?  ", " : ") = val.unpack();\n"));
            out.append("        out.append(format(\"");
            for (uint i = 0; i < vv.length; i++)
                out.append(((vv[i].attr & 2) == 0 ? ssi[i] + ": {}" : "") + (i + 1 < vv.length ?  " " : "\\n\",\n            "));
            for (uint i = 0; i < vv.length; i++)
                out.append(((vv[i].attr & 2) == 0 ? ((vv[i].attr & 8) == 8 ? "string(bytes(" + ssi[i] + "))" : ssi[i]) + (i + 1 < vv.length ? ", " : "));\n    }\n\n") : ""));
        }
        out.append("}\n");
        out.append("contract " + name + " {\n\n");
        for (sti t: ti) {
            out.append("    function store_" + string(ss[t.id]) + "(" + string(ss[t.id]) + " val) external pure returns (TvmCell c) {\n");
            out.append("        return abi.encode(val);\n    }\n\n");
        }

        out.append("    function print(uint8 t, TvmCell c) external pure returns (string out) {\n");
        out.append("        if (t == 0) out.append(\"Invalid content type\\n\");\n");
        for (sti t: ti) {
            //(uint8 id, , vari[] vv, string[] ssi) = t.unpack();
            out.append("        else if (t == " + format("{}", t.id) + ") out.append(" + libname + ".print_" + string(ss[t.id]) + "(abi.decode(c, " + string(ss[t.id]) + ")));\n");
        }
        out.append("    }\n}\n");
    }

    function derive_struct_type(stt[] ttt, vard[] vv) internal returns (stt tt, sti ti) {
        string[] stn;
        uint8[] tid;
        for (vard v: vv) {
            tid.push(v.vtype);
            stn.push(v.vname);
        }
        return derive_agg_type(ttt, stn, tid);
    }

    function derive_agg_type(stt[] ttt, string[] tname, uint8[] ee) internal returns (stt tt, sti ti) {
        tt = ttt[ee[0]];
        tt.pid = tt.id;
        tt.id = uint8(ttt.length);
        tt.nl = uint8(tname[0].byteLength());
        uint off;
        vari[] vv;
        bytes[] ss;
        for (uint j = 1; j < ee.length; j++) {
            stt vt = ttt[ee[j]];
            tt.bsz += vt.bsz;
            tt.rsz += vt.rsz;
            bytes bn = bytes(tname[j]);
            uint len = bn.length;
            off += len;
            vv.push(vari(uint8(j), ee[j], uint8(len), 1, uint8(off), ttt[ee[j]].attr));
            ss.push(bn);
        }
        ti = sti(tt.id, tt.pid, vv, ss);
    }
    function map_names(gti g) internal {
        for (uint i = 0; i < g.nt; i++)
            g.tnc[tvm.hash(g.ss[i])] = uint8(i);
    }
}
