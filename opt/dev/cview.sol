pragma ton-solidity >= 0.65.0;
import "ged.sol";
import "libctl.sol";
import "libdis.sol";
import "libdis2.sol";
contract cview is ged {
    uint32 _flags;
    function dda(bytes bb) external pure returns (string out) {
        return libdis.dda(bb);
    }
    function dda2(bytes bb) external pure returns (string out) {
        return libdis2.dda(bb);
    }
    constructor(device_t pdev) public ged(pdev) {
        tvm.accept();
    }
    function conf(uint32 val) external {
        tvm.accept();
        _flags = val;
    }
}