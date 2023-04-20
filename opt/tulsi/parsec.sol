pragma ton-solidity >= 0.67.0;

import "common.h";
import "libtic.sol";

contract parsec is common {

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
    function absorb_module(string name, string ss) external pure returns (gtic g, string out, string dbg) {
        g.name = name;
        g.gt = libti.with_base();

        g.gt.derive_fixed_length_type(libti.UINT, [1, 2, 3, 4, 31]);
        g.gt.derive_fixed_length_type(libti.BYTES, [8, 12]);

        bool hoard = false;
        bool act = false;
        bytes bb = bytes(ss);

        dbg.append(debug_parse(bb));

        strti s;
        bytes[] ww = words(bb, '\n', true);
        for (bytes w: ww) {
            if (w == "}") {
                hoard = false;

                g.tc.push(s);
                g.nt++;

                g.gt.ss.push(s.name);
                g.gt.tnc[tvm.hash(s.name)] = s.tid;

                g.gt.tt.push(stt(s.tid, libti.STRUCT, s.nr, s.nb, uint8(s.name.byteLength()), 3, 0, s.attr));
                g.gt.nt++;
                delete s;
            } else {
                bytes[] www = words(w, ' ', true);
                uint wwl = www.length;
                bytes w1 = wwl > 0 ? www[0] : "";
                bytes w2 = wwl > 1 ? www[1] : "";
                bytes w3 = wwl > 2 ? www[2] : "";
                bytes w4;
                if (!w2.empty()) {
                    if (w1 == "pragma" && (w2 == "ton-solidity" || w2 == "ever-solidity"))
                        act = true;
                    else if (w1 == "struct") {
                        hoard = true;
                        s.name = w2;
                        s.id = g.nt;
                        s.tid = g.gt.nt;
                        s.attr = libti.STRUCT;
                    } else {
                        if (hoard) {
                            uint8 tn = g.gt.tnc[tvm.hash(w1)];
                            uint8 dl = uint8(w1.length + w2.length);
                            uint8 cl;
                            stt vt = g.gt.tt[tn];
                            s.nr += vt.rsz;
                            s.nb += vt.bsz;
                            s.nv++;
                            if (s.ldecl < dl)
                                s.ldecl = dl;
                            if (w3 == "//") {
                                for (uint i = 3; i < wwl; i++)
                                    w4.append(string(www[i]) + (i + 1 < wwl ? " " : ""));
                                cl = uint8(w4.length);
                                if (s.ldesc < cl)
                                    s.ldesc = cl;
                            }

                            s.vd.push(vard(tn, dl, cl, w2[ : w2.length - 1], w4));
                        }
                    }
                }
            }
        }
        dbg.append(g.gt.print_types());
        dbg.append(g.print_types());
        out.append(g.gen_print());
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
    function strtok(bytes s, bytes1 c) internal pure returns (uint[] ppp) {
        uint i;
        for (bytes1 b: s) {
            if (b == c)
                ppp.push(i + 1);
            i++;
        }
    }
}