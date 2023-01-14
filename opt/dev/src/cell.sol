pragma ton-solidity >= 0.64.0;

import "ged.sol";
import "libctl.sol";
contract cell is ged {

    uint32 _flags;// = libctl.UNITS_BITS;

    constructor(device_t pdev) public ged(pdev) {
        tvm.accept();
    }

    function encode_ctl(string name, string desc, uint8 ctype, uint8 size, uint8 max, uint8 def, uint8 off, uint32 mask) external pure returns (TvmCell c) {
        return libctl.encode(name, desc, ctype, size, max, def, off, mask);
    }

    function export_ctls() external view returns (TvmCell[] cs) {
        for ((uint32 addr, TvmCell c): _mem)
            if (addr < 0xFFFF && addr >> 8 & 0xFF == libctl.CTL_OFFSET)
                cs.push(c);
    }

    function _fetch_ctls() internal view returns (TvmSlice[] ss) {
        for ((uint32 addr, TvmCell c): _mem)
            if (addr < 0xFFFF && addr >> 8 & 0xFF == libctl.CTL_OFFSET)
                ss.push(c.toSlice());
    }
    function print_ctls() external view returns (string out) {
        return libctl.print_ctls(_fetch_ctls());
    }

    function parse_ctl(TvmCell c) external pure returns (string name, string desc, uint8 ctype, uint8 size, uint8 max, uint8 def, uint8 off, uint32 mask) {
        return libctl.parse(c.toSlice());
    }

    function ctl(string cmd, string arg, string val) external view returns (string out) {
        if (cmd == "set") {
            (uint off, uint mask) = libctl.parse_stat(arg);
            if (mask > 0) {
                uint v = libctl.parse_count(val);
                uint f = _flags;
                uint prev = (f & mask) >> off;
                if (prev != v) {
                    f &= ~uint32(mask);
                    f |= uint32(v << off);
                }
                return format("SUCCESS: off {} mask {} {} -> {}\n", off, mask, _flags, f);
            } else
                return "unknown stat: " + arg;
        } else if (cmd == "view") {
            TvmSlice[] ss = _fetch_ctls();
            if (arg == "flags") {
                TvmSlice[] sf = libctl.filter(ss, val, libctl.TYPE_VALUE);
                if (!sf.empty()) {
                    (string name, string desc, , , , , uint8 off, ) = libctl.parse(sf[0]);
                    uint f = _flags;
                    uint mask = uint(0x03) << off;
                    uint cur = (f & mask) >> off;
                    out.append(format("{} / {} : cur {}\n", name, desc, cur));
                    return out + libctl.print_ctls(sf);
                }
            } else if (arg == "stat") {
                TvmSlice[] sf = libctl.filter(ss, val, libctl.TYPE_STAT);
                return libctl.print_ctls(sf);
            } else if (arg == "attr") {
                TvmSlice[] sf = libctl.filter(ss, val, libctl.TYPE_ATTR);
                return libctl.print_ctls(sf);
            } else if (arg == "display") {
                TvmSlice[] sf = libctl.filter(ss, val, libctl.TYPE_DISPLAY);
                return libctl.print_ctls(sf);
            } else if (arg == "value") {
                TvmSlice[] sf = libctl.filter(ss, val, libctl.TYPE_VALUE);
                if (!sf.empty()) {
                    (, , , uint8 size, , uint8 def, uint8 off, ) = libctl.parse(sf[0]);
                    uint f = _flags;
                    uint mask = uint(0x03) << off;
                    uint cur = (f & mask) >> off;
                    uint vdef = uint(def) << off;

                    return format("Size {} Def {} offset {} flags {} mask {} cur {} vdef {}\n", size, def, off, f, mask, cur, vdef);
                }
                return libctl.print_ctls(sf);
            }
        } else if (cmd == "show") {
            TvmSlice[] ss = _fetch_ctls();
            if (arg == "ctl")
                return libctl.print_ctls(libctl.filter(ss, val, 0));
            else if (arg == "type") {
                TvmSlice[] sf = libctl.filter(ss, val, 0);
                if (!sf.empty()) {
                    (, , uint8 nt, , , , , ) = libctl.parse(sf[0]);
                    if (nt > 0) {
                        sf = libctl.filter(ss, "", nt);
                        return libctl.print_ctls(sf);
                    }
                }
            } else
                return "unrecognized argument: " + arg;
        }
            return "unknown command: " + cmd;
    }

    function conf(uint32 val) external {
        tvm.accept();
        _flags = val;
    }

}

