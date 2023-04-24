pragma ton-solidity >= 0.67.0;
import "common.h";
import "libstr.sol";

contract settings is common {

    string constant SELF = "settings";
    bytes constant QUICKS = "cCuUhHbBqQwWeExXzZ";
    string constant CONFIG_FILE = "default.cfg";

    enum MENU { MAIN, SELECT, CONFIG, LAST }
    string[][] constant MCS = [
        ["Preferences", "Settings", "Configure"],
        ["Settings", "Generation", "Other"],
        ["Configuration", "Save settings", "Load settings"],
        ["Generation settings", "Structure type definitions", "Enum type definitions", "Type printing functions",
            "Terse printing format", "Verbose printing format", "Helper contract encoders", "Print cell by type index"],
        ["Other settings", "Other 1", "Other 2", "Other 3", "Other 4", "Other 5"]
    ];

    function _fill_vals(uint itm, uint v) internal view returns (string out) {
        string[] opts = MCS[itm + uint(MENU.LAST) - 1];
        uint len = opts.length;
        if (len > 0)
           out.append(opts[0] + "\n\n");
        v = v >> 8 * itm;
        uint shift = 1;
        for (uint i = 1; i < len; i++) {
            out.append(format("{}) {}:\t[{}]\n", i, opts[i], (v & shift) > 0 ? "X" : " "));
            shift <<= 1;
        }
    }
    function _help(uint n, uint h) internal pure returns (string out) {
        out = "Quick commands:\n\n'c':  Compile the project\n'u':  Update the smart-contract code in the blockchain\n'x':  Show debug commands\n'z:  Hide debug commands\n'b':  Go back to the parent menu\n'0':  Print the current context menu\n'q':  Quit\n";
        if (n == 1) {
            h;
        }
    }
    function _config(uint n, uint h) internal pure returns (string cmd) {
        h;
        if (n == 1) {
            cmd = "jq -r .vout $of >" + CONFIG_FILE + " && echo Configuration saved to " + CONFIG_FILE + "\n";
        } else if (n == 2) {
            cmd = "v=`cat " + CONFIG_FILE + "` && echo Loaded configuration from " + CONFIG_FILE + "\n";
        }
    }
    function onc(uint h, uint vin, string s) external view returns (uint hout, uint vout, string cmd, string out) {
        if (s.empty())
            return (h, vin, cmd, out);
        vout = vin;
        bytes1 b0 = bytes(s)[0];
        uint8 v = uint8(b0);
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        MENU ectx = MENU(ctx);
        uint8 n;
        if (libstr.strchr(QUICKS, b0) > 0) {    // quick command
            if (v >= 0x41 && v <= 0x5A)         // convert a letter to lowercase
                v += 0x20;
            if (v == 0x62) {                    // 'b': go back to the parent menu
                if (itm > 0)
                    itm = 0;
                else
                    ectx = MENU.MAIN;
            } else if (v == 0x68)               // 'h': help
                out.append(_help(ctx, h));
            else                                // execute a quick command
                cmd.append(_quick_command(v));
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            n = v - 0x30;                       // digit ascii to its numerical value
            if (ectx == MENU.MAIN)              // we're in the main manu, switch context to a sub-menu
                ectx = MENU(n);
            else if (ectx == MENU.SELECT) {     // change configs settings
                if (itm == 0)                   // no config is active yet, switch to the selected one
                    itm = n;
                else                            // toggle the selected flag value minding the active context
                    vout = vin ^ (1 << itm * 8 + n - 1);
                out.append(_fill_vals(itm, vout));
            } else if (ectx == MENU.CONFIG)
                cmd = _config(n, h);
        } else
            out.append("Press 'h' for help\n");
        if (ectx != MENU(ctx) || n == 0)        // '0' prints current menu
            out.append(print_menu(ectx));
        if (hout == 0)
            hout = _to_handle(idev, ct, uint(ectx), itm, arg, val);
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
    function print_menu(MENU n) internal view returns (string out) {
        return print_list_menu(MCS[uint(n < MENU.LAST ? n : MENU.MAIN)]);
    }
    function print_list_menu(string[] items) internal pure returns (string out) {
        uint len = items.length;
        if (len > 0)
            out.append(items[0] + "\n\n");
        for (uint i = 1; i < len; i++)
            out.append(format("{}) {}\n", i, items[i]));
    }
}
