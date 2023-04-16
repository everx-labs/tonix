pragma ton-solidity >= 0.67.0;

import "common.h";
import "libti.sol";

contract parse is common {

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
    function parse_type(string ss) external pure returns (gti g, string out) {
        g = libti.with_base();

        g.derive_fixed_length_type(libti.UINT, [1, 2, 3, 4, 31]);
        g.derive_fixed_length_type(libti.BYTES, [8, 12]);

        bool hoard = false;
        bool act = false;
        vard[] vv;
        bytes bb = bytes(ss);

        bytes[] ww = words(bb, '\n', true);
        for (bytes w: ww) {
            if (w == "}") {
                hoard = false;
                g.ss.push(vv[0].vname);
                g.tnc[tvm.hash(vv[0].vname)] = g.nt;
                (stt tt, sti ti) = libti.derive_struct_type(g.tt, vv);
                g.tti.push(ti);
                g.tt.push(tt);
                g.nt++;
                delete vv;
            } else {
                bytes[] www = words(w, ' ', true);
                bytes w1 = www.length > 0 ? www[0] : "";
                bytes w2 = www.length > 1 ? www[1] : "";
                if (!w2.empty()) {
//                out.append("[" + string(w1) + "] [" + string(w2) +"]\n");
                    if (w1 == "pragma" && (w2 == "ton-solidity" || w2 == "ever-solidity"))
                        act = true;
                    else if (w1 == "struct") {
                        hoard = true;
                        vv.push(vard(g.tnc[tvm.hash(w1)], w2, ""));
                    } else {
                        if (hoard)
                            vv.push(vard(g.tnc[tvm.hash(w1)], w2[ : w2.length - 1], ""));
                    }
                }
            }
        }
//        out.append(g.print_types());
        out.append(g.gen_print("parser"));
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