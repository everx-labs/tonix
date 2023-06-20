pragma ton-solidity >= 0.67.0;

struct vard {
    uint8 vtype;
    uint8 vcnt;
    uint8 dlen;
    uint8 slen;
    string vname;
    string vdesc;
}

struct strti {
    uint8 id;
    uint8 nv;
    uint8 nr;
    uint16 nb;
    uint8 attr;
    uint8 ldecl;
    uint8 ldesc;
    string name;
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
    uint8 map_start;
    uint8 map_len;
    string name;
}

struct gtic {
    mod_info mi;
    strti[] tc;
    mapping (uint8 => vard[]) vds;
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

   strti[] constant BT = [
////     id  nv nr nb  attr ldc ldd name
strti(  NONE, 0, 0, 0, NONE, 0, 0, "?"),
strti(  BOOL, 0, 0, 1, BOOL, 4, 0, "bool"),
strti(   INT, 0, 0, 1, NONE, 3, 0, "int"),
strti(  UINT, 0, 0, 1, NONE, 4, 0, "uint"),
strti( BYTES, 0, 0, 8, NONE, 5, 0, "bytes"),
strti(STRING, 0, 1, 0, NONE, 6, 0, "string"),
strti(  CELL, 0, 1, 0, NONE, 4, 0, "TvmCell"),
strti(STRUCT, 0, 0, 0, NONE, 6, 0, "struct"),
strti( ARRAY, 0, 1, 0, NONE, 2, 0, "array"),
strti(   MAP, 0, 1, 0, NONE, 7, 0, "map"),
strti(  ENUM, 0, 0, 1, NONE, 4, 0, "enum")
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
    function enjoin(string prefix, string[] body, string suffix) internal returns (string res) {
        for (string s: body)
            res.append(prefix + s + suffix + "\n");
    }

    function strchr(bytes s, bytes1 c) internal returns (uint) {
        uint i;
        for (bytes1 b: s) {
            if (b == c)
                return i + 1;
            i++;
        }
    }

    function fix_arr_name(bytes sname) internal returns (string res) {
        uint q1 = strchr(sname, '[');
        uint q2 = strchr(sname, ']');
        if (q1 > 0 && q2 > 0)
            res = string(sname[ : q1 - 1]) + "s";
    }

    function fix_map_name(bytes sname) internal returns (string res) {
        uint q1 = strchr(sname, '(');
        uint q2 = strchr(sname, ')');
        uint q3 = strchr(sname, '=');
        uint q4 = strchr(sname, '>');
        if (q1 > 0 && q2 > 0 && q3 > 0 && q4 > 0)
            res = string(sname[q1 : q3 - 2]) + "to" + string(sname[q4 + 1 : q2 - 1]);
    }

    function conf_flags(uint vh, uint word) internal returns (bool f1, bool f2, bool f3, bool f4, bool f5, bool f6, bool f7, bool f8) {
        uint h = vh >> word * 8 & 0xFF;
        f1 = (h & 0x01) > 0;
        f2 = (h & 0x02) > 0;
        f3 = (h & 0x04) > 0;
        f4 = (h & 0x08) > 0;
        f5 = (h & 0x10) > 0;
        f6 = (h & 0x20) > 0;
        f7 = (h & 0x40) > 0;
        f8 = (h & 0x80) > 0;
    }

    string constant BB1 = " {\n\n";
    string constant BB2 = " {\n";
    string constant IND1 = "    ";
    string constant IND2 = "        ";
    string constant BE1 = "}\n\n";
    string constant BE2 = "    }\n";
    function as_block(uint8 level, string header, string[] body) internal returns (string res) {
        if (level == 1) {
            res.append(header + BB1);
            for (string s: body)
                res.append(IND1 + s + "\n");
            res.append(BE1);
        } else if (level == 2) {
            res.append(header + BB2);
            for (string s: body)
                res.append(IND2 + s + "\n");
            res.append(BE2);
        }
    }

    function gen_function(string header, string[] body) internal returns (string res) {
        res = header;
        for (string s: body)
            res.append(IND2 + s + "\n");
        res.append(BE2);
    }

    function header_print(string name, string arg) internal returns (string res) {
        return "function " + name + "(" + arg + ") internal returns (string out) {\n";
    }
    function gen_function_header(string name, string arg, string mods, string ret_arg) internal returns (string res) {
        return "function " + name + "(" + arg + ") " + mods + " returns (" + ret_arg + ") {\n";
    }
    function _append(string s) internal returns (string) {
        return "out.append(" + s + ");";
    }

    function get_len(gtic g) internal returns (uint8) {
        return uint8(g.tc.length);
    }
    function get_id(gtic g, uint t) internal returns (uint8) {
        return g.tc[t].id;
    }
    function get_nv(gtic g, uint t) internal returns (uint8) {
        return g.tc[t].nv;
    }
    function get_attr(gtic g, uint t) internal returns (uint8) {
        return g.tc[t].attr & 0x0F;
    }
    function get_ldecl(gtic g, uint t) internal returns (uint8) {
        return g.tc[t].ldecl;
    }
    function get_ldesc(gtic g, uint t) internal returns (uint8) {
        return g.tc[t].ldesc;
    }
    function get_name(gtic g, uint t) internal returns (string) {
        return g.tc[t].name;
    }
    function get_vars(gtic g, uint t) internal returns (vard[] vd) {
//        return g.tc[t].vd;
        if (g.vds.exists(uint8(t)))
            return g.vds[uint8(t)];
    }

    function _print_var(gtic g, uint vtype, string vname) internal returns (string res) {
        string pname = _pname(g, vtype, vname);
        uint8 attr = get_attr(g, vtype);
        if (attr == ENUM || attr == STRUCT || attr == ARRAY || attr == MAP)
            res = pname;
        else
            res = "format(\"{}\", " + pname + ")";
    }
    function _pname(gtic g, uint vtype, string vname) internal returns (string) {
        uint8 attr = get_attr(g, vtype);
        uint8 vtid = get_id(g, vtype);
        string tiname = get_name(g, vtid);
        return
            attr == BYTES   ? "string(bytes(" + vname + "))" :
            attr == ENUM ||
            attr == STRUCT  ? "print_" + tiname + "(" + vname + ")" :
            attr == ARRAY   ? "print_" + fix_arr_name(tiname) +  "(" + vname + ")" :
            attr == MAP     ? "print_" + fix_map_name(tiname) +  "(" + vname + ")" :
            attr == BOOL    ?  vname + " ? \"Yes\" : \"No\"" :
            vtid == CELL    ? "tvm.hash(" + vname + ")" :
                               vname;
    }
    function gen_module(gtic g, uint h) internal returns (string out, string dbg) {
        (mod_info mi, , , ) = g.unpack();
        (uint8 maj, uint8 min, uint8 nt, , , , , , , uint8 fla_start, uint8 fla_len, , uint8 da_len, uint8 enum_start, uint8 enum_len,
            uint8 struct_start, uint8 struct_len, uint8 map_start, uint8 map_len, string name) = mi.unpack();
        (bool struct_defs, bool enum_defs, bool type_printing, bool terse_printing, bool verbose_printing, bool helper_encoders, bool print_cells_by_type, ) = conf_flags(h, 0);

        string libname = "lib" + name;

        string[] defs;
        string[] fns;
        string[] empty;
        for (uint i = fla_start; i < fla_start + fla_len + da_len; i++) {
            string sname = get_name(g, i);
            vard[] vd = get_vars(g, i);
            if (vd.empty())
                continue;
//            uint8 vtattr = get_attr(g, vd[0].vtype);
            fns.push(gen_function(header_print("print_" + fix_arr_name(sname), sname + " val"), [
                "for (uint i = 0; i < val.length; i++)",
//                "    " + _append((vtattr == STRUCT ? "print_" + get_name(g, get_id(g, vd[0].vtype)) + "(val[i])" : "format(\"{} \", val[i])"))]));
//                "    " + _append((vtattr == STRUCT || vtattr == ENUM ? "print_" + get_name(g, get_id(g, vd[0].vtype)) + "(val[i])" : "format(\"{} \", val[i])"))]));
                    "    " + _append(_print_var(g, vd[0].vtype, "val[i]"))]));
//string pname = _print_var(g, vtype, vname);
        }

        for (uint i = map_start; i < map_start + map_len; i++) {
            string sname = get_name(g, i);
            vard[] vd = get_vars(g, i);
            if (vd.length <= 1)
                continue;
//            uint8 vtattr = get_attr(g, vd[1].vtype);
            fns.push(gen_function(header_print("print_" + fix_map_name(sname), sname + " val"), [
                "for ((" + get_name(g, vd[0].vtype) + " key, " + get_name(g, vd[1].vtype) + " value): val)",
//                "    " + _append("format(\"{} => \", key) + " + (vtattr == STRUCT ? "print_" + get_name(g, vd[1].vtype) + "(value)" : "format(\"{}\", value)"))]));
                "    " + _append("format(\"{} => \", key) + " + _print_var(g, vd[1].vtype, "value"))]));
//                (vtattr == STRUCT ? "print_" + get_name(g, vd[1].vtype) + "(value)" : "format(\"{}\", value)"))]));
//_append(_print_var(g, vd[0].vtype, "val[i]"))
        }

        for (uint i = enum_start; i < enum_start + enum_len; i++) {
            string sname = get_name(g, i);
            vard[] vd = get_vars(g, i);
            uint8 nv = get_nv(g, i);
            string vname = vd[0].vname;
            string tyd = "enum " + sname + " { " + vname;
            string[] fnb = ["if (val == " + sname + "." + vname + ") " + _append("\"" + vname + "\"")];
            for (uint j = 1; j < nv; j++) {
                vname = vd[j].vname;
                tyd.append(", " + vname);
                fnb.push("else if (val == " + sname + "." + vname + ") " + _append("\"" + vname + "\""));
            }
            tyd.append(" }\n");
            if (enum_defs)
                defs.push(tyd);
            fns.push(gen_function(header_print("print_" + sname, sname + " val"), fnb));
        }

        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            if (i >= get_len(g)) {
                dbg.append(format("Error: index {} out of range {}, max: {}\n", i, get_len(g), nt));
                break;
            }
            uint8 nv = get_nv(g, i);
            uint8 ldecl = get_ldecl(g, i);
            uint8 ldesc = get_ldesc(g, i);
            string sname = get_name(g, i);
            vard[] vd = get_vars(g, i);
            string[] vds;
            string[] vns;
            string[] vts;
            string[] vvs;
            string[] vas;
            string[] tyl;
            for (uint j = 0; j < nv; j++) {
                (uint8 vtype, , uint8 dlen, uint8 clen, string vname, string vdesc) = vd[j].unpack();
                uint8 attr = get_attr(g, vtype);
                string vtname = get_name(g, vtype);
//                uint8 vtid = get_id(g, vtype);
                string pname = _pname(g, vtype, vname);

                if (struct_defs) {
                    string tyd = vtname + " " + vname + ";";
                    if (!vdesc.empty()) {
                        repeat(ldecl + 1 - dlen)
                            tyd.append(" ");
                        tyd.append("// " + vdesc);
                    }
                    tyl.push(tyd);
                }
                if (attr == ARRAY || attr == MAP)
                    vas.push(pname);
                else {
                    vns.push(pname);
                    vts.push(vname + ": {}");
                    string svs = (clen > 0 ? vdesc : vname) + ":";
                    uint pad = clen > 0 ? ldesc + 1 - clen : ldecl + 1 - dlen;
                    repeat (pad)
                        svs.append(" ");
                    svs.append("{}");
                    vvs.push(svs);
                }
                vds.push(vtname + " " + vname);
            }
            if (struct_defs)
                defs.push("struct " + sname + " {\n" + enjoin("    ", tyl, "") + "}\n");

            string[] body;
            body.push("(" + join(vds, ", ") + ") = val.unpack();");
            string var_list = join(vns, ", ");
            if (terse_printing)
                body.push(_append("format(\"" + join(vts, " ") + "\\n\",\n" + "            " + var_list + ")"));
            if (verbose_printing)
                body.push(_append("format(\"" + join(vvs, "\\n") + "\\n\",\n" + "            " + var_list + ")"));
            for (string s: vas)
                body.push(_append(s));

            fns.push(gen_function(header_print("print_" + sname, sname + " val"), body));
        }

        string[] fsto;
        string[] ftp_body = ["if (t == 0) " + _append("\"Invalid content type\\n\"")];
        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            if (i >= get_len(g)) {
                dbg.append(format("Error: index {} out of range {}, max: {}\n", i, get_len(g), nt));
                break;
            }
            uint8 id = get_id(g, i);
            string sname = get_name(g, i);
            if (helper_encoders)
                fsto.push(gen_function(gen_function_header("store_" + sname, sname + " val", "external pure", "TvmCell c"), ["return abi.encode(val);"]));

            ftp_body.push("else if (t == " + format("{}", id) + ") " + _append(libname + ".print_" + sname + "(abi.decode(c, " + sname + "))"));
        }
        if (print_cells_by_type)
            fsto.push(gen_function(gen_function_header("print", "uint8 t, TvmCell c", "external pure", "string out"), ftp_body));

        string prag = "pragma ton-solidity >= 0." + format("{}.{}", maj, min) + ";";
        string tdefs = join(defs, "\n");
        string lib = as_block(1, "library " + libname, type_printing ? fns : empty);
        string ctx = as_block(1, "contract " + name, fsto);
        string mod = join([prag, tdefs, lib, ctx], "\n");

        out.append(mod);
    }

    function fill_type(gtic g, uint8 t, uint8 id, string tname, vard[] vd) internal {
        strti pti = g.tc[t];
        uint8 nv;
        uint8 nr = pti.nr;
        uint16 nb = pti.nb;
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
        g.tc[id] = strti(id, nv, nr, nb, t, ldecl, ldesc, tname);
        g.vds[id] = vd;
    }

    function print_types(gtic g) internal returns (string out) {
        (mod_info mi, strti[] ti, , mapping (uint => uint8) tnc) = g.unpack();
        (uint8 maj, uint8 min, uint8 nt, uint8 start, uint8 len, uint8 base_start, uint8 base_len, uint8 fixed_start, uint8 fixed_len,
            uint8 fla_start, uint8 fla_len, uint8 da_start, uint8 da_len, uint8 enum_start, uint8 enum_len, uint8 struct_start, uint8 struct_len, uint8 map_start, uint8 map_len, string name) = mi.unpack();
        out.append(format(" maj: {} min: {} nt: {} start: {} len: {} base_start: {} base_len: {} fixed_start: {} fixed_len: {} fla_start: {} fla_len: {} da_start: {} da_len: {} enum_start: {} enum_len: {} struct_start: {} struct_len: {} map_start: {} map_len: {} name: {}\n",
            maj, min, nt, start, len, base_start, base_len, fixed_start, fixed_len, fla_start, fla_len, da_start, da_len, enum_start, enum_len, struct_start, struct_len, map_start, map_len, name));

        for ((, uint8 n): tnc)
            out.append(format("{}) ", n) + (n < ti.length ? ti[n].name : "???") + "\n");

        out.append(format("id  nv nr nb att dcl dsc   name\n"));
        for (uint i = 1; i < nt; i++) {
            if (i >= get_len(g))
                continue;
            (uint8 id, uint8 nv, uint8 nr, uint16 nb, uint8 attr, uint8 ldecl, uint8 ldesc, string sname) = ti[i].unpack();
            out.append(format("{:2}) {:2} {} {:4} {:2} {:2} {:3} {}\n",
                id, nv, nr, nb, attr, ldecl, ldesc, sname));
        }
    }
}
