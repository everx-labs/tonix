pragma ever-solidity >= 0.66.0;

contract b0 {

    uint32 constant NULL = 0;
    uint16 constant DEF_BSIZE = 124;
    mapping (uint32 => TvmCell) _ram;

    function uc(TvmCell c) external accept {
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

    modifier accept {
        tvm.accept();
        _;
    }
}