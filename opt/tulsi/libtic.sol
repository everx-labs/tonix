pragma ton-solidity >= 0.67.0;

import "libti.sol";
import "libstr.sol";

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
strti(  BOOL, 0, 0,   1, BOOL, 4, 0, "bool",   VVD),
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
        uint q1 = libstr.strchr(sname, '[');
        uint q2 = libstr.strchr(sname, ']');
        if (q1 > 0 && q2 > 0)
            res = string(sname[ : q1 - 1]) + "s";
    }
    function gen_module(gtic g) internal returns (string out, string dbg) {
        (mod_info mi, strti[] ti, ) = g.unpack();
        (uint8 maj, uint8 min, uint8 nt, , , , , , , uint8 fla_start, uint8 fla_len, , uint8 da_len, uint8 enum_start, uint8 enum_len, uint8 struct_start, uint8 struct_len, string name) = mi.unpack();

        string libname = "lib" + name;

        string[] defs;
        string[] fns;
        for (uint i = fla_start; i < fla_start + fla_len + da_len; i++) {
            (, , , , , , , string sname, vard[] vd) = ti[i].unpack();
            string pra = "function print_" + fix_arr_name(sname) + "(" + sname + " val) internal returns (string out) {";
            string loop_head;
            string loop_body;
            if (!vd.empty()) {
                (uint8 vtype, , , , , ) = vd[0].unpack();
                strti vt = ti[vtype];
                uint8 tattr = vt.attr & 0x0F;
                loop_head = "for (uint i = 0; i < val.length; i++)";
                loop_body = "    out.append(" + (tattr == STRUCT ? "print_" + ti[vt.id].name + "(val[i]))" : "format(\"{} \", val[i]))") + ";";
            }
            fns.push(enjoin(pra, "    ", indent([loop_head, loop_body]), "", "    }"));
        }

        for (uint i = enum_start; i < enum_start + enum_len; i++) {
            (, uint8 nv, , , , , , string sname, vard[] vd) = ti[i].unpack();
            string vname = vd[0].vname;
            string tyd = "enum " + sname + " { " + vname;
            string[] fnb = ["if (val == " + sname + "." + vname + ") out.append(\"" + vname + "\");"];
            for (uint j = 1; j < nv; j++) {
                vname = vd[j].vname;
                tyd.append(", " + vname);
                fnb.push("else if (val == " + sname + "." + vname + ") out.append(\"" + vname + "\");");
            }
            tyd.append(" }\n");
            defs.push(tyd);
            string fn_head = "function print_" + sname + "(" + sname + " val) internal returns (string out) {";
            fns.push(enjoin(fn_head, "    ", indent(fnb), "", "    }"));
        }

        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            if (i >= ti.length) {
                dbg.append(format("Error: index {} out of range {}, max: {}\n", i, ti.length, nt));
                break;
            }
            (, uint8 nv, , , , uint8 ldecl, , string sname, vard[] vd) = ti[i].unpack();
            string[] vds;
            string[] vns;
            string[] vts;
            string[] vas;
            string[] tyl;
            for (uint j = 0; j < nv; j++) {
                (uint8 vtype, , uint8 dlen, , string vname, string vdesc) = vd[j].unpack();
                strti vt = ti[vtype];
                string tyd = vt.name + " " + vname + ";";
                if (!vdesc.empty()) {
                    repeat(ldecl + 1 - dlen)
                        tyd.append(" ");
                    tyd.append("// " + vdesc);
                }
                tyl.push(tyd);

                uint8 attr = vt.attr & 0xF;
                string pname =
                    attr == BYTES ? "string(bytes(" + vname + "))" :
                    attr == ENUM || attr == STRUCT ?  "print_" + ti[vt.id].name + "(" + vname + ")" :
                    attr == ARRAY ? "print_" + fix_arr_name(ti[vt.id].name) +  "(" + vname + ")" :
                    attr == BOOL ?  vname + " ? \"Yes\" : \"No\"" :
                                    vname;
                if (attr == ARRAY)
                    vas.push(pname);
                else {
                    vns.push(pname);
                    vts.push(vname + ": {}");
                }
                vds.push(vt.name + " " + vname);
            }
            defs.push(enjoin("struct " + sname + " {", "", indent(tyl), "", "}"));

            string val_unpack = "    (" + join(vds, ", ") + ") = val.unpack();";
            string print_format = "    out.append(format(\"";
            string var_list = join(vns, ", ");
            string vaals = vas.empty() ? "}" : enjoin("", "        out.append(", vas, ");", "}");
            string print_terse = print_format + join(vts, " ") + "\\n\",\n" + "            " + var_list + "));";

            string fn_head = "function print_" + sname + "(" + sname + " val) internal returns (string out) {";
            fns.push(join([fn_head, val_unpack, print_terse, vaals], "\n    "));
        }

        string[] fsto;
        string[] ftp_body = ["if (t == 0) out.append(\"Invalid content type\\n\");"];
        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            if (i >= ti.length) {
                dbg.append(format("Error: index {} out of range {}, max: {}\n", i, ti.length, nt));
                break;
            }
            (uint8 id, , , , , , , string sname, ) = ti[i].unpack();
            fsto.push(enjoin("function store_" + sname + "(" + sname + " val) external pure returns (TvmCell c) {", "        ", ["return abi.encode(val);"], "", "    }"));
            ftp_body.push("else if (t == " + format("{}", id) + ") out.append(" + libname + ".print_" + sname + "(abi.decode(c, " + sname + ")));");
        }
        fsto.push(enjoin("function print(uint8 t, TvmCell c) external pure returns (string out) {", "        ", ftp_body, "", "    }"));

        string prag = "pragma ton-solidity >= 0." + format("{}.{}", maj, min) + ";";
        string tdefs = join(defs, "\n");
        string lib = enjoin("library " + libname + " {\n", "    ", fns, "\n", "}");
        string ctx = enjoin("contract " + name + " {", "    ", fsto, "", "}");
        string mod = join([prag, tdefs, lib, ctx], "\n\n");

        dbg.append(mod);
        out.append(mod);
    }

    function add_fixed_length_type(gtic g, uint8 t, uint8 size) internal {
        vard[] vv;
        strti ti = strti(g.mi.nt, 1, 0, size, t, 0, 0, format("{}{}", BT[t].name, size * 8 / BT[t].nb), vv);
        g.add_type(ti);
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
}
