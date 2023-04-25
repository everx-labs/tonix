pragma ton-solidity >= 0.67.0;
contract common {
    function _from_handle(uint h) internal pure returns (uint8 n, uint8 t, uint8 c, uint8 f, uint8 o, uint8 a) {
        return (uint8(h & 0xFF), uint8(h >> 8 & 0xFF), uint8(h >> 16 & 0xFF), uint8(h >> 24 & 0xFF), uint8(h >> 32 & 0xFF), uint8(h >> 40 & 0xFF));
    }
    function _to_handle(uint n, uint t, uint c, uint f, uint o, uint a) internal pure returns (uint h) {
        return n + (t << 8) + (c << 16) + (f << 24) + (o << 32) + (a << 40);
    }
    function _a(uint t, uint n) internal pure returns (uint) {
        return (t << 8) + n;
    }
    function _ua(uint t, uint n) internal pure returns (uint32) {
        return uint32((t << 4) + n);
    }
    uint32 constant NULL = 0;
    mapping (uint32 => TvmCell) _ram;
    function uc(TvmCell c) external {
        tvm.accept();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }
    modifier accept {
        tvm.accept();
        _;
    }
    function st(uint32 a, TvmCell c) external accept {
        _ram[a] = c;
    }
    function ld(uint32 a) external view returns (TvmCell c) {
        c = _ram[a];
    }
}
