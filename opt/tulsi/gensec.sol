pragma ton-solidity >= 0.67.0;
import "common.h";
import "libtic.sol";

contract gensec is common {
    string[] constant OPTS = [
"Structure type definitions: [",
"Enum type definitions:      [",
"Type printing functions:    [",
"Terse printing format:      [",
"Verbose printing format:    [",
"Helper contract encoders:   [",
"Print cell by type:         ["
];

    function gen_module(gtic g, uint h) external pure returns (string out, string dbg) {
        (out, dbg) = libtic.gen_module(g, h);
        uint shift = 1;
        for (string o: OPTS) {
            dbg.append(o + ((h & shift) > 0 ? "X" : " ") + "]\n");
            shift <<= 1;
        }
    }
    function type_info(gtic g) external pure returns (string out) {
        out.append(g.print_types());
    }

    function scan_mem(gtic g, mapping (uint32 => TvmCell) m) external pure returns (string out, string dbg) {
        dbg.append("Addr bits cells refs\n");
        for ((uint32 a, TvmCell c): m) {
            (uint nc, uint nb, uint nr) = c.dataSize(200);
            uint idx = _match_size(g, nb);
            dbg.append(format("[{}]  {} {} {}\n", a, nb, nc, nr));
            if (idx > 0) {
//                dbg.append(format("Found match at index {}\n", idx));
                strti t = g.tc[idx];
                out.append(format("[{}]\t", a) + "is likely a " + t.name + "\n");
            } else
                dbg.append(" -\n");
        }
    }
//
//    function _pcmp(gtic g, mapping (uint32 => TvmCell) m1, mapping (uint32 => TvmCell) m2) internal view returns (string out) {
//        (uint nc, uint nb, uint nr) = c.dataSize(200);
//        bool f = false;
//        if (cid > 0) {
//            stot st = ST[cid];
//            out.append(print_stot(st));
//            if (st.pid == 4)
//                f = c != _ram[st.roff];
//            out.append(st.tname + ": " + (f ? "differs" : "identical"));
//        } else
//            out.append("not found");
//        out.append("\n");
//        if (!f)
//            return out;
//    }

    function _match_size(gtic g, uint sz) internal pure returns (uint) {
        for (uint i = g.mi.struct_start; i < g.mi.struct_start + g.mi.struct_len; i++) {
            (uint8 id, uint8 nv, uint8 nr, uint16 nb, uint8 attr, uint8 ldecl, uint8 ldesc, string sname, ) = g.tc[i].unpack();
            if (g.tc[i].nb == sz)
                return i;
        }
    }
    function struct_types(gtic g) external pure returns (string out, string dbg) {
        (mod_info mi, strti[] ti, mapping (uint => uint8) tnc) = g.unpack();
        (, , uint8 nt, , , , , , , , , , , uint8 enum_start, uint8 enum_len, uint8 struct_start, uint8 struct_len, uint8 map_start, uint8 map_len, string name) = mi.unpack();
        dbg.append(format("id  nv nr nb att dcl dsc   name\n"));
        out.append(format("id  nv nr nb  name\n"));
        for (uint i = struct_start; i < struct_start + struct_len; i++) {
            (uint8 id, uint8 nv, uint8 nr, uint16 nb, uint8 attr, uint8 ldecl, uint8 ldesc, string sname, ) = ti[i].unpack();
            dbg.append(format("{:2}) {:2} {} {:5} {:2} {:2} {:3} {}\n", id, nv, nr, nb, attr, ldecl, ldesc, sname));
            out.append(format("{:2}) {:2} {} {:5} {}\n", id, nv, nr, nb, sname));
        }
        for (uint i = map_start; i < map_start + map_len; i++) {
            (uint8 id, uint8 nv, uint8 nr, uint16 nb, uint8 attr, uint8 ldecl, uint8 ldesc, string sname, ) = ti[i].unpack();
            dbg.append(format("{:2}) {:2} {} {:5} {:2} {:2} {:3} {}\n", id, nv, nr, nb, attr, ldecl, ldesc, sname));
            out.append(format("{:2}) {:2} {} {:5} {}\n", id, nv, nr, nb, sname));
        }
    }
    function print_config(uint h) external pure returns (string out, string dbg) {
        uint shift = 1;
        for (string o: OPTS) {
            out.append(o + ((h & shift) > 0 ? "X" : " ") + "]\n");
            shift <<= 1;
        }
    }
    function _sizeof(TvmCell c) internal pure returns (uint) {
        ( , uint nb, ) = c.dataSize(200);
        return nb / 8;
    }

}
