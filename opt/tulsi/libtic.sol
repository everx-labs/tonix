pragma ton-solidity >= 0.67.0;

import "libti.sol";
struct strti {
    uint8 id;
    uint8 tid;
    uint8 nv;
    uint8 nr;
    uint8 nb;
    uint8 attr;
    uint8 ldecl;
    uint8 ldesc;
    string name;
    vard[] vd;
}

struct gtic {
    uint8 nt;
    string name;
    strti[] tc;
    gti gt;
}

using libtic for gtic global;

library libtic {

    function print_types(gtic g) internal returns (string out) {
        (uint8 nt, string mname, strti[] ti, ) = g.unpack();
        out.append(format("Module {}, types: {}\n", mname, nt));
        for (uint i = 1; i < nt; i++) {
            (uint8 id, uint8 tid, uint8 nv, uint8 nr, uint8 nb, uint8 attr, , , string sname, ) = ti[i].unpack();
            out.append(format("id {} tid {} nv {} nr {} nb {} attr {} name {}\n",
                id, tid, nv, nr, nb, attr, sname));
       }
//        for (strti t: g.tc) {
//            (uint8 id, uint8 pid, vari[] vv, string[] ssi) = t.unpack();
//            out.append(format("id {} pid {} {} vars {} names\n", id, pid, vv.length, ssi.length));
//            out.append(string(ss[pid]) + " " + string(ss[id]) + " {\n");
//            for (uint i = 0; i < vv.length; i++)
//                out.append("    " + string(ss[vv[i].pid]) + " " + ssi[i] + ";\n");
//            out.append("}\n");
//        }
    }

    function gen_headers(gtic g) internal returns (string out) {
        out.append("pragma ton-solidity >= 0.67.0;\n\n");
        for (strti t: g.tc) {
            (uint8 id, , uint8 nv, , , uint8 attr, uint8 ldecl, , string name, vard[] vd) = t.unpack();
            if (id == 0)
                continue;
            attr = attr & 0x0F;
            if (attr == libti.STRUCT)
                out.append("struct " + name + " {\n");
            else if (attr == libti.ENUM)
                out.append("enum " + name + " { ");
            else
                out.append("unknown type: " + name + " {\n");
            for (uint i = 0; i < nv; i++) {
                (uint8 vtype, uint8 vcnt, uint8 dl, , string vname, string vdesc) = vd[i].unpack();
                if (attr == libti.STRUCT) {
                    out.append("    " + g.gt.ss[vtype] + (vcnt > 1 ? format("[{}]", vcnt) : "") + " " + vname + ";");
                    if (!vdesc.empty()) {
                        repeat(ldecl + 1 - dl)
                            out.append(" ");
                        out.append("// " + vdesc);
                    }
                    out.append("\n");
                } else if (attr == libti.ENUM)
                    out.append(vname + (i + 1 < nv ? ", " : " "));
            }
            out.append("}\n\n");
        }
    }

    function gen_lib_code(gtic g) internal returns (string out) {
        string libname = "lib" + g.name;
        out.append("library " + libname + " {\n\n");
        for (strti t: g.tc) {
            (uint8 id, , uint8 nv, , , uint8 tattr, , uint8 ldesc, string sname, vard[] vd) = t.unpack();
            if (id == 0)
                continue;
            bool tis_struct = tattr & 0xF == libti.STRUCT;
            bool tis_enum = tattr & 0xF == libti.ENUM;

            out.append("    function print_" + sname + "(" + sname + " val) internal returns (string out) {\n");
            string s1 = "(";
            string s2 = "out.append(format(\"";
            string s3;
            string s4;
            string s5;
            string s6 = ldesc > 0 ? "out.append(format(\"" : "";
            for (uint i = 0; i < nv; i++) {
                (uint8 vtype, uint8 vcnt, , uint8 clen, string vname, string vdesc) = vd[i].unpack();

                if (tis_enum) {
                    out.append("        if (val == " + sname + "." + vname + ") out.append(\"" + vname + "\");\n");
                } else if (tis_struct) {
                    stt vt = g.gt.tt[vtype];
                    bool vis_struct = vt.attr & 0xF == libti.STRUCT;
                    bool vis_enum = vt.attr & 0xF == libti.ENUM;
                    s1.append(g.gt.ss[vt.id] + (vcnt > 1 ? format("[{}]", vcnt) : "") + " " + vname);
                    s5.append(format("        // id {} pid {} nr {} attr {}\n", vt.id, vt.pid, vt.nr, vt.attr));
//                    (uint8 id, uint8 pid, uint8 rsz, uint8 bsz, , , , uint8 attr) = tt[i].unpack();

//                    if ((vt.attr & 0xF) == libti.STRUCT)
                    if (vis_struct) {
                        if (vcnt > 1) {
                            s4.append("        for (uint i = 0; i < " + format("{}", vcnt) + "; i++)\n");
                            s4.append("            out.append(print_" + g.gt.ss[vt.id] + "(" + vname + "[i]));\n");
                        } else
                            s4.append("        out.append(print_" + g.gt.ss[vt.id] + "(" + vname + "));\n");
                    } else {
                        s2.append(" " + vname + ": {}");
                        if (ldesc > 0) {
                            s6.append((clen > 0 ? vdesc : vname) + ":");
                            repeat(ldesc + 1 - clen)
                                s6.append(" ");
                            s6.append("{}\\n");
                        }
                        if (i > 0)
                            s3.append(", ");
                        s3.append((vt.attr & 0x0F) == libti.BYTES ? "string(bytes(" + vname + "))" :
                                  vis_enum ? "print_" + g.gt.ss[vt.id] + "(" + vname + ")" :
                                  (vt.attr & 0x0F) == libti.BOOL ? vname + " ? \"Yes\" : \"No\"" :
                                    vname);
//                        if (i + 1 < nv) {
//                            s2.append(" ");
//                            s3.append(", ");
////                        } else {
////                            s2.append("\\n\",");
////                            s3.append("));\n");
//                        }
                    }
                    s1.append(i + 1 < nv ? ", " : ") = val.unpack();");
                }
            }

            s2.append("\\n\",");
            s3.append("));\n");

            out.append(s5 + "\n");

            if (tis_struct) {
                out.append("        " + s1 + "\n");
                out.append("        " + s2 + "\n");
                s3 = "            " + s3 + "\n";
                out.append(s3);
                if (!s4.empty())
                    out.append(s4 + "\n");
                if (!s6.empty())
                    out.append("        " + s6 + "\",\n" + s3);
            }
            out.append("    }\n");
        }
        out.append("}\n");
    }

    function gen_handlers(gtic g) internal returns (string out) {
        string libname = "lib" + g.name;
        out.append("contract " + g.name + " {\n\n");
        for (strti t: g.tc) {
            if (t.id > 0) {
                out.append("    function store_" + t.name + "(" + t.name + " val) external pure returns (TvmCell c) {\n");
                out.append("        return abi.encode(val);\n    }\n\n");
            }
        }
        out.append("    function print(uint8 t, TvmCell c) external pure returns (string out) {\n");
        out.append("        if (t == 0) out.append(\"Invalid content type\\n\");\n");
        for (strti t: g.tc) {
            //(uint8 id, , vari[] vv, string[] ssi) = t.unpack();
            if (t.id > 0)
                out.append("        else if (t == " + format("{}", t.id) + ") out.append(" + libname + ".print_" + t.name + "(abi.decode(c, " + t.name + ")));\n");
        }
        out.append("    }\n}\n");
    }

    function gen_print(gtic g) internal returns (string out) {
        out.append(gen_headers(g));
        out.append(gen_lib_code(g));
        out.append(gen_handlers(g));
    }

    function derive_struct_type(gtic g, vard[] vv) internal {
        uint vl = vv.length;
        uint nr;
        uint nb;
        for (uint i = 1; i < vl; i++) {
//            (uint8 vtype, string vname, string vdesc) = vv[i].unpack();
            stt vt = g.gt.tt[vv[i].vtype];
            nr += vt.rsz;
            nb += vt.bsz;
        }
        g.tc.push(strti(g.nt, g.gt.nt, uint8(vl), uint8(nr), uint8(nb), 0, 0, 0, vv[0].vname, vv));
        g.nt++;
    }

//    function derive_agg_type(stt[] ttt, string[] tname, uint8[] ee) internal returns (stt tt, strti ti) {
//        tt = ttt[ee[0]];
//        tt.pid = tt.id;
//        tt.id = uint8(ttt.length);
//        tt.nl = uint8(tname[0].byteLength());
//        uint off;
//        vari[] vv;
//        bytes[] ss;
//        for (uint j = 1; j < ee.length; j++) {
//            stt vt = ttt[ee[j]];
//            tt.bsz += vt.bsz;
//            tt.rsz += vt.rsz;
//            bytes bn = bytes(tname[j]);
//            uint len = bn.length;
//            off += len;
//            vv.push(vari(uint8(j), ee[j], uint8(len), 1, uint8(off), ttt[ee[j]].attr));
//            ss.push(bn);
//        }
//        ti = sti(tt.id, tt.pid, vv, ss);
//    }
//    function map_names(gtic g) internal {
//        for (uint i = 0; i < g.nt; i++)
//            g.tnc[tvm.hash(g.gt.ss[i])] = uint8(i);
//    }
}
