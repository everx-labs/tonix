pragma ton-solidity >= 0.67.0;
import "common.h";
import "libtic.sol";

contract gensec is common {
    function gen_module(gtic g) external pure returns (string out, string dbg) {
        (out, dbg) = libtic.gen_module(g);
        dbg.append(g.print_types());
    }
}