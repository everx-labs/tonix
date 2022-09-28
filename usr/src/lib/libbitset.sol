pragma ton-solidity >= 0.64.0;
library libbitset {
    function BIT_CLR(uint32 set, uint8 n) internal {
        set &= ~(uint32(1) << n);
    }
    function BIT_ISSET(uint32 set, uint8 n) internal returns (bool) {
        return set & (uint32(1) << n) > 0;
    }
    function BIT_SET(uint32 set, uint8 n) internal {
        set |= uint32(1) << n;
    }
    function toa(uint32 set) internal returns (string out) {
        uint sdiv = set;
        uint smod;
        while (sdiv > 0) {
            (sdiv, smod) = math.divmod(sdiv, 2);
            out = (smod == 0 ? "0" : "1") + out;
        }
    }
}