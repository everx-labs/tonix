pragma ton-solidity >= 0.67.0;
import "common.h";
import "libstr.sol";

contract anset is common {

    string constant SELF = "anset";
    bytes constant QUICKS = " cCuUhHbBqQwWeExXzZ,.<>";
    string constant CONFIG_FILE = "default.cfg";
    string constant E = "\\033[";
    string constant ECHO = "echo -e '" + E;

    enum MENU { MAIN, SELECT, CONFIG, LAST }
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
    function _fill_tvals(uint itm, uint h, uint v) internal view returns (string cmd) {
        h;
        string[] opts = MCS[itm];
        uint len = opts.length;
        if (len == 0)
            return _echo("5mEmpty...");
        bool has_values = itm >= uint(MENU.LAST);
        bool horiz = itm == uint(MENU.MAIN);
        uint x = has_values ? 25 : 1;
        uint y = horiz ? 1 : has_values ? 5 : 3;
        string next;

        cmd = ECHO + format("{};H", y);
        if (has_values)
            v = v >> 8 * (itm - uint(MENU.LAST) + 1);
        else
            cmd.append(_e("0J"));

        if (horiz) {
            cmd.append(_e("37;44m"));
            next = _e("10C");
        } else {
            next = _e("E");
            if (has_values)
                next.append(_e("25C"));
        }

        if (!has_values)
            cmd.append(_e(";K"));

        cmd.append(_e(format("{};{}H{}", y, x, opts[0])));
        if (!horiz)
            cmd.append(_e("E"));

        for (uint i = 1; i < len; i++) {
            cmd.append(next + format("{}) {}", i, opts[i]));
            if (has_values)
                cmd.append(":" + _e(format("50G[{}]", (v >> (i - 1) & 1) > 0 ? "X" : " ")));
        }

        cmd.append(_eseq(["0m", "0J"]) + "'\n");
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

    function onc(uint h, uint vin, string s) external view returns (uint hout, uint vout, string cmd) {
        vout = vin;
        bytes1 b0 = s.empty() ? bytes1(0x20) : bytes(s)[0];
        uint8 v = uint8(b0);
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        MENU ectx = MENU(ctx);
        uint8 n;
        uint fill = 0xBAD;

        if (libstr.strchr(QUICKS, b0) > 0) {    // quick command
            if (v >= 0x41 && v <= 0x5A)         // convert a letter to lowercase
                v += 0x20;
            else if (v >= 0x3C && v <= 0x3F)    // strip "shift" modifier
                v -= 0x10;
            if (v == 0x62) {                    // 'b': go back to the parent menu
                if (itm > 0) {
                    itm = 0;
                    fill = ctx;
                } else
                    ectx = MENU.MAIN;
            } else if (v == 0x68)               // 'h': help
                cmd = _echo("29;H" + _e("0J") + _help(itm, h));
            else if (v == 0x2C && ectx > MENU.MAIN)
                ectx = MENU(ctx - 1);
            else if (v == 0x2E && ectx < MENU.LAST)
                ectx = MENU(ctx + 1);
            else                                // execute a quick command
                cmd = _quick_command(v);
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            n = v - 0x30;                       // digit ascii to its numerical value
            if (ectx == MENU.MAIN) {            // we're in the main manu, switch context to a sub-menu
                ectx = MENU(n);
            } else if (ectx == MENU.SELECT) {   // change configs settings
                if (itm == 0) {                 // no config is active yet, switch to the selected one
                    itm = n;
                    fill = itm + uint(MENU.LAST) - 1;
                } else {                        // toggle the selected flag value minding the active context
                    uint bit_mask = 1 << itm * 8 + n - 1;
                    vout = vin ^ bit_mask;
                    cmd = _echo(format("{};51H{}", 6 + n, (vout & bit_mask) > 0 ? "X" : " "));
                }
            } else if (ectx == MENU.CONFIG)
                cmd = _config(n);
        } else
            cmd = _echo("39;HPress \"h\" for help");
        if (ectx != MENU(ctx)) {
            fill = uint(ectx);
            itm = 0;
        }
        if (hout == 0)
            hout = _to_handle(idev, ct, uint(ectx), itm, arg, val);
        if (fill != 0xBAD) {
            cmd = _fill_tvals(fill, hout, vout) + cmd;
        }
    }

    function _quick_command(uint8 v) internal pure returns (string cmd) {
        mapping (uint8 => string) q;
        q[0x63] = "make cc";                // 'c': compile the project sources
        q[0x75] = "make up_" + SELF;        // 'u': update the code in the blockchain
        q[0x71] = "echo Bye! && exit 0";    // 'q': quit
        q[0x78] = "set -x";                 // 'x': show debug commands
        q[0x7A] = "set +x";                 // 'z': hide debug commands
        return q.exists(v) ? q[v] : "echo Unrecognized quick command";
    }
}
