pragma ton-solidity >= 0.68.0;

import "common.h";
import "libtic.sol";
import "libstr.sol";

contract parsec is common {

    bytes constant WHITESPACE = "\t\n ";
    uint8 constant ERROR = 0xFF;
    function strip_leading(bytes s, bytes cc) internal pure returns (bytes) {
        uint pos;
        for (bytes1 b: s) {
            if (libstr.strchr(cc, b) > 0)
                pos++;
            else
                break;
        }
        return pos > 0 ? s[pos : ] : s;
    }
    function strip_trailing(bytes s, bytes1 c) internal pure returns (bytes) {
        uint len = s.length;
        return len > 0 && s[len - 1] == c ? s[ : len - 1] : s;
    }
    function words(bytes s, bytes1 c, bool skip_empty) internal pure returns (bytes[] ww) {
        uint i;
        uint t;
        uint len = s.length;
        while (i < len) {
            if (s[i] == c) {
                if (!skip_empty || i > t) {
                    ww.push(s[t : i]);
                    t = i;
                }
                while (i < len && s[i] == c) {
                    i++;
                    t++;
                }
            }
            i++;
        }
        if (t < len)
            ww.push(s[t : ]);
    }

    function _var_decl(bytes w) internal pure returns (bytes vtype, bytes vname, bytes vcom, bytes err, uint8 hint) {
        uint q1 = libstr.strrchr(w, '/');
        if (q1 > 0)
            vcom = strip_leading(w[q1 : ], WHITESPACE);
        uint q2 = libstr.strchr(w, ';');
        if (q2 > 0) {
            bytes vdecl = w[ : q2 - 1];
            uint q3 = libstr.strrchr(vdecl, ' ');
            if (q3 > 0) {
                vname = vdecl[q3 : ];
                vtype = strip_leading(vdecl[ : q3 - 1], WHITESPACE);
                uint vl = vtype.length;
                uint q4 = libstr.strrchr(vtype, '[');
                if (q4 > 0)
                    hint = libtic.ARRAY;
                else if (vl > 7 && vtype[ : 7] == "mapping")
                    hint = libtic.MAP;
            } else
                err = "No variable separator in declaration";
        } else
            err = "No semicolon in declaration";
        if (!err.empty())
            hint = ERROR;
    }

    function paw(string ss) external pure returns (string out) {
        bytes[] ww = words(ss, '\n', true);
        for (bytes w: ww) {
            out.append("Line: " + string(w) + "\n");
            (bytes vtype, bytes vname, bytes vcom, bytes err, uint8 hint) = _var_decl(w);
            if (!err.empty())
                out.append("Error: " + string(err) + "\n");
            else {
                out.append(format("hint: {}", hint) + "Type: " + string(vtype) + " name: " + string(vname));
                if (!vcom.empty())
                    out.append(" comments: " + string(vcom));
                out.append("\n");
            }
        }
    }

    function scan(bytes bb) internal pure returns (mapping (uint => uint8) tnc, string[] prags, string[] fls, string[] enums, string[] flas, string[] das, string[] strus, string[] mas) {
        uint8 cur;
        for (uint i = 0; i < libtic.BT.length; i++)
            tnc[tvm.hash(libtic.BT[i].name)] = uint8(i);
        cur = uint8(libtic.BT.length);

        bytes[] ww = words(bb, '\n', true);
        for (bytes w: ww) {
            bytes[] www = words(w, ' ', true);
            uint wwl = www.length;
            bytes w1 = wwl > 0 ? www[0] : "";
            uint w1l = w1.length;
            bytes w2 = wwl > 1 ? www[1] : "";
            if (w2.length > 0) {
                if (w1 == "pragma" || w1 == "struct" || w1 == "enum") {
                    if (w1 == "pragma") prags.push(w2);
                    else if (w1 == "struct") strus.push(w2);
                    else if (w1 == "enum") enums.push(w2);
                    tnc[tvm.hash(w2)] = cur;
                    cur++;
                } else {
                    (bytes vtype, , , bytes err, uint8 hint) = _var_decl(w);
                    if (err.empty() && tnc[tvm.hash(vtype)] == 0) {
                        tnc[tvm.hash(vtype)] = cur;
                        cur++;
                        w1l = vtype.length;
                        if (vtype[w1l - 1] == "]") {
                            uint q = libstr.strrchr(vtype, "[");
                            if (q > 0) {
                                if (q + 1 < w1l)
                                    flas.push(vtype);
                                else
                                    das.push(vtype);
                            }
                        } else if (hint == libtic.MAP)
                            mas.push(vtype);
                        else
                            fls.push(vtype);
                    }
                }
            }
        }

        cur = 0;
        for (strti ti: libtic.BT) tnc[tvm.hash(ti.name)] = cur++;
        for (string s: fls) tnc[tvm.hash(s)] = cur++;
        for (string s: flas) tnc[tvm.hash(s)] = cur++;
        for (string s: das) tnc[tvm.hash(s)] = cur++;
        for (string s: enums) tnc[tvm.hash(s)] = cur++;
        for (string s: strus) tnc[tvm.hash(s)] = cur++;
        for (string s: mas) tnc[tvm.hash(s)] = cur++;
    }

    function add_type(gtic gin, strti s) internal pure returns (gtic g) {
        g = gin;
        g.tc.push(s);
        g.mi.nt++;
        g.tnc[tvm.hash(s.name)] = s.id;
    }

    function add_types(gtic gin, uint8 t, string[] tnames) internal pure returns (gtic g) {
        g = gin;
        uint8 id = g.mi.nt;
        strti pti = g.tc[t];
        for (string tn: tnames) {
            strti ti = strti(id, 0, pti.nr, pti.nb, t, 0, 0, tn);
            g.tc.push(ti);
            g.mi.nt++;
            g.tnc[tvm.hash(tn)] = id;
            id++;
        }
    }

    function parse_source(string name, string ss) external pure returns (gtic g) {
        tvm.accept();
        g.mi.name = name;

        (mapping (uint => uint8) tnc, , string[] fls, string[] enums, string[] flas, string[] das, string[] strus, string[] mas) = scan(bytes(ss));

        g.tnc = tnc;
        g.tc = libtic.BT;

        uint8 start = 1;
        uint8 base_start = 1;
        uint8 base_len = uint8(libtic.BT.length) - 1;
        uint8 fixed_start = base_start + base_len;
        uint8 fixed_len = uint8(fls.length);
        uint8 fla_start = fixed_start + fixed_len;
        uint8 fla_len = uint8(flas.length);
        uint8 da_start = fla_start + fla_len;
        uint8 da_len = uint8(das.length);
        uint8 enum_start = da_start + da_len;
        uint8 enum_len = uint8(enums.length);
        uint8 struct_start = enum_start + enum_len;
        uint8 struct_len = uint8(strus.length);
        uint8 map_start = struct_start + struct_len;
        uint8 map_len = uint8(mas.length);
        uint8 len = map_start + map_len;

        uint8 nt = fixed_start;

        g.mi = mod_info(0, 0, nt, start, len, base_start, base_len,
            fixed_start, fixed_len, fla_start, fla_len,
            da_start, da_len, enum_start, enum_len,
            struct_start, struct_len, map_start, map_len, name);

        vard[] vv;
        for (bytes s: fls) {
            bytes1 b0 = s[0];
            uint8 t;
            uint8 sh;
            uint8 fac;
            uint16 i;
            if (b0 == 'i') {
                t = libtic.INT;
                sh = 3;
                fac = 1;
            } else if (b0 == 'u') {
                t = libtic.UINT;
                sh = 4;
                fac = 1;
            } else if (b0 == 'b') {
                t = libtic.BYTES;
                sh = 5;
                fac = 8;
            }
            if (t == 0)
                continue;
            bytes bv = s[sh : ];
            optional(int) vi = stoi(bv);
            if (vi.hasValue())
                i = uint16(vi.get());
//            g.add_fixed_length_type(t, i * fac);
            strti ti = strti(g.mi.nt, 1, 0, i * fac, t, 0, 0, format("{}{}", libtic.BT[t].name, i * fac / libtic.BT[t].nb));
            g.tc.push(ti);
            g.mi.nt++;
            g.tnc[tvm.hash(ti.name)] = ti.id;
        }

        g = add_types(g, libtic.ARRAY, flas);
        g = add_types(g, libtic.ARRAY, das);
        g = add_types(g, libtic.ENUM, enums);
        g = add_types(g, libtic.STRUCT, strus);
        g = add_types(g, libtic.MAP, mas);

        bytes[] ww = words(ss, '\n', true);
        string sname;
        uint8 tcur;
        for (bytes w: ww) {

            if (w == "}") {
                g.fill_type(libtic.STRUCT, tcur, sname, vv);
                delete sname;
                delete tcur;
                delete vv;
                continue;
            }

            bytes[] www = words(w, ' ', true);
            uint wwl = www.length;
            bytes w1 = wwl > 0 ? www[0] : "";
            uint w1l = w1.length;
            bytes w2 = wwl > 1 ? www[1] : "";

            if (!w2.empty()) {
                if (w1 == "struct") {
                    tcur = g.tnc[tvm.hash(w2)];
                    sname = w2;
                } else if (w1 == "enum") {
                    uint8 tn = g.tnc[tvm.hash(w2)];
                    vard[] vv0;
                    for (uint i = 3; i < wwl; i++) {
                        bytes wi = www[i];
                        if (wi == "{")
                            continue;
                        if (wi == "}")
                            break;
                        uint8 dl = uint8(wi.length);
                        vv0.push(vard(tn, 1, dl, 0, strip_trailing(wi, ','), ""));
                    }
                    g.fill_type(libtic.ENUM, tn, w2, vv0);
                } else if (w1 == "pragma" && (w2 == "ton-solidity" || w2 == "ever-solidity")) {
                    bytes w4 = wwl > 3 ? www[3] : "";
                    bytes[] wx = words(w4, '.', true);
                    optional(int) vi = stoi(wx[1]);
                    if (vi.hasValue())
                        g.mi.maj = uint8(vi.get());
                    vi = stoi(wx[2]);
                    if (vi.hasValue())
                        g.mi.min = uint8(vi.get());
                } else {
                    if (sname.empty() || w1l == 0)
                        continue;
                    (bytes vtype, bytes vname, bytes vcom, bytes err, uint8 hint) = _var_decl(w);
                    hint;
                    if (!err.empty())
                        continue;
                    w1l = w1.length;
                    uint8 tn = g.tnc[tvm.hash(vtype)];
                    uint8 vcnt = 1;
                    if (vtype[w1l - 1] == "]") {
                        uint8 tb;
                        uint q = libstr.strrchr(vtype, "[");
                        if (q > 0) {
                            if (q + 1 < w1l) {
                                optional(int) vi = stoi(vtype[q : w1l - 1]);
                                if (vi.hasValue())
                                    vcnt = uint8(vi.get());
                            } else
                                vcnt = 0;
                            tb = g.tnc[tvm.hash(vtype[ : q - 1])];
                        }
                        g.fill_type(libtic.ARRAY, tn, vtype, [vard(tb, vcnt, uint8(w1l + vname.length), uint8(vcom.length), vname, vcom)]);
                    } else if (hint == libtic.MAP) {
                        bytes[] wwm = words(vtype, ' ', false);
                        bytes tk = wwm[1][1 : ];
                        bytes tv = strip_trailing(wwm[3], ')');
                        g.fill_type(libtic.MAP, tn, vtype, [
                            vard(g.tnc[tvm.hash(tk)], 1, 3, 0, "key", ""),
                            vard(g.tnc[tvm.hash(tv)], 1, 5, 0, "value", "")]);
                    }
                    vv.push(vard(tn, vcnt, uint8(w1l + vname.length), uint8(vcom.length), vname, vcom));
                }
            }
        }
    }

    function debug_parse(bytes bb) internal pure returns (string out) {
        bytes[] ww = words(bb, '\n', true);
        for (bytes w: ww) {
            out.append("[" + string(w) + "]\n");
            out.append("[ ");
            bytes[] www = words(w, ' ', true);
            for (bytes w0: www)
                out.append("[" + string(w0) + "] ");
            out.append("]\n");
        }
    }
}
