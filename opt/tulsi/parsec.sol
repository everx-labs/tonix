pragma ton-solidity >= 0.67.0;

import "common.h";
import "libtic.sol";
import "libstr.sol";

contract parsec is common {

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

    function scan(bytes bb) internal pure returns (mapping (uint => uint8) tnc, string[] prags, string[] fls, string[] enums, string[] flas, string[] das, string[] strus) {
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
                } else if (tnc[tvm.hash(w1)] == 0) {
                    tnc[tvm.hash(w1)] = cur;
                    cur++;
                    if (w1l > 0 && w1[w1l - 1] == "]") {
                        uint q = libstr.strrchr(w1, "[");
                        if (q > 0) {
                            if (q + 1 < w1l)
                                flas.push(w1);
                            else
                                das.push(w1);
                        }
                    } else
                        fls.push(w1);
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
    }


    function parse_source(string name, string ss) external pure returns (gtic g) {
        tvm.accept();
        g.mi.name = name;

        (mapping (uint => uint8) tnc, , string[] fls, string[] enums, string[] flas, string[] das, string[] strus) = scan(bytes(ss));

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
        uint8 len = struct_start + struct_len;

        uint8 nt = fixed_start;

        g.mi = mod_info(0, 0, nt, start, len, base_start, base_len, fixed_start, fixed_len, fla_start, fla_len, da_start, da_len, enum_start, enum_len, struct_start, struct_len, name);

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
            g.add_fixed_length_type(t, i * fac);
        }

        vard[] vv;
        for (bytes s: flas)
            g.add_type(libtic.ARRAY, s, vv);
        for (bytes s: das)
            g.add_type(libtic.ARRAY, s, vv);
        for (bytes s: enums)
            g.add_type(libtic.ENUM, s, vv);
        for (bytes s: strus)
            g.add_type(libtic.STRUCT, s, vv);

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
            uint w2l = w2.length;
            bytes w3 = wwl > 2 ? www[2] : "";
            bytes w4;

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
                    w4 = wwl > 3 ? www[3] : "";
                    bytes[] wx = words(w4, '.', true);
                    optional(int) vi = stoi(wx[1]);
                    if (vi.hasValue())
                        g.mi.maj = uint8(vi.get());
                    vi = stoi(wx[2]);
                    if (vi.hasValue())
                        g.mi.min = uint8(vi.get());
                } else {
                    if (sname.empty())
                        continue;
                    uint8 tn = g.tnc[tvm.hash(w1)];
                    uint8 dl = uint8(w1l + w2l);
                    uint8 cl;
                    uint8 vcnt = 1;
                    bytes w1b;
                    uint8 tb;
                    if (w1l > 0 && w1[w1l - 1] == "]") {
                        uint q = libstr.strrchr(w1, "[");
                        if (q > 0) {
                            if (q + 1 < w1l) {
                                optional(int) vi = stoi(w1[q : w1l - 1]);
                                if (vi.hasValue())
                                    vcnt = uint8(vi.get());
                            } else
                                vcnt = 0;
                            w1b = w1[ : q - 1];
                            tb = g.tnc[tvm.hash(w1b)];
                        }
                        g.fill_type(libtic.ARRAY, tn, w1, [vard(tb, vcnt, dl, cl, w2[ : w2l - 1], w4)]);
                    }
                    if (w3 == "//") {
                        for (uint i = 3; i < wwl; i++)
                            w4.append(string(www[i]) + (i + 1 < wwl ? " " : ""));
                        cl = uint8(w4.length);
                    }
                    vv.push(vard(tn, vcnt, dl, cl, w2[ : w2l - 1], w4));
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
