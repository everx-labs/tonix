pragma ever-solidity >= 0.67.0;

import "b0.sol";
import "libstr.sol";

contract psh is b0 {

    string constant SELF = "psh";
    bytes constant QUICKS = "cCuUhHbBqQxXzZ";

    enum MENU { MAIN, M1, M2, LAST }

    string[][] constant MCS = [
        ["Main menu", "Menu 1", "Menu 2" ],
        ["Topic 1", "Item 1" ],
        ["Topic 2", "Item 1" ]
    ];

    string[][] constant HELP = [
        [""]
    ];

    function _print_help(uint ctx, uint itm) internal view returns (string out) {
        out.append("Help topic for " + MCS[ctx][0] + (itm > 0 ? " item " + MCS[ctx][itm] : "")  + "\n");
    }
    function onc(uint h, string s) external view returns (uint hout, string cmd) {
        return _onc(h, s);
    }
    function _onc(uint h, string s) internal view returns (uint hout, string cmd) {
        string out;
        if (s.empty())
            return (hout, cmd);
        bytes1 b00 = bytes(s)[0];
        uint8 v = uint8(b00);
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        MENU ectx = MENU(ctx);
        uint nitm;

        if (libstr.strchr(QUICKS, b00) > 0) {    // quick command
            if (v >= 0x41 && v <= 0x5A) // convert to lowercase
                v += 0x20;
            if (v == 0x62)  // go back to main menu
                ectx = MENU.MAIN;
            else if (v == 0x68)
                out.append(_print_help(ctx, itm));
            else    // execute a quick command
                cmd.append(_quick_command(v));
            nitm = itm;
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            uint8 n = v - 0x30; // digit ascii to value
            if (ectx == MENU.MAIN)   // switch context to a sub-menu
                ectx = MENU(n);
            else if (ectx == MENU.M1) { // do
            }
            if (n == 0) // '0' prints current menu
                out.append(print_menu(ectx));
            nitm = n;
        }
        if (ectx != MENU(ctx)) {  // remember the current context
            nitm = 0;
            out.append(print_menu(ectx));
        }
        hout = _to_handle(idev, ct, uint(ectx), nitm, arg, val);
        if (!out.empty())
            cmd.append(print_cmd(out));
    }

    function print_cmd(string s) internal pure returns (string) {
        return "printf \"" + s + "\";";
    }
    function print_menu(MENU n) internal view returns (string out) {
        return print_list_menu(MCS[uint(n < MENU.LAST ? n : MENU.MAIN)]);
    }
    function _quick_command(uint8 v) internal pure returns (string cmd) {
        mapping (uint8 => string) q;
        q[0x63] = "make cc";
        q[0x75] = "make up_" + SELF;
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

    function _sv(string[] list, uint n) internal pure returns (string) {
        return list[n < list.length && n > 0 ? n - 1 : 0];
    }
//    function from_handle(uint h) external pure returns (uint n, uint t, uint c, uint f, uint o, uint a) {
//        return _from_handle(h);
//    }
    function _from_handle(uint h) internal pure returns (uint8 n, uint8 t, uint8 c, uint8 f, uint8 o, uint8 a) {
        return (uint8(h & 0xFF), uint8(h >> 8 & 0xFF), uint8(h >> 16 & 0xFF), uint8(h >> 24 & 0xFF), uint8(h >> 32 & 0xFF), uint8(h >> 40 & 0xFF));
    }
//    function to_handle(uint n, uint t, uint c, uint f, uint o, uint a) external pure returns (uint h) {
//        return _to_handle(n, t, c, f, o, a);
//    }
    function _to_handle(uint n, uint t, uint c, uint f, uint o, uint a) internal pure returns (uint h) {
        return n + (t << 8) + (c << 16) + (f << 24) + (o << 32) + (a << 40);
    }

}

