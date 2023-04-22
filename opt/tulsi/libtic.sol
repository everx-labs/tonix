pragma ton-solidity >= 0.67.0;

import "libti.sol";
struct strti {
    uint8 id;
    uint8 nv;
    uint8 nr;
    uint8 nb;
    uint8 attr;
    uint8 ldecl;
    uint8 ldesc;
    string name;
    vard[] vd;
}

struct mod_info {
    uint8 maj;
    uint8 min;
    uint8 nt;
    uint8 start;
    uint8 len;
    uint8 base_start;
    uint8 base_len;
    uint8 fixed_start;
    uint8 fixed_len;
    uint8 fla_start;
    uint8 fla_len;
    uint8 da_start;
    uint8 da_len;
    uint8 enum_start;
    uint8 enum_len;
    uint8 struct_start;
    uint8 struct_len;
    string name;
}

struct gtic {
    mod_info mi;
    strti[] tc;
    mapping (uint => uint8) tnc;
}

using libtic for gtic global;

library libtic {

    uint8 constant NONE   = 0;
    uint8 constant BOOL   = 1;
    uint8 constant INT    = 2;
    uint8 constant UINT   = 3;
    uint8 constant BYTES  = 4;
    uint8 constant STRING = 5;
    uint8 constant CELL   = 6;
    uint8 constant STRUCT = 7;
    uint8 constant ARRAY  = 8;
    uint8 constant MAP    = 9;
    uint8 constant ENUM   = 10;

    vard[] constant VVD = [
vard(0, 0, 0, 0, "N/A", "??")
    ];
   strti[] constant BT = [
////     id  nv  nr  nb   attr  ldc ldd name
strti(  NONE, 0, 0,   0, NONE, 0, 0, "?",      VVD),
strti(  BOOL, 0, 0,   1, NONE, 4, 0, "bool",   VVD),
strti(   INT, 0, 0,   1, NONE, 3, 0, "int",    VVD),
strti(  UINT, 0, 0,   1, NONE, 4, 0, "uint",   VVD),
strti( BYTES, 0, 0,   8, NONE, 5, 0, "bytes",  VVD),
strti(STRING, 0, 1,   0, NONE, 6, 0, "string", VVD),
strti(  CELL, 0, 4, 127, NONE, 4, 0, "TvmCell",    VVD),
strti(STRUCT, 0, 0,   0, NONE, 6, 0, "struct", VVD),
strti( ARRAY, 0, 1,   0, NONE, 2, 0, "array",  VVD),
strti(   MAP, 0, 1,   0, NONE, 7, 0, "map",    VVD),
strti(  ENUM, 0, 0,   1, NONE, 4, 0, "enum",   VVD)
    ];


    function join(string[] ss, string delim) internal returns (string res) {
        res = ss.empty() ? "" : ss[0];
        for (uint i = 1; i < ss.length; i++)
            res.append(delim + ss[i]);
    }

    function indent(string[] ss) internal returns (string[] res) {
        for (string s: ss)
            res.push("    " + s);
    }
    function enjoin(string header, string prefix, string[] body, string suffix, string tail) internal returns (string res) {
        res.append(header + "\n");
        for (string s: body)
            res.append(prefix + s + suffix + "\n");
        res.append(tail + "\n");
    }

    function fix_arr_name(bytes sname) internal returns (string res) {
        res = sname[ : sname.length - 2];
        res.append("s");
    }
    function gen_module(gtic g) internal returns (string out, string dbg) {
        (mod_info mi, strti[] ti, ) = g.unpack();
        (uint8 maj, uint8 min, , , , , , , , , , uint8 da_start, uint8 da_len, , , uint8 struct_start, uint8 struct_len, string name) = mi.unpack();

        string defs;
        string libname = "lib" + name;

        string[] fns;
        for (uint i = da_start; i < da_start + da_len; i++) {
            (uint8 id, , , , , , , string sname, vard[] vd) = ti[i].unpack();
            string pra = "function print_" + fix_arr_name(sname) + "(" + sname + " val) internal returns (string out) {";
            string loop_head;
            string loop_body;
            if (!vd.empty()) {
                (uint8 vtype, uint8 vcnt, uint8 dlen, uint8 slen, string vname, ) = vd[0].unpack();
                strti vt = ti[vtype];
                uint8 tattr = vt.attr & 0x0F;
                loop_head = "for (uint i = 0; i < val.length; i++)";
                loop_body = "    out.append(" + (tattr == STRUCT ? "print_" + ti[vt.id].name + "(val[i]))" : "format(\"{} \", val[i]))") + ";";
            }
            fns.push(enjoin(pra, "    ", indent([loop_head, loop_body]), "", ""));
        }
        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            (, , , , , , , string sname, ) = ti[i].unpack();
            (, string type_def1, string print_fn1, string val_unpack, string print_terse) = gen_all(g, ti[i]);
            defs.append(type_def1);
            string fn_head = "function print_" + sname + "(" + sname + " val) internal returns (string out) {";
            fns.push(enjoin(fn_head, "    ", indent([val_unpack, print_terse]), "", ""));
        }

        string[] fsto;
        string[] ftp_body = ["if (t == 0) out.append(\"Invalid content type\\n\");"];
        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            (uint8 id, , , , , , , string sname, ) = ti[i].unpack();
            fsto.push(enjoin("function store_" + sname + "(" + sname + " val) external pure returns (TvmCell c) {", "        ", ["return abi.encode(val);"], "", "    }"));
            ftp_body.push("else if (t == " + format("{}", id) + ") out.append(" + libname + ".print_" + sname + "(abi.decode(c, " + sname + ")));");
        }
        fsto.push(enjoin("function print(uint8 t, TvmCell c) external pure returns (string out) {", "        ", ftp_body, "", "    }"));

        string prag = "pragma ton-solidity >= 0." + format("{}.{}", maj, min) + ";";
        string lib = enjoin("library " + libname + " {\n", "    ", fns, "    }\n", "}\n");
        string ctx = enjoin("contract " + name + " {", "    ", fsto, "", "}");
        string mod = join([prag, defs, lib, ctx], "\n");

        dbg.append(mod);
        out.append(mod);
    }

    function gen_all(gtic g, strti ti) internal returns (string type_info, string type_def, string print_fn, string val_unpack, string print_terse) {
        (uint8 id, uint8 nv, uint8 nr, uint8 nb, uint8 tattr, uint8 ldecl, uint8 ldesc, string sname, vard[] vd) = ti.unpack();
        tattr = tattr & 0x0F;
        bool tis_struct = tattr & 0xF == STRUCT;
        bool tis_enum = tattr & 0xF == ENUM;
        type_info = format("{:2}) {:2} {} {:3} {:2} {:2} {:3} {}\n", id, nv, nr, nb, tattr, ldecl, ldesc, sname);
        string[] vds;
        string[] vns;
        string[] vts;
        if (tis_struct) {
            for (uint i = 0; i < nv; i++) {
                (uint8 vtype, , , , string vname, ) = vd[i].unpack();
                strti vt = g.tc[vtype];
                uint8 attr = vt.attr & 0xF;

                string pname =
                    attr == BYTES ? "string(bytes(" + vname + "))" :
                    attr == ENUM || attr == STRUCT ?  "print_" + g.tc[vt.id].name + "(" + vname + ")" :
                    attr == ARRAY ? "print_" + fix_arr_name(g.tc[vt.id].name) +  "(" + vname + ")" :
                    attr == BOOL ?  vname + " ? \"Yes\" : \"No\"" :
                                    vname;

                vns.push(pname);
                vts.push(vname + ": {}");
                vds.push(vt.name + " " + vname);
            }
        }

        if (tis_enum) {
            type_def.append("enum " + sname + " { ");
            for (uint i = 0; i < nv; i++)
                type_def.append(vd[i].vname + (i + 1 < nv ? ", " : " "));
        } else if (tis_struct) {
            type_def.append("struct " + sname + " {\n");
            for (uint i = 0; i < nv; i++) {
                type_def.append("    " + vds[i] + ";");
                if (!vd[i].vdesc.empty()) {
                    repeat(ldecl + 1 - vd[i].dlen)
                        type_def.append(" ");
                    type_def.append("// " + vd[i].vdesc);
                }
                type_def.append("\n");
            }
            type_def.append("}\n\n");
        }
        print_fn.append("function print_" + sname + "(" + sname + " val) internal returns (string out) {");
        val_unpack = "(" + join(vds, ", ") + ") = val.unpack();";
        string print_format = "out.append(format(\"";
        string var_list = join(vns, ", ");
        print_terse = print_format + join(vts, " ") + "\\n\",\n" + "            " + var_list + "));";
    }

    function add_fixed_length_type(gtic g, uint8 t, uint8 size) internal {
        vard[] vv;
        strti ti = strti(g.mi.nt, 1, 0, size, t, 0, 0, format("{}{}", BT[t].name, size * 8 / BT[t].nb), vv);
        g.add_type(ti);
        //g.add_type(t, format("{}{}", BT[t].name, size * 8 / BT[t].nb), vv);
    }

    function fill_type(gtic g, uint8 t, uint8 id, string tname, vard[] vd) internal {
        uint8 nv;
        uint8 nr;
        uint8 nb;
        uint8 ldecl;
        uint8 ldesc;
        for (vard v: vd) {
            (uint8 vtype, , uint8 dlen, uint8 slen, , ) = v.unpack();
            strti vt = g.tc[vtype];
            nr += vt.nr;
            nb += vt.nb;
            if (dlen > ldecl)
                ldecl = dlen;
            if (slen > ldesc)
                ldesc = slen;
            nv++;
        }
        strti ti = strti(id, nv, nr, nb, t, ldecl, ldesc, tname, vd);
        g.tc[id] = ti;
    }

    function add_type(gtic g, uint8 t, string tname, vard[] vd) internal {
        uint8 id = g.mi.nt;
        uint8 nv;
        uint8 nr;
        uint8 nb;
        uint8 ldecl;
        uint8 ldesc;
        for (vard v: vd) {
            (uint8 vtype, , uint8 dlen, uint8 slen, , ) = v.unpack();
            strti vt = g.tc[vtype];
            nr += vt.nr;
            nb += vt.nb;
            if (dlen > ldecl)
                ldecl = dlen;
            if (slen > ldesc)
                ldesc = slen;
            nv++;
        }
        strti ti = strti(id, nv, nr, nb, t, ldecl, ldesc, tname, vd);
        g.tc.push(ti);
        g.mi.nt++;
        g.tnc[tvm.hash(tname)] = id;
    }
    function add_type(gtic g, strti s) internal {
        g.tc.push(s);
        g.mi.nt++;
        g.tnc[tvm.hash(s.name)] = s.id;
    }

    function print_types(gtic g) internal returns (string out) {
        (mod_info mi, strti[] ti, mapping (uint => uint8) tnc) = g.unpack();
        (uint8 maj, uint8 min, uint8 nt, uint8 start, uint8 len, uint8 base_start, uint8 base_len, uint8 fixed_start, uint8 fixed_len,
            uint8 fla_start, uint8 fla_len, uint8 da_start, uint8 da_len, uint8 enum_start, uint8 enum_len, uint8 struct_start, uint8 struct_len, string name) = mi.unpack();
        out.append(format(" maj: {} min: {} nt: {} start: {} len: {} base_start: {} base_len: {} fixed_start: {} fixed_len: {} fla_start: {} fla_len: {} da_start: {} da_len: {} enum_start: {} enum_len: {} struct_start: {} struct_len: {} name: {}\n",
            maj, min, nt, start, len, base_start, base_len, fixed_start, fixed_len, fla_start, fla_len, da_start, da_len, enum_start, enum_len, struct_start, struct_len, name));

        for ((, uint8 n): tnc)
            out.append(format("{}) ", n) + (n < ti.length ? ti[n].name : "???") + "\n");

        out.append(format("id  nv nr nb att dcl dsc   name\n"));
        for (uint i = 1; i < nt; i++) {
            if (i >= ti.length)
                continue;
            (uint8 id, uint8 nv, uint8 nr, uint8 nb, uint8 attr, uint8 ldecl, uint8 ldesc, string sname, ) = ti[i].unpack();
            out.append(format("{:2}) {:2} {} {:3} {:2} {:2} {:3} {}\n",
                id, nv, nr, nb, attr, ldecl, ldesc, sname));
        }
    }

//    function gen_headers(gtic g) internal returns (string out) {
//        out.append("pragma ton-solidity >= 0.67.0;\n\n");
//        for (strti t: g.tc) {
//            (uint8 id, uint8 nv, , , uint8 tattr, uint8 ldecl, , string name, vard[] vd) = t.unpack();
//            if (id == 0)
//                continue;
//            tattr = tattr & 0x0F;
//            bool tis_struct = tattr & 0xF == STRUCT;
//            bool tis_enum = tattr & 0xF == ENUM;
//            if (tis_enum) {
//                out.append("enum " + name + " { ");
//                for (uint i = 0; i < nv; i++)
//                    out.append(vd[i].vname + (i + 1 < nv ? ", " : " "));
//            } else if (!tis_struct)
//                continue;
////            else
////                out.append("unknown type: " + name + " {\n");
//            out.append("struct " + name + " {\n");
//            for (uint i = 0; i < nv; i++) {
//                if (i >= vd.length) {
//                    out.append(format("Error: index {} out of range {}, max: {}\n", i, vd.length, nv));
//                    break;
//                }
//                (uint8 vtype, , uint8 dl, , string vname, string vdesc) = vd[i].unpack();
//  //              if (tis_struct) {
//                    //out.append("    " + g.gt.ss[vtype] + (vcnt != 1 ? (vcnt > 1 ? format("[{}]", vcnt) : "[]") : "") + " " + vname + ";");
//                out.append("    " + g.tc[vtype].name + " " + vname + ";");
//                if (!vdesc.empty()) {
//                    repeat(ldecl + 1 - dl)
//                        out.append(" ");
//                    out.append("// " + vdesc);
//                }
//                out.append("\n");
//            }
//            out.append("}\n\n");
//        }
//    }
//
//    function gen_lib_code(gtic g) internal returns (string out) {
//        string libname = "lib" + g.mi.name;
//        out.append("library " + libname + " {\n\n");
//        for (strti t: g.tc) {
//            (uint8 id, uint8 nv, , , uint8 tattr, , uint8 ldesc, string sname, vard[] vd) = t.unpack();
//            if (id == 0 || nv == 0)
//                continue;
//            bool tis_struct = tattr & 0xF == STRUCT;
//            bool tis_enum = tattr & 0xF == ENUM;
//            if (!tis_enum && !tis_struct)
//                continue;
//
//            out.append("    function print_" + sname + "(" + sname + " val) internal returns (string out) {\n");
//            string s1 = "(";
//            string s2 = "out.append(format(\"";
//            string s3;
//            string s4;
//            string s5;
//            string s6 = ldesc > 0 ? "out.append(format(\"" : "";
//            for (uint i = 0; i < nv; i++) {
//                if (i >= vd.length) {
//                    out.append(format("Error: index {} out of range {}, max: {}\n", i, vd.length, nv));
//                    break;
//                }
//                (uint8 vtype, uint8 vcnt, , uint8 clen, string vname, string vdesc) = vd[i].unpack();
//
//                if (tis_enum)
//                    out.append("        if (val == " + sname + "." + vname + ") out.append(\"" + vname + "\");\n");
//                else if (tis_struct) {
//                    strti vt = g.tc[vtype];
//                    bool vis_struct = vt.attr & 0xF == STRUCT;
//                    bool vis_enum = vt.attr & 0xF == ENUM;
//                    s1.append(g.tc[vt.id].name + (vcnt != 1 ? (vcnt > 1 ? format("[{}]", vcnt) : "[]") : "") + " " + vname);
//                    s5.append(format("        // id {} nr {} attr {}\n", vt.id, vt.nr, vt.attr));
//                    if (vis_struct) {
//                        if (vcnt != 1) {
//                            s4.append("        for (uint i = 0; i < " + (vcnt > 0 ? format("{}", vcnt) : vname + ".length") + "; i++)\n");
//                            s4.append("            out.append(print_" + g.tc[vt.id].name + "(" + vname + "[i]));\n");
//                        } else
//                            s4.append("        out.append(print_" + g.tc[vt.id].name + "(" + vname + "));\n");
//                    } else {
//                        s2.append(" " + vname + ": {}");
//                        if (ldesc > 0) {
//                            s6.append((clen > 0 ? vdesc : vname) + ":");
//                            repeat(ldesc + 1 - clen)
//                                s6.append(" ");
//                            s6.append("{}\\n");
//                        }
//                        if (!s3.empty())
//                            s3.append(", ");
//                        s3.append((vt.attr & 0x0F) == BYTES ? "string(bytes(" + vname + "))" :
//                                  vis_enum ? "print_" + g.tc[vt.id].name + "(" + vname + ")" :
//                                  (vt.attr & 0x0F) == BOOL ? vname + " ? \"Yes\" : \"No\"" :
//                                    vname);
//                    }
//                    s1.append(i + 1 < nv ? ", " : ") = val.unpack();");
//                }
//            }
//
//            s2.append("\\n\",");
//            s3.append("));\n");
//
////            out.append(s5 + "\n");
//
//            if (tis_struct) {
//                out.append("        " + s1 + "\n");
//                out.append("        " + s2 + "\n");
//                s3 = "            " + s3 + "\n";
//                out.append(s3);
//                if (!s4.empty())
//                    out.append(s4 + "\n");
//                if (!s6.empty())
//                    out.append("        " + s6 + "\",\n" + s3);
//            }
//            out.append("    }\n");
//        }
//        out.append("}\n");
//    }
//
//    function gen_handlers(gtic g) internal returns (string out) {
//        string libname = "lib" + g.mi.name;
//        out.append("contract " + g.mi.name + " {\n\n");
//        for (strti t: g.tc) {
//            if (t.id > 0 && t.nv > 0 && (t.attr == STRUCT || t.attr == ENUM)) {
//                out.append("    function store_" + t.name + "(" + t.name + " val) external pure returns (TvmCell c) {\n");
//                out.append("        return abi.encode(val);\n    }\n\n");
//            }
//        }
//        out.append("    function print(uint8 t, TvmCell c) external pure returns (string out) {\n");
//        out.append("        if (t == 0) out.append(\"Invalid content type\\n\");\n");
//        for (strti t: g.tc) {
//            if (t.id > 0 && t.nv > 0 && (t.attr == STRUCT || t.attr == ENUM))
//                out.append("        else if (t == " + format("{}", t.id) + ") out.append(" + libname + ".print_" + t.name + "(abi.decode(c, " + t.name + ")));\n");
//        }
//        out.append("    }\n}\n");
//    }
//
//    function gen_print(gtic g) internal returns (string out) {
//        out.append(gen_headers(g));
//        out.append(gen_lib_code(g));
//        out.append(gen_handlers(g));
//    }

}
