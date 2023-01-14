pragma ton-solidity >= 0.64.0;

import "libtable.sol";

library libctl {

    uint8 constant UNITS_NONE  = 1;
    uint8 constant UNITS_BITS  = 2;
    uint8 constant UNITS_BYTES = 3;

    uint8 constant CONTROL_NONE = 0;
    uint8 constant CONTROL_CELL = 1;

    uint8 constant COMMAND_NONE = 0;
    uint8 constant COMMAND_SET = 1;
    uint8 constant COMMAND_VIEW = 2;
    uint8 constant COMMAND_SHOW = 3;

    uint8 constant ATTR_NONE = 0;
    uint8 constant ATTR_TYPE = 1;
    uint8 constant ATTR_SIZE = 2;
    uint8 constant ATTR_MAX = 3;
    uint8 constant ATTR_DEF = 4;
    uint8 constant ATTR_OFFSET = 5;
    uint8 constant ATTR_MASK = 6;
    uint8 constant ATTR_VALUE = 7;

    uint8 constant DISPLAY_NONE = 0;
    uint8 constant DISPLAY_CURR = 1;
    uint8 constant DISPLAY_TOTAL = 2;
    uint8 constant DISPLAY_FULL = 3;

    uint8 constant COUNT_NONE = 0;
    uint8 constant COUNT_CURR = 1;
    uint8 constant COUNT_TOTAL = 2;
    uint8 constant COUNT_FULL = 3;

    uint8 constant UNITS_OFF = 2;
    uint8 constant TAIL_OFF = 4;
    uint8 constant CELLS_OFF = 8;
    uint8 constant REFS_OFF  = 10;
    uint8 constant SIZE_OFF  = 12;
    uint8 constant DEPTH_OFF = 14;
    uint32 constant UNITS_MASK = uint32(0x03) << UNITS_OFF;
    uint32 constant TAIL_MASK = uint32(0x03) << TAIL_OFF;
    uint32 constant CELLS_MASK = uint32(0x03) << CELLS_OFF;
    uint32 constant REFS_MASK  = uint32(0x03) << REFS_OFF;
    uint32 constant SIZE_MASK  = uint32(0x03) << SIZE_OFF;
    uint32 constant DEPTH_MASK = uint32(0x03) << DEPTH_OFF;

    uint8 constant CTL_NONE = 0;
    uint8 constant CTL_NUMBER = 1;
    uint8 constant CTL_STAT = 2;
    uint8 constant CTL_OFFSET = 3;
    uint8 constant CTL_MASK = 4;
    uint8 constant CTL_VALUE = 5;

    uint8 constant TAIL_NONE  = 0;
    uint8 constant TAIL_BRIEF = 1;
    uint8 constant TAIL_COLLAPSE = 2;
    uint8 constant TAIL_FULL = 3;

    uint8 constant TYPE_NONE = 0;
    uint8 constant TYPE_CONTROL = 1;
    uint8 constant TYPE_COMMAND = 2;
    uint8 constant TYPE_STAT = 3;
    uint8 constant TYPE_ATTR = 4;
    uint8 constant TYPE_DISPLAY = 6;
    uint8 constant TYPE_VALUE = 7;
    uint8 constant TYPE_OPTION = 8;

    uint8 constant STAT_NONE = 0;
    uint8 constant STAT_CELLS = 1;
    uint8 constant STAT_REFS = 2;
    uint8 constant STAT_SIZE = 3;
    uint8 constant STAT_DEPTH = 4;

    function show_size(uint sz) internal returns (string out) {
        if (sz == UNITS_NONE) return "none";
        if (sz == UNITS_BITS) return "bits";
        if (sz == UNITS_BYTES) return "bytes";
        return "undefined";
    }
    function parse_stat(string val) internal returns (uint, uint) {
        if (val == "units") return (UNITS_OFF, UNITS_MASK);
        if (val == "tail") return (TAIL_OFF, TAIL_MASK);
        if (val == "cells") return (CELLS_OFF, CELLS_MASK);
        if (val == "refs") return (REFS_OFF, REFS_MASK);
        if (val == "size") return (SIZE_OFF, SIZE_MASK);
        if (val == "depth") return (DEPTH_OFF, DEPTH_MASK);
    }
    function parse_count(string val) internal returns (uint) {
        if (val == "none") return COUNT_NONE;
        if (val == "current") return COUNT_CURR;
        if (val == "total") return COUNT_TOTAL;
        if (val == "full") return COUNT_FULL;
    }
    function show_count(uint val) internal returns (string out) {
        if (val == COUNT_NONE) return "none";
        if (val == COUNT_CURR) return "current";
        if (val == COUNT_TOTAL) return "total";
        if (val == COUNT_FULL) return "full";
        return "undefined";
    }
    function print_count(string sym, uint val, uint cur) internal returns (string out) {
        if (val == COUNT_NONE)
            return "";
        if (val >= COUNT_CURR && val <= COUNT_FULL)
            return sym + format("{}", cur);
//        if (val == COUNT_TOTAL) return out + format("{}", total);
//        if (val == COUNT_FULL) return out + format("{}/{}", cur, total);
//        return "undefined";
    }
    function print_count(string sym, uint val, uint cur, uint total) internal returns (string out) {
        if (val == COUNT_NONE) return "";
        out = sym;
        if (val == COUNT_CURR) return out + format("{}", cur);
        if (val == COUNT_TOTAL) return out + format("{}", total);
        if (val == COUNT_FULL) return out + format("{}/{}", cur, total);
        return "undefined";
    }

    function as_row(TvmSlice s) internal returns (string[]) {
        (string name, string desc, uint8 ctype, uint8 size, uint8 max, uint8 def, uint8 off, uint32 mask) = parse(s);
        return [name, str.toa(ctype), str.toa(size), str.toa(max), str.toa(def), str.toa(off), str.toa(mask), desc];
    }
    function print_ctls(TvmSlice[] ss) internal returns (string out) {
        if (ss.empty())
            return "No controls";
        string[][] rows = [["name", "type", "size", "max", "def", "off", "mask", "desc"]];
        for (TvmSlice s: ss)
            rows.push(as_row(s));
        return libtable.table_view([uint(12), 5, 4, 3, 3, 3, 9, 30], libtable.CENTER, rows);
    }
    function parse(TvmSlice s) internal returns (string name, string desc, uint8 ctype, uint8 size, uint8 max, uint8 def, uint8 off, uint32 mask) {
        (name, desc, ctype, size, max, def, off, mask) = s.decode(string, string, uint8, uint8, uint8, uint8, uint8, uint32);
    }
    function encode(string name, string desc, uint8 ctype, uint8 size, uint8 max, uint8 def, uint8 off, uint32 mask) internal returns (TvmCell c) {
        TvmBuilder b;
        b.store(name, desc, ctype, size, max, def, off, mask);
        return b.toCell();
    }
    function filter(TvmSlice[] ss, string name, uint8 t) internal returns (TvmSlice[] sf) {
        for (TvmSlice s: ss) {
            (string cname, , uint8 ctype, , , , , ) = libctl.parse(s);
            if (str.strstr(cname, name) > 0 && (t == 0 || t == ctype))
                sf.push(s);
        }
    }
    function flag_value(TvmSlice[] ss, uint stg, uint ord) internal returns (uint val) {
        if (ord < ss.length) {
            (, , , , , , uint8 off, ) = libctl.parse(ss[ord]);
            uint mask = uint(0x03) << off;
            uint cur = (stg & mask) >> off;
            return cur;
        }
    }
    function flag_values(TvmSlice[] ss, uint stg) internal returns (uint[] vals) {
        for (uint i = 1; i < ss.length; i++) {
            (, , , , , , uint8 off, ) = libctl.parse(ss[i]);
            uint mask = uint(0x03) << off;
            uint cur = (stg & mask) >> off;
            vals.push(cur);
        }
    }

    function option_values(uint[] offs, uint stg) internal returns (uint v1, uint v2, uint v3, uint v4, uint v5, uint v6, uint v7, uint v8) {
        uint[] vals;
        for (uint i = 0; i < offs.length; i++) {
            uint off = offs[i];
            uint mask = uint(0x03) << off;
            uint cur = (stg & mask) >> off;
            vals.push(cur);
        }
        return to_tuple(vals);
    }

    function cstat_options(uint stg) internal returns (uint v1, uint v2, uint v3, uint v4, uint v5, uint v6, uint v7, uint v8) {
        return option_values([uint(UNITS_OFF), TAIL_OFF, CELLS_OFF, REFS_OFF, SIZE_OFF, DEPTH_OFF], stg);
    }
    function to_tuple(uint[] vals) internal returns (uint v1, uint v2, uint v3, uint v4, uint v5, uint v6, uint v7, uint v8) {
        uint l = vals.length;
        v1 = l > 0 ? vals[0] : 0;
        v2 = l > 1 ? vals[1] : 0;
        v3 = l > 2 ? vals[2] : 0;
        v4 = l > 3 ? vals[3] : 0;
        v5 = l > 4 ? vals[4] : 0;
        v6 = l > 5 ? vals[5] : 0;
        v7 = l > 6 ? vals[6] : 0;
        v8 = l > 7 ? vals[7] : 0;
    }
    function option_values(TvmSlice[] ss, uint stg) internal returns (uint v1, uint v2, uint v3, uint v4, uint v5, uint v6, uint v7, uint v8) {
        uint[] vals = flag_values(ss, stg);
        return to_tuple(vals);
    }
}