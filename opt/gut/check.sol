pragma ton-solidity >= 0.71.0;
import "common.h";
import "libparse.sol";
import "libgen.sol";

using libprint for string[];
contract check is common {

    uint8 constant JOBS = 0;
    uint8 constant COMM = 1;
    uint8 constant PRNT = 2;
    uint8 constant CONF = 3;
    uint8 constant BILD = 4;
    uint8 constant TEST = 5;

    string[][] constant CI = [
        ["jobs", "commands", "print", "config", "build", "test"],
        ["commands", "help", "size", "up", "check", "gena"],
        ["print", "hashes", "configs", "builds"],
        ["config", "contracts", "functions"],
        ["build", "parse", "ck", "gen"],
        ["test", "tpar", "tcheck", "tgen"]
    ];
    function cmd(string ss) external view returns (string[] res) {
        mapping (uint => string) cmds;
        cmds = _cached();
        uint hc = tvm.hash(ss);
        mapping (uint => uint) pools = _hashes();
        if (pools.exists(hc)) {
            uint rn = pools[hc];
            uint idx = rn & 0xFF;
            uint pn = rn >> 8 & 0xFF;
            if (idx == NULL || pn == NULL) {
                uint ln = idx + pn;
                if (ln < CI[JOBS].length)
                    res.print_items(CI[ln], " ", "echo", ":", "");
                return res;
            }
            if (pn == COMM) {
                res.push(cmds[hc]);
            } else if (pn == PRNT) {
                res.push("echo \"\\");
                if (idx == 1) {
                    for ((uint k, uint v): pools)
                        res.push(format("{}: {}\n\\", k, v));
                } else if (idx == 2) {
                    res.print_items(CC[CTX_ALL], " ", "", ":", "");
                    res.print_items(FO,    " ", "", ":", "");
                    res.print_items(ARB,   " ", "", ":", "");
                    res.print_items(ARS,  "\n", "", ":", "");
                }
                res.push("\"");
            } else if (pn == CONF) {
                if (idx == 1)
                    res.print_items(CC[CTX_ALL], " ", "echo", ":", "");
                else if (idx == 2) {
                    res.print_items(CC[CTX_PAR], " ", "echo", ":", "");
                    res.print_items(CC[CTX_CHK], " ", "echo", ":", "");
                    res.print_items(CC[CTX_GEN], " ", "echo", ":", "");
                }
            } else if (pn == BILD) {
                if (idx == 1) {

                }
            } else if (pn == TEST) {
                uint[] nn;
                //    _from_handle (uint h) => (uint8 n, uint8 t, uint8 c, uint8 f, uint8 o, uint8 a) {
                //    _to_handle(uint n, uint t, uint c, uint f, uint o, uint a) => (uint h) {
                if (idx == CTX_PAR) {
                    // par parse_source `jq -cn --rawfile v data/rt.sol '{name:\"rt\",ss:$v}'`
                    nn.push(_to_handle(CTX_PAR, PAR_SOURCE, NULL, F_NONE, CL_NOARG, IN_SRC_H));
                    nn.push(_to_handle(CTX_PAR, PAR_CACHED, NULL, F_NONE, CL_NOARG, IN_NOARG));
                } else if (idx == CTX_CHK) {
                    nn.push(_to_handle(CTX_CHK, CHK__MELD_, NULL, F_ROUT, CL_NOARG, IN_LINES));
                    //"`cat data/rt/lpar.tin`" | jq -r .out
                    nn.push(_to_handle(CTX_CHK, CHK_TCHECK, NULL, F_ROUT, CL_NOARG, IN_TYPES));
                    nn.push(_to_handle(CTX_CHK, CHK_ENC_MI, NULL, F_CELL, CL_MINFO, IN_NOARG));
                    nn.push(_to_handle(CTX_CHK, CHK_ENC_TI, NULL, F_CELL, CL_NOARG, IN_TYPES));
                } else if (idx == CTX_GEN) {
                    // gen do_gen --n 73 >/tmp/gen_73
                    nn.push(_to_handle(CTX_GEN, GEN_DO_GEN, NULL, F_NONE, CL_CACHE, IN_NOARG));
                    nn.push(_to_handle(CTX_CHK, CHK__MELD_, NULL, F_ROUT, CL_NOARG, IN_LINES));
                }
                for (uint h: nn) {
                    (uint8 n, uint8 t, uint8 c, uint8 f, uint o, uint a) = _from_handle(h);
                    c;
                    string cm = TOC + CC[CTX_ALL][n] + ".conf runx -m " + CC[n][t];
                    if (a != IN_NOARG)
                        cm.append(" \"`jq " + ARS[a] + "`\"");
                    if (o != CL_NOARG)
                        cm.append(" " + ARB[o]);
                    if (f != F_NONE)
                        cm.append(" | " + FO[f]);
                    res.push(cm);
                }
            }
        }
        else
            res.push(COUT[0]);
    }

    function mods(string[][] lines) external pure returns (string[] res) {
        for (string[] ss: lines) {
            string mod;
            for (string s: ss)
                mod.append(s + "\n");
            res.push(mod);
        }
    }
    function meld(string[] lines) external pure returns (string out) {
        for (string s: lines)
            out.append(s + "\n");
    }

    function tcheck(a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) external pure returns (string out) {
        string[] res;
        for (uint8 id = 0; id < tc.length; id++) {
            (uint attr, ) = tc[id].unpack();
            if (attr >= STRUCT) {
                if (attr == ENUM) {
                    if (vnames[id].empty())
                        res.println(format("id: {}: ", id) + " no members in enum");
                } else if (attr == STRUCT) {
                    if (vnames[id].empty())
                        res.println(format("id: {}: ", id) + " no members in struct");
                    else if (vars[id].empty())
                        res.println(format("id: {}: ", id) + " no vars in struct");
                }
            }
        }
        for (string s: res)
            out.append(s + "\n");
    }

    function enc_mi(string mname, uint8 maj, uint8 min) external pure returns (TvmCell c) {
        return abi.encode(mname, maj, min);
    }
    function enc_ti(a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) external pure returns (TvmCell c) {
        return abi.encode(tc, vars, vnames);
    }

    function paw(string ss) external pure returns (string out) {
        bytes[] ww = libparse.words(ss, '\n', true);
        out.append("hint  Type   Name\n");
        for (bytes w: ww) {
            (uint lh, uint th) = libparse.parse_line(w);
            if (lh == libparse.VAR_DECL) {
                (bytes vtype, bytes vname, bytes vcom) = libparse.parse_decl(w);
                string svtype = vtype.empty() ? "  ?  " : string(vtype);
                string svname = vname.empty() ? "  ?  " : string(vname);
                out.append(format("[{:2}] {} ", lh, th) + svtype + "\t" + svname);
                if (!vcom.empty())
                    out.append(" comments: " + string(vcom));
                out.append("\n");
            } else if (lh == libparse.TYPE_DEF) {
                out.append("Defined type: ");
                out.append(th == ENUM ? "enum" : th == STRUCT ? "struct" : "unknown");
                out.append("\n");
            } else if (lh == libparse.BLOCK_END) {
                out.append("Block end\n");
            } else if (lh == libparse.EMPTY) {
                out.append("Empty line\n");
            } else if (lh == libparse.PRAGMA) {
                out.append("Pragma\n");
            } else {
                out.append("Unknown line type\n");
            }
        }
    }

    string constant TOC = "/home/boris/newdir/tonix/bin/tonos-cli -c etc/";
    string[] constant CIN = ["", "help", "size", "up", "check", "gena"];
    string[] constant COUT = ["echo Huh?", "echo Help yourself. Try jobs", "ls -al build/*.tvc", "make up_check", "make ck", "make lgc"];
    function _cached() internal view returns (mapping (uint => string) cmds) {
        for (uint i = 0; i < CIN.length; i++) {
            cmds[tvm.hash(CIN[i])] = COUT[i];
        }
    }
    function _hashes() internal view returns (mapping (uint => uint) pools) {
        for (uint i = 0; i < CI.length; i++) {
            string[] cin = CI[i];
            for (uint j = 0; j < cin.length; j++) {
                pools[tvm.hash(cin[j])] = (i << 8) + j;
            }
        }
    }

    uint8 constant CTX_ALL = 0;
    uint8 constant CTX_PAR = 1;
    uint8 constant CTX_CHK = 2;
    uint8 constant CTX_GEN = 3;

    uint8 constant PAR_SOURCE = 1;
    uint8 constant PAR_CACHED = 2;

    uint8 constant CHK__MELD_ = 1;
    uint8 constant CHK_TBDTBD = 2;
    uint8 constant CHK_TCHECK = 3;
    uint8 constant CHK_ENC_MI = 4;
    uint8 constant CHK_ENC_TI = 5;

    uint8 constant GEN_TBDTBD = 1;
    uint8 constant GEN_DO_GEN = 2;

    string[][] constant CC = [["contracts", "par", "check", "gen"],
        ["par", "parse_source", "parse"],
        ["check", "meld", "?", "tcheck", "enc_mi", "enc_ti"],
        ["gen", "?", "do_gen", "?"]
    ];

    uint8 constant F_NONE = 0;
    uint8 constant F_ROUT = 1;
    uint8 constant F_CELL = 2;

    string[] constant FO = ["filters", "jq -r .out", "jq -r .c"];

    uint8 constant CL_NOARG = 0;
    uint8 constant CL_EMPTY = 1;
    uint8 constant CL_CACHE = 2;
    uint8 constant CL_MINFO = 3;

    string[] constant ARB = ["clargs",
    "",
    "--n 73 >/tmp/gen_73",
    "--mname rt --maj 68 --min 0"
    ];

    uint8 constant IN_NOARG = 0;
    uint8 constant IN_SRC_H = 1;
    uint8 constant IN_TYPES = 2;
    uint8 constant IN_LINES = 3;
    uint8 constant IN_EMPTY = 4;

    string[] constant ARS = ["inargs",
    "-cn --rawfile v data/rt.sol '{name:\"rt\",ss:$v}'",
    ". data/rt/rt.tin",
    "{\"lines\":.res} /tmp/gen_73",
    ""];
}
