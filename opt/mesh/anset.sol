pragma ton-solidity >= 0.67.0;
import "common.h";
import "libstr.sol";

contract anset is common {

    string constant SELF = "anset";
    bytes constant QUICKS = "cCuUhHbBqQwWeExXzZ,.<>";
    string constant CONFIG_FILE = "default.cfg";
    string constant E = "\\033[";
    string constant ECHO = "echo -en '" + E;

    enum MENU { MAIN, SELECT, CONFIG, LAST }

    uint8 constant SETTINGS_FIRST   = 3;
    uint8 constant SETTINGS_UI      = SETTINGS_FIRST;
    uint8 constant SETTINGS_KEY     = SETTINGS_FIRST + 1;
    uint8 constant SETTINGS_DEV     = SETTINGS_FIRST + 2;
    uint8 constant SETTINGS_LAST    = SETTINGS_DEV;
    uint8 constant SETTINGS_COUNT   = SETTINGS_LAST - SETTINGS_FIRST + 1;

    string[][] constant MCS = [
        ["Preferences", "Settings", "Configure"],
        ["Settings", "UI settings", "Hotkeys", "Developer mode"],
        ["Configuration", "Save to file", "Load from file"],
        ["UI settings", "Enable hotkeys", "Debug printouts", "Developer mode"],
        ["Keyboard shortcuts", "Parent menu", "Display help", "Debug on", "Debug off", "Quit shell", "Compile source", "Update code", "Display help"],
        ["Developer features", "Compilation", "Code upload", "Debug commands"]
    ];

    function _echo(string s) internal pure returns (string) {
        return ECHO + s + "'\n";
    }

    function _eseq(string[] ss) internal pure returns (string out) {
        for (string s: ss)
            out.append("\\033[" + s);
    }
    function _e(string s) internal pure returns (string) {
        return E + s;
    }
    function enc(uint h, uint v) external pure returns (TvmCell c) {
        (, , uint ctx, , , ) = _from_handle(h);
        if (ctx == uint(MENU.CONFIG)) {
            c = abi.encode(v);
        }
    }

    function _draw_list(string[] list, uint x, uint y, uint sel, uint voff, string[] vals) internal pure returns (string s) {
        s.append(_e(format("{};{}H", y, x) + list[0]) + _e(y == 1 ? "2J" : "E"));
        string next = y > 1 ? _e("E") : "";
        string sval = voff > 0 ? ":" + _e(format("{}G", voff)) : "";
        if (x > 1)
            next.append(_e(format("{}C", x - 1)));
        for (uint i = 1; i < list.length; i++) {
            s.append(next);
            string sitm = format("{}) {}", i, list[i]);
            s.append(sel == i ? _e("30;47m") + sitm + _e("0m") : sitm);
            if (!sval.empty())
                s.append(sval + vals[i - 1]);
        }
    }
    function draw(uint h, uint v) external view returns (string cmd) {
        return _draw(h, v);
    }

    function _draw(uint h, uint v) internal view returns (string cmd) {
        (, , uint ctx, uint itm, uint arg, ) = _from_handle(h);
        string s;
        string[] vals;
        if (ctx > 0) {
            s.append(_draw_list(MCS[uint(MENU.MAIN)], 8, 1, ctx, 0, vals));
            s.append(_draw_list(MCS[uint(MENU.MAIN)], 1, 3, ctx, 0, vals));
        }
        if (itm > 0)
            s.append(_draw_list(MCS[ctx], 18, 3, itm, 0, vals));
        if (arg > 0) {
            v = v >> 8 * (itm + 1);
            if (itm == SETTINGS_KEY - SETTINGS_FIRST + 1)
                vals = ["b", "h", "x", "z", "q", "c", "u", "h"];
            else {
                for (uint i = 1; i < MCS[itm + SETTINGS_UI - 1].length; i++)
                    vals.push(format("[{}]", (v >> (i - 1) & 1) > 0 ? "X" : " "));
            }
            s.append(_draw_list(MCS[itm + SETTINGS_UI - 1], 39, 3, arg, 60, vals));
        }
        s.append(_eseq(["0m", "0J"]));
        s.append(arg > 0 ? _e(format("{};{}H", 1 + arg, 70)) : _e("?25l"));
        cmd = "echo -en '" + s + "'\n";
    }
    function _help(uint n, uint h) internal pure returns (string out) {
        out = "Quick commands:\n\n'c':  Compile the project\n'u':  Update the smart-contract code in the blockchain\n'x':  Show debug commands\n'z':  Hide debug commands\n'b':  Go back to the parent menu\n'0':  Print the current context menu\n'q':  Quit\n";
        if (n == 1) {
            h;
        }
    }
    function _config(uint n) internal pure returns (string cmd) {
        if (n == 1)
            cmd = "jq -r .vout $of >" + CONFIG_FILE + " && echo Configuration saved to " + CONFIG_FILE;
        else if (n == 2)
            cmd = "v=`cat " + CONFIG_FILE + "` && echo Loaded configuration from " + CONFIG_FILE;
    }

    function ona(uint h, uint vin, string s) external view returns (uint hout, uint vout) {
        vout = vin;
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);

        bytes bb = bytes(s);
        uint len = bb.length;
        bytes1 b0 = len > 0 ? bytes(s)[0] : bytes1(0x20);
        bytes1 b1 = len > 1 ? bytes(s)[1] : bytes1(0x20);
        uint8 v0 = uint8(b0);
        uint8 v1 = uint8(b1);

        if (v0 == 0x5B) { // Handle arrow keys
            if (v1 == 0x41) {   // Up
                if (arg > 0) {
                    if (arg > 1)
                        arg--;
                } else if (itm > 0) {
                    if (itm > 1)
                        itm--;
                } else if (ctx > 0)
                    ctx--;
            } else if (v1 == 0x42) { // Down
                if (arg > 0) {
                    if (arg + 1 < MCS[SETTINGS_FIRST + itm - 1].length)
                        arg++;
                } else if (itm > 0) {
                    if (itm < SETTINGS_COUNT)
                        itm++;
                } else if (ctx > 0) {
                    itm = 1;
                }
            } else if (v1 == 0x43) { // Right: expand the highlighted menu item
                if (itm > 0)
                    arg = 1;
                else if (ctx > 0)
                    itm = 1;
            } else if (v1 == 0x44) { // Left: collapse the open menu
                if (arg > 0)
                    arg = 0;
                else if (itm > 0)
                    itm = 0;
                else
                    ctx = 0;
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
        }
        hout = _to_handle(idev, ct, ctx, itm, arg, val);
    }
    function onc(uint h, string s) external pure returns (uint hout, string cmd) {
        bytes1 b0 = s.empty() ? bytes1(0x20) : bytes(s)[0];
        uint8 v = uint8(b0);

        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        if (v == 0x1b || v == 0x62 || v == 0x20) {
            hout = h;
            if (v == 0x1b)
                cmd.append("read -rsn2 j;eval \"$R ona --h $h --vin $v --s '$j'\"");
            else if (v == 0x62 || v == 0x20) {
                if (v == 0x20)
                    s = "[" + s;
                cmd.append("eval \"$R ona --h $h --vin $v\" --s \"" + s + "\"");
            }
            cmd.append(" >tmp/ona.res;h=`jq -r .hout tmp/ona.res`;v=`jq -r .vout tmp/ona.res`;");
            cmd.append("eval \"$R draw --h $h --v $v\" | jq -r .cmd >tmp/sdr && source tmp/sdr;");
            return (hout, cmd);
        }

        MENU ectx = MENU(ctx);

        if (libstr.strchr(QUICKS, b0) > 0) {    // quick command
            if (v >= 0x41 && v <= 0x5A)         // convert a letter to lowercase
                v += 0x20;
            else if (v >= 0x3C && v <= 0x3F)    // strip "shift" modifier
                v -= 0x10;
            if (v == 0x68)               // 'h': help
                cmd = _echo("29;H" + _e("0J") + _help(itm, h));
            else if (v == 0x2C && ectx > MENU.MAIN)
                ectx = MENU(ctx - 1);
            else if (v == 0x2E && ectx < MENU.LAST)
                ectx = MENU(ctx + 1);
            else                                // execute a quick command
                cmd = _quick_command(v) + "\n";
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            uint8 n = v - 0x30;                       // digit ascii to its numerical value
            if (arg > 0)
                arg = n;
            else if (itm > 0)
                itm = n;
            else
                ectx = MENU(n);
        } else
            cmd = _echo("39;HPress \"h\" for help");
        hout = _to_handle(idev, ct, uint(ectx), itm, arg, val);
    }

    function _quick_command(uint8 v) internal pure returns (string cmd) {
        mapping (uint8 => string) q;
        q[0x63] = "make cc";                // 'c': compile the project sources
        q[0x75] = "make up_" + SELF;        // 'u': update the code in the blockchain
        q[0x71] = _echo("?25h Bye!") + "exit 0;";    // 'q': quit
        q[0x78] = "set -x";                 // 'x': show debug commands
        q[0x7A] = "set +x";                 // 'z': hide debug commands
        return q.exists(v) ? q[v] : "echo Unrecognized quick command";
    }
}
