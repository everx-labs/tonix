pragma ever-solidity >= 0.66.0;

import "b0.sol";
import "libstr.sol";
import "libctypes.sol";
struct sy0 {
    uint8 nl;
    string name;
}
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

struct fsym {
    uint8 na;
    uint8 np;
    uint8 nl;
    string name;
    string[] frags;
    uint8[] vars;
}

struct lbuf {
    uint pos;
    bytes bb;
}
//struct sof {
//
//}
library liblexer {

    using liblexer for lbuf;
//    function fargs(bytes bb, uint start) internal pure returns (string[] args, uint pos) {
    function fargs(lbuf l) internal returns (string[] args) {

        uint p = l.pos;
        bytes bb = l.bb;
        uint pa = p;
        byte b;
        while (b != ')' ) {
            b = bb[p++];
            if (b == ',') {
                args.push(bb[pa : p - 1]);
                pa = p;
            }
        }
        args.push(bb[pa : p - 1]);
        l.pos = p;
    }

    function function_macro_definition(lbuf l) internal returns (fsym fs) {
        (uint p, bytes bb) = l.unpack();
        uint t1 = p;
        byte b;
        while (!libctype.isspace(b))
            b = bb[p--];
        string name = bb[p + 2 : t1];
        uint8 nl = uint8(t1 - p - 2);
        //(string[] aa2, uint sa) = fargs(bb, t1);
        string[] aa2 = l.fargs();//(bb, t1);
        uint na = aa2.length;
        uint np;
        (string[] frags, uint8[] vars, bytes[] words) = l.function_macro_definition_template(aa2);
        fs = fsym(uint8(na), uint8(np), nl, name, frags, vars);
    }

    function function_macro_definition_template(lbuf l, string[] args) internal returns (string[] frags, uint8[] vars, bytes[] words) {
        (uint p, bytes bb) = l.unpack();
        uint wc;
        uint sa = p;
        uint pw = sa;
        bytes w;
        byte b;
        bool ident;
        while (b != '\n') {
            b = bb[p++];
            if (ident && libctype.isident(b))
                wc++;
            else if (!libctype.isspace(b)) {
                if (wc == 0)
                    ident = libctype.isident(b);
                wc++;
            } else {
                if (wc == 0)
                    continue;
                w = bb[pw : p - 1];
                uint wl = w.length;
                if (wl > 0) {
                    for (uint j = 0; j < args.length; j++) {
                        if (w == args[j]) {
                            frags.push(bb[sa : pw]);
                            p += wl;
                            sa = p;
                            vars.push(uint8(j));
                            wc = 0;
                            pw = p;
                            delete w;
                        }
                    }
                    wc = 0;
                }
                words.push(w);
                delete w;
                pw = p;
            }
        }
        frags.push(bb[sa : p - 1]);
//        pos = p;
        l.pos = p;
    }

    function parse_line(lbuf l) internal returns (string out) {
        (uint p, bytes bb) = l.unpack();
        byte b;
        while (b != "\n") {
            b = bb[p++];
        }
        out.append(bb[l.pos : p]);
        l.pos = p;
    }
}
contract pp is b0 {

    using liblexer for lbuf;
//    function fargs(bytes bb, uint start) internal pure returns (string[] args, uint pos) {
//        uint p = start;
//        uint pa = p;
//        byte b;
//        while (b != ')' ) {
//            b = bb[p++];
//            if (b == ',') {
//                args.push(bb[pa : p - 1]);
//                pa = p;
//            }
//        }
//        args.push(bb[pa : p - 1]);
//        pos = p;
//    }

    function process3(string[] ss) external pure returns (string out) {
        for (string s: ss) {
            bytes bb = bytes(s);
            uint len = bb.length;
            if (len == 0)
                continue;
            uint p;
            uint wp;
            uint wc;
            while (p++ + 1 < len) {
                byte b = bb[p];
                if (!libctype.isspace(b))
                    wc++;
                if (wc == 0)
                    continue;
                if (libctype.isspace(b)) {
                    out.append("|");
                    out.append(bb[wp : p + 1]);
                    out.append("| ");
                    wc = 0;
                    wp = p + 1;
                }
            }
            if (wp + 1 < len) {
                out.append("|");
                out.append(bb[wp : len - 1]);
                out.append("| ");
            }
        }
        for (string s: ss)
            out.append(s);
    }

//    function function_macro_definition(bytes bb, uint p) internal pure returns (fsym fs, uint pos) {
//        uint t1 = p;
//        byte b;
//        while (!libctype.isspace(b))
//            b = bb[p--];
//        string name = bb[p + 2 : t1];
//        uint8 nl = uint8(t1 - p - 2);
//        //(string[] aa2, uint sa) = fargs(bb, t1);
//        string[] aa2 = fargs(bb, t1);
//        uint na = aa2.length;
//        uint np;
//        p = sa;
//        (string[] frags, uint8[] vars, uint po, bytes[] words) = function_macro_definition_template(bb, p, aa2);
//        fs = fsym(uint8(na), uint8(np), nl, name, frags, vars);
//        pos = po;
//    }

//    function function_macro_definition_template(bytes bb, uint p, string[] args) internal pure returns (string[] frags, uint8[] vars, uint pos, bytes[] words) {
//        uint wc;
//        uint sa = p;
//        uint pw = sa;
//        bytes w;
//        byte b;
//        bool ident;
//        while (b != '\n') {
//            b = bb[p++];
//            if (ident && libctype.isident(b))
//                wc++;
//            else if (!libctype.isspace(b)) {
//                if (wc == 0)
//                    ident = libctype.isident(b);
//                wc++;
//            } else {
//                if (wc == 0)
//                    continue;
//                w = bb[pw : p - 1];
//                uint wl = w.length;
//                if (wl > 0) {
//                    for (uint j = 0; j < args.length; j++) {
//                        if (w == args[j]) {
//                            frags.push(bb[sa : pw]);
//                            p += wl;
//                            sa = p;
//                            vars.push(uint8(j));
//                            wc = 0;
//                            pw = p;
//                            delete w;
//                        }
//                    }
//                    wc = 0;
//                }
//                words.push(w);
//                delete w;
//                pw = p;
//            }
//        }
//        frags.push(bb[sa : p - 1]);
//        pos = p;
//    }

    function process2(string s) external pure returns (string out) {
        bytes bb = bytes(s);
        uint len = bb.length - 1;
        uint p;
        lbuf l = lbuf(p, bb);

//        uint p0;
        mapping (byte => sym2[]) ms2;
        mapping (byte => fsym[]) msf;

//        out = s;
        out.append(l.parse_line());
        out.append(l.parse_line());
        out.append(l.parse_line());
        out.append(l.parse_line());
//        out.append(l.parse_line());
    }
    function process2_old(string s) external pure returns (string out) {
        bytes bb = bytes(s);
        uint len = bb.length - 1;
        uint p;
        uint p0;
        mapping (byte => sym2[]) ms2;
        mapping (byte => fsym[]) msf;

        while (p++ < len) {
            byte b = bb[p];
            if (b == "#") {
                out.append(bb[p0 : p]);
                uint t0 = p + 1;
                while (bb[p++] != ' ' ) {}
                if (bb[t0 : p - 1] == "define") {
                    t0 = p;
                    while (b != ' ' && b != '(')
                        b = bb[p++];
                    uint t1 = p - 1;
                    if (b == "(") {
                        lbuf l = lbuf(p, bb);
                        (string[] aa2) = l.fargs();
                        uint sa = l.pos;
                        out.append(format("{} => {} ", p, sa));
                        for (string aa: aa2) {
                            out.append("|" + aa + "| ");
                        }
                        (string[] frags, uint8[] vars, bytes[] words) = l.function_macro_definition_template(aa2);
//                        out.append(format("{} => {} ", p, po));

                        for (string w: words)
                            out.append("(" + w + ") ");
                        for (string f: frags)
                            out.append("{" + f + "} ");
                        for (uint8 v: vars)
                            out.append(format("[{}] ", v));
                        out.append("\n");

                        fsym fs = l.function_macro_definition();
//                        out.append(format("{} => {} ", t1, pos));
                        out.append(print_fsym(fs));
                        msf[bb[t0]].push(fs);
//                        msf[bb[t0]].push(fsym(uint8(na), uint8(np), uint8(t1 - t0),  bb[t0 : t1], frags, vars));
                    } else {
                        while (bb[p++] != '\n') {}
                        ms2[bb[t0]].push(sym2(uint8(t1 - t0), bb[t0 : t1], bb[t1 + 1 : p - 1]));
                    }
                } else {
                    out.append("?!");
                    out.append(bb[t0 : p - 1]);
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
            } else if (msf.exists(b)) {
                for (fsym sy: msf[b]) {
                    (uint8 na, uint8 np, uint8 nl, string name, string[] frags, uint8[] vars) = sy.unpack();
                    if (bb[p : p + nl] == name) {
                        for (uint j = 0; j < np; j++) {
                            out.append(frags[vars[j]]);
                            out.append(frags[j]);
                        }

                    }
                }
            }
        }
        out.append(bb[p0 : ]);
        out.append("-------\n");
        for (( , fsym[] fsy): msf) {
            for (fsym sy: fsy) {
                (uint8 na, uint8 np, uint8 nl, string name, string[] frags, uint8[] vars) = sy.unpack();
                out.append(format("{} np: {} na: {} nl: {}", name, np, na, nl) + "\n");
//                out.append(fn.name + "(");
//                out.append(args[0] + "(");
//                if (na > 1) {
////                    out.append(args[1]);
////                    for (uint j = 2; j < na; j++)
////                        out.append("," + args[j]);
//                }
//                out.append(") ");
//                for (string a: args)
//                    out.append(a + ", ");
                for (string f: frags)
                    out.append("[" + f + "]"  );
                out.append("\n");
//                for (uint8 f: vars)
//                    out.append(format("[{}] ", f));
//                out.append("-------\n");
                for (uint j = 0; j < np; j++) {
//                    out.append(args[vars[j]]);
                    out.append(format("[{}] ", vars[j]));
                    out.append(frags[j]);
                }
//                out.append(frags[np]);
                out.append("-------\n");
//                for (string a: args)
//                    out.append("[" + a + "] ");
                for (string f: frags)
                    out.append("[" + f + "]");
                out.append("-------\n");
            }
        }
        for (( , sym2[] sy2): ms2) {
            for (sym2 s2: sy2) {
                (uint8 nl, string name, string val) = s2.unpack();
                out.append(format("len: {} ", nl) + name + " => " + val + "\n");
            }
        }
        out.append("====================\n");
        for (( , fsym[] fsy): msf) {
            for (fsym sy: fsy) {
                out.append(expand_def(sy, ["MALLOC_DEFINE", "M_LOGINCLASS", "\"loginclass\"", "\"loginclass structures\""]) + "\n");
            }
        }
    }

    function print_fsym(fsym sy) internal pure returns (string out) {
        (uint8 na, uint8 np, uint8 nl, string name, string[] frags, uint8[] vars) = sy.unpack();
        out.append(format("{} np: {} na: {} nl: {}", name, np, na, nl) + "\n");
        for (string f: frags)
            out.append("{" + f + "} ");
        for (uint8 v: vars)
            out.append(format("[{}] ", v));
        out.append("\n");

    }
    function expand_def(fsym sy, string[] xp) internal pure returns (string out) {//(TvmCell c) {
        (uint8 na, uint8 np, uint8 nl, string name, string[] frags, uint8[] vars) = sy.unpack();
        if (name == xp[0]) {
            for (uint j = 0; j < np; j++) {
                uint8 v = vars[j];
                out.append(frags[j]);
                out.append(xp[v]);
            }
            out.append(frags[np]);
        } else {
            out.append("Mismatch: 1) [" + name + "]  2) [" + xp[0] + "]\n");
        }
    }

//    function expand_def(TvmSlice d, TvmSlice x) internal pure returns (string out) {//(TvmCell c) {
//        (uint8 na, uint8 np) = d.decode(uint8, uint8);
//        TvmBuilder b;
//        vector(bytes) xa;
//        for (uint i = 0; i < na; i++)
//            xa.push(x.loadRefAsSlice().decode(bytes));
//        for (uint j = 0; j < np; j++) {
//            uint8 v = d.decode(uint8);
//            out.append(xa[v]);
//            out.append(d.decode(bytes));
//        }
//
//    }
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
//        argv.push("process3");
        for (string v: vv)
            argv.push(v);
        return cmd_main(argv);
    }
    function cmd_main(string[] argv) internal pure returns (string cmd) {
        cmd.append("tonos-cli -c etc/" + argv[0] + ".conf runx -m " + argv[1] + " --s \"`cat " + argv[2] + "`\" | jq -r .out;");
//        cmd.append("tonos-cli -c etc/" + argv[0] + ".conf runx -m " + argv[1] + " --ss [\"`jq --raw-input --slurp 'split(\"\\n\")' " + argv[2] + "`]\" | jq -r .out;");
//         --s \"`cat " + argv[2] + "`\" | jq -r .out;");
// '{ss:split("\n")}' test2.sol
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