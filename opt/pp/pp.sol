pragma ever-solidity >= 0.66.0;

import "b0.sol";
import "libstr.sol";

struct sym {
    uint8 nl;
    byte sb;
    uint nh;
    string name;
    string val;
}
struct sym2 {
    uint8 nl;
    string name;
    string val;
}
contract pp is b0 {

    function process2(string s) external pure returns (string out) {
        bytes bb = bytes(s);
        uint len = bb.length - 1;
        uint p;
        uint p0;
        mapping (byte => sym2[]) ms2;
        while (p++ < len) {
            byte b = bb[p];
            if (b == "#") {
                out.append(bb[p0 : p]);
                uint t0 = p + 1;
                while (bb[p++] != ' ') {}
                if (bb[t0 : p - 1] == "define") {
                    t0 = p;
                    while (bb[p++] != ' ') {}
                    uint t1 = p - 1;
                    while (bb[p++] != '\n') {}
                    ms2[bb[t0]].push(sym2(uint8(t1 - t0), bb[t0 : t1], bb[t1 + 1 : p - 1]));
                }
                p0 = p;
            } else if (ms2.exists(b)) {
                for (sym2 sy2: ms2[b]) {
                    (uint8 nl, string name, string val) = sy2.unpack();
                    if (bb[p : p + nl] == name) {
                        out.append(bb[p0 : p]);
                        out.append(val);
                        p0 = p + nl;
                        break;
                    }
                }
            }
        }
        out.append(bb[p0 : ]);
//        for (( , sym2[] sy2): ms2) {
//            for (sym2 s2: sy2) {
//                (uint8 nl, string name, string val) = s2.unpack();
//                out.append(format("len: {} ", nl) + name + " => " + val + "\n");
//            }
//        }
    }
    function process(string s) external pure returns (string out) {
        sym[] mcs;
        bytes mm;
        bytes[] lll = libstr.split(s, '\n');

        for (uint j = 0; j < lll.length; j++) {
            bytes ln = lll[j];
            uint lnl = ln.length;
            if (lnl == 0)
                continue;
            if (ln[0] == '#') {
                bytes[] ww = libstr.split(ln, ' ');
                if (ww[0] == "#define") {
                    string sm = ww[1];
                    byte b = ww[1][0];
                    mcs.push(sym(uint8(sm.byteLength()), b, tvm.hash(sm), sm, ww[2]));
                    mm.append(bytes(b));
                }
            } else {
                if (!mm.empty()) {
                    for (uint i = 0; i < lnl - 1; i++) {
                        byte b = ln[i];
                        if (libstr.strchr(mm, b) > 0) {
                            for (sym sy: mcs) {
                                if (sy.sb == b) {
                                    (uint8 nl, , , string name, string val) = sy.unpack();
                                    if (i + nl < lnl && ln[i : i + nl] == name)
                                        lll[j] = string(ln[ : i]) + val + string(ln[i + nl : ]);
                                }
                            }
                        }
                    }
                }
                out.append(lll[j]);
            }
            out.append("\n");
        }
    }

    function main(string s) external pure returns (string cmd) {
        string[] vv = libstr.split(s, ' ');
        string[] argv;
        argv.push("pp");
        argv.push("process2");
        for (string v: vv)
            argv.push(v);
        return cmd_main(argv);
    }
    function cmd_main(string[] argv) internal pure returns (string cmd) {
        cmd.append("tonos-cli -c etc/" + argv[0] + ".conf runx -m " + argv[1] + " --s \"`cat " + argv[2] + "`\" | jq -r .out;");
    }
}



//    function process3(string s) external pure returns (string out) {
//        TvmBuilder bx;
//        bx.store(s);
//        TvmSlice s0 = bx.toSlice().loadRefAsSlice();
//        
////        bytes bb = bytes(s);
////        uint len = bb.length - 1;
//        uint p;
//        uint p0;
//        mapping (byte => sym2[]) ms2;
//        TvmSlice s1 = s0;
//        TvmBuilder br;
//        while (true) {
//            byte b = s0.decode(byte);
//            if (b == "#") {
//                //out.append(bb[p0 : p]);
//                br.storeRef(s1);
//                uint t0 = p + 1;
//                while (bb[p++] != ' ') {}
//                if (bb[t0 : p - 1] == "define") {
//                    t0 = p;
//                    while (bb[p++] != ' ') {}
//                    uint t1 = p - 1;
//                    while (bb[p++] != '\n') {}
//                    ms2[bb[t0]].push(sym2(uint8(t1 - t0), bb[t0 : t1], bb[t1 + 1: p - 1]));
//                }
//                p0 = p;
//            } else {
//                if (ms2.exists(b)) {
//                    for (sym2 sy2: ms2[b]) {
//                        (uint8 nl, string name, string val) = sy2.unpack();
//                        if (bb[p : p + nl] == name) {
//                            out.append(bb[p0 : p]);
//                            out.append(val);
//                            p0 = p + nl;
//                            break;
//                        }
//                    }
//                }
//            }
//        }
//        out.append(bb[p0 : ]);
//    }