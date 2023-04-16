pragma ton-solidity >= 0.67.0;

import "common.h";
import "libstr.sol";
contract tulsi is common {

    TvmCell _rom;
    uint32 _version;
    function immap(mapping (uint32 => TvmCell) m) external accept {
        for ((uint32 a, TvmCell c): m)
            if (_ram[a] != c)
                _ram[a] = c;
    }
    function ldr(uint32 a, uint32 n) external view returns (TvmCell[] cc) {
        repeat(n) {
            if (_ram.exists(a))
                cc.push(_ram[a]);
            a++;
        }
    }
    string constant SELF = "tulsi";
    string constant PP = "parse";
    bytes constant QUICKS = "cCuUhHbBqQwWxXzZ";

    uint8 constant CRUN = 1;
    uint8 constant CCALL = 2;
    enum MENU { MAIN, DUMP, PARSE, MISC, LAST }
    string[][] constant MCS = [
        ["Tulsi", "Dump", "Parse", "Misc"],
        ["Dump", "TBD" ],
        ["Parse", "Self", "Header", "Generate", "Test" ],
        ["Misc", "Bin size"]
    ];

    function _misc(uint n) internal pure returns (string cmd) {
        if (n == 1)
            cmd.append("du -b build/*.tvc\n");
    }

    function _cjoin(string[] args) internal pure returns (string out) {
        if (!args.empty()) {
            out = args[0];
            for (uint i = 1; i < args.length; i++)
                out.append(" && " + args[i]);
        }
    }
    function _toc_cmd(string cn, uint8 ccm, string fn, string args, bool redir, bool debug) internal pure returns (string cmd) {
        string pq = "~/bin/0.67.1/tonos-cli -c etc/" + cn + ".conf ";
        string ofn = " tmp/" + fn + ".res";
        string fargs = " -m " + fn + " " + args;
        cmd.append(pq + (ccm == CRUN ? "runx" : "callx") + fargs + " >" + ofn + "\n");
        if (debug) {
            cmd.append(_cjoin(["grep -q \"Error: {\"" + ofn, pq + "debug run -d build/parse.debug.json" + fargs, "tail -n15 trace.log | head -n-5\n"]));
        }
        cmd.append("jq -r .out" + ofn + (redir ? " >" + ofn + ".out" : "") + "\n");
    }
    function _parse(uint n) internal pure returns (string cmd) {
        if (n == 1) {
            cmd.append(_toc_cmd(PP, CRUN, "parse_type", "\"`cat ti.h | jq -Rs {ss:.}`\"", false, true));
        } else if (n == 2) {
            cmd.append(_print_cmd("File name?\n") + "read -r ii\n");
            cmd.append(_toc_cmd(PP, CRUN, "parse_type", "\"`cat $ii | jq -Rs {ss:.}`\"", false, false));
        } else if (n == 3) {
            cmd.append(_toc_cmd(PP, CRUN, "parse_type", "\"`cat ti.h | jq -Rs {ss:.}`\"", true, true));
            cmd.append("~/bin/0.67.1/sold tmp/parse_type.res.out -p parser -o build\n");
            cmd.append("make build/parser.deployed\n");
        } else if (n == 4) {
            cmd.append(_toc_cmd("parser", CRUN, "store_stt", "`jq -c {val:.g.tt[16]} tmp/parse_type.res`", true, false));
            cmd.append(_toc_cmd("parser", CRUN, "print", "--t 16 --c `jq -r .c tmp/store_stt.res`", false, false));
        }
    }
    function _dump(uint n) internal pure returns (string out) {
        if (n == 1)
            out.append("Placeholder\n");
    }
    function onc(uint h, string s) external view returns (uint hout, string cmd, string out) {
        if (s.empty())
            return (hout, cmd, out);
        bytes1 b0 = bytes(s)[0];
        uint8 v = uint8(b0);
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        MENU ectx = MENU(ctx);
        uint nitm;

        if (libstr.strchr(QUICKS, b0) > 0) {    // quick command
            if (v >= 0x41 && v <= 0x5A) // convert to lowercase
                v += 0x20;
            if (v == 0x62)  // go back to main menu
                ectx = MENU.MAIN;
            else    // execute a quick command
                cmd.append(_quick_command(v));
            nitm = itm;
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            uint8 n = v - 0x30; // digit ascii to value
            if (ectx == MENU.MAIN)   // switch context to a sub-menu
                ectx = MENU(n);
            else if (ectx == MENU.DUMP)
                out.append(_dump(n));
            else if (ectx == MENU.PARSE)
                cmd.append(_parse(n));
            else if (ectx == MENU.MISC)
                cmd.append(_misc(n));
            if (n == 0) // '0' prints current menu
                out.append(print_menu(ectx));
            nitm = n;
        }
        if (ectx != MENU(ctx)) {  // remember the current context
            nitm = 0;
            out.append(print_menu(ectx));
        }
        hout = _to_handle(idev, ct, uint(ectx), nitm, arg, val);
    }

    function _print_cmd(string s) internal pure returns (string) {
        return "printf \"" + s + "\";";
    }
    function print_menu(MENU n) internal view returns (string out) {
        return print_list_menu(MCS[uint(n < MENU.LAST ? n : MENU.MAIN)]);
    }
    function _quick_command(uint8 v) internal pure returns (string cmd) {
        mapping (uint8 => string) q;
        q[0x63] = "make cc";
        q[0x75] = "make up_" + SELF;
        q[0x77] = "make up_" + PP;
        q[0x71] = "echo Bye! && exit 0";
        q[0x78] = "set -x";
        q[0x7A] = "set +x";
        return q.exists(v) ? q[v] : "echo Unrecognized quick command";
    }
    function print_list_menu(string[] items) internal pure returns (string out) {
        uint len = items.length;
        if (len > 0)
            out.append(items[0] + "\n\n");
        for (uint i = 1; i < len; i++)
            out.append(format("{}) {}\n", i, items[i]));
    }

}
