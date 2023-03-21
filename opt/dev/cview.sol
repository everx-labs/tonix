pragma ton-solidity >= 0.67.0;
import "libctl.sol";
import "libdis.sol";
import "libdis2.sol";
contract cview {
    uint32 _flags;
    mapping (uint32 => TvmCell) _mem;
    function dda(bytes bb) external pure returns (string out) {
        return libdis.dda(bb);
    }
    function dda2(bytes bb) external pure returns (string out) {
        return libdis2.dda(bb);
    }
    function conf(uint32 val) external {
        tvm.accept();
        _flags = val;
    }
}