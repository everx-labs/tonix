pragma ton-solidity >= 0.68.0;
import "common.h";
import "libstr.sol";

contract tup is common {

    string constant SELF = "tup";
    bytes constant QUICKS = "cCuUhHbBqQwWeExXzZ,.<>";
//    string constant CONFIG_FILE = "default.cfg";
//    string constant E = "\\033[";
//    string constant ECHO = "echo -en '" + E;

    enum MENU { MAIN, SETUP, INSTALL, RUN, VIEW, LAST }

    uint8 constant SETTINGS_FIRST   = 3;
    uint8 constant SETTINGS_UI      = SETTINGS_FIRST;
    uint8 constant SETTINGS_KEY     = SETTINGS_FIRST + 1;
    uint8 constant SETTINGS_DEV     = SETTINGS_FIRST + 2;
    uint8 constant SETTINGS_LAST    = SETTINGS_DEV;
    uint8 constant SETTINGS_COUNT   = SETTINGS_LAST - SETTINGS_FIRST + 1;

    string[][] constant MCS = [
        ["Preferences", "Setup", "Install", "Run", "View", "Path"],
        ["Setup", "Tools", "Path"],
        ["Install", "Setup", "Runtime"],
        ["Run", "Setup", "Config"],
        ["View", "Path"],
        ["Path", "/bin", "/sbin", "/usr/bin", "/usr/sbin"]
    ];

    function draw(uint h, uint v) external view returns (string cmd) {
        return _draw(h, v);
    }

    function _echo(string s) internal pure returns (string) {
        return "echo -en '" + s + "'\n";
    }

    function _eseq(string[] ss) internal pure returns (string out) {
        for (string s: ss)
            out.append("\\033[" + s);
    }
    function _e(string s) internal pure returns (string) {
        return "\\033[" + s;
    }

    function _draw_list(string[] list, uint x, uint y, uint sel, uint voff, string[] vals) internal pure returns (string s) {
        s = _e(format("{};{}H{}", y, x, list[0])) + _e("E");
        string next = _e("E") + (x > 1 ? _e(format("{}C", x - 1)) : "");
        string sval = voff > 0 ? ":" + _e(format("{}G", voff)) : "";
        for (uint i = 1; i < list.length; i++)
            s.append(
                next +
                (sel == i ? _e("30;47m") + list[i] + _e("0m") : list[i]) +
                (sval.empty() ? "" : sval + vals[i - 1]));
    }

    function exec(uint h, uint v) external pure returns (string cmd) {
        (, , uint ctx, uint itm, uint arg, ) = _from_handle(h);
        v;arg;

        if (ctx == 1) {
            if (itm == 1)
                cmd = "make -s tools;";
            else if (itm == 2)
                cmd = "mkdir -p bin sbin usr/bin usr/sbin;";
        } else if (ctx == 2) {
            if (itm == 1)
                cmd = "make -C opt/mesh install;";
//            else if (itm == 2)
//                cmd = "cd opt/mesh;make install;";
        } else if (ctx == 3) {
            if (itm == 1)
                cmd = "cd opt/mesh;make setup;";
            else if (itm == 2)
                cmd = "cd opt/mesh;make run;";
        } else if (ctx == 4) {
            if (itm == 1)
                cmd = "printf /bin:/sbin:/usr/bin:/usr/sbin";
        } else if (ctx == 5) {
            if (itm == 1)
                cmd = "ls bin;";
            else if (itm == 2)
                cmd = "ls sbin;";
            else if (itm == 3)
                cmd = "ls usr/bin;";
            else if (itm == 4)
                cmd = "ls usr/sbin;";
        }
        if (!cmd.empty())
            cmd = _echo(_e("16;3H")) + cmd;
    }

    function _draw_roundish_bound(uint x, uint y, uint w, uint h) internal pure returns (string s) {
        string hl;
        repeat (w - 2)
            hl.append("\u2500");                                    // ───
        string vb = _e("E\u2502") + _e(format("{}G\u2502", w));     // │ │

        s.append(_e(format("{};{}H\u256D", y, x)) + hl + "\u256E"); // ╭─╮
        repeat (h - 2)                                              // │ │
            s.append(vb);                                           // │ │
        s.append(_e("E\u2570") + hl + "\u256F");                    // ╰─╯
    }
    function _draw(uint h, uint v) internal view returns (string cmd) {
        v;
        (, , uint ctx, uint itm, uint arg, ) = _from_handle(h);
        string s = _e("2J") + _draw_roundish_bound(1, 1, 40, 12);
        string[] vals;

        if (ctx > 0)
            s.append(_draw_list(MCS[uint(MENU.MAIN)], 4, 3, ctx, 0, vals));
        if (itm > 0)
            s.append(_draw_list(MCS[ctx], 15, 3, itm, 0, vals));
        s.append(arg > 0 ? _e(format("{};{}H", 1 + arg, 70)) : _e("?25l"));
        return _echo(s);
    }
    function _help(uint n, uint h) internal pure returns (string out) {
        n;h;
        out = "Quick commands:\n\n'c':  Compile the project\n'u':  Update the smart-contract code in the blockchain\n'x':  Show debug commands\n'z':  Hide debug commands\n'b':  Go back to the parent menu\n'q':  Quit\n";
    }

    function ona(uint h, uint vin, string s) external view returns (uint hout, uint vout, string out, string cmd) {
        vout = vin;
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);

        bytes bb = bytes(s);
        uint len = bb.length;
        bytes1 b0 = len > 0 ? bytes(s)[0] : bytes1(0x20);
        bytes1 b1 = len > 1 ? bytes(s)[1] : bytes1(0x20);
        bytes1 b2 = len > 2 ? bytes(s)[2] : bytes1(0x20);
        uint8 v0 = uint8(b0);
        uint8 v1 = uint8(b1);
        uint8 v2 = uint8(b2);

        out.append(s);
        out.append(format("{} {} {}", v0, v1, v2));

        if (len == 0) {
            cmd.append("eval \"$R exec --h $h --v $v\" | jq -r .cmd >tmp/sx && source tmp/sx;");
            return (h, vin, "", cmd);
        }
        if (v0 == 0x1B) {
            if (v1 == 0x5B) {   // Handle arrow keys
                if (v2 == 0x41) {   // Up
                    if (arg > 0) {
                        if (arg > 1)
                            arg--;
                    } else if (itm > 0) {
                        if (itm > 1)
                            itm--;
                    } else if (ctx > 0)
                        ctx--;
                } else if (v2 == 0x42) { // Down
                    if (arg > 0) {
                        if (arg + 1 < MCS[SETTINGS_FIRST + itm - 1].length)
                            arg++;
                    } else if (itm > 0) {
                        if (itm < SETTINGS_COUNT)
                            itm++;
                    } else if (ctx < uint(MENU.LAST))
                        ctx++;
                } else if (v2 == 0x43) { // Right: expand the highlighted menu item
                    if (itm > 0)
                        arg = 1;
                    else if (ctx > 0)
                        itm = 1;
                    else
                        ctx++;
                } else if (v2 == 0x44) { // Left: collapse the open menu
                    if (arg > 0)
                        arg = 0;
                    else if (itm > 0)
                        itm = 0;
                    else
                        ctx = 0;
                } else if (v2 == 0x46)
                    cmd.append("make -s -C opt/mesh up_" + SELF + " >" + SELF + "_up;");
                else if (v2 == 0x48)
                    cmd.append("make -s -C opt/mesh cc;");
            }

        }
        if (v0 == 0x62 || v1 == 0x48) { // 'b' key: collapse the open menu
            if (arg > 0)
                arg = 0;
            else if (itm > 0)
                itm = 0;
            else
                ctx = 0;
        } else if (s == "[") {  // Space: toggle the current box item, or expand the highlighted menu item
            if (arg > 0) {
                uint bit_mask = 1 << (itm + 1) * 8 + arg - 1;
                vout = vin ^ bit_mask;
            } else {
                if (itm > 0)
                    arg = 1;
                else if (ctx > 0)
                    itm = 1;
            }
        } else if (s == "|") {
                if (itm > 0)
                    arg = 1;
                else if (ctx > 0)
                    itm = 1;
        }
        hout = _to_handle(idev, ct, ctx, itm, arg, val);
        cmd.append("eval \"$R draw --h $h --v $v\" | jq -r .cmd >tmp/sdr && source tmp/sdr;");
    }

    function _quick_command(uint8 v) internal pure returns (string cmd) {
        mapping (uint8 => string) q;
        q[0x63] = "make cc";                // 'c': compile the project sources
        q[0x75] = "make up_" + SELF;        // 'u': update the code in the blockchain
        q[0x71] = _echo(_e("?25h Bye!")) + "exit 0;";    // 'q': quit
        q[0x78] = "set -x";                 // 'x': show debug commands
        q[0x7A] = "set +x";                 // 'z': hide debug commands
        return q.exists(v) ? q[v] : "echo Unrecognized quick command";
    }
}
