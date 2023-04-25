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
    function print_config(uint h) external pure returns (string out, string dbg) {
        uint shift = 1;
        for (string o: OPTS) {
            out.append(o + ((h & shift) > 0 ? "X" : " ") + "]\n");
            shift <<= 1;
        }
    }
}
