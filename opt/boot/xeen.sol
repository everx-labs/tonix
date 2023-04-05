pragma ton-solidity >= 0.67.0;

import "common.h";

contract xeen {
    TvmCell _rom;
    uint32 _version;
    mapping (uint32 => TvmCell) _ram;
    function uc(TvmCell c) external accept {
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }
    modifier accept {
        tvm.accept();
        _;
    }
    function immap(mapping (uint32 => TvmCell) m) external accept {
        for ((uint32 a, TvmCell c): m)
            if (_ram[a] != c)
                _ram[a] = c;
    }
    function ldr(uint32 a, uint32 n) external view returns (TvmCell[] cc) {
        repeat(n) {
            if (_ram.exists(a))
                cc.push(_ram[a]);
            a++;
        }
    }
    function st(uint32 a, TvmCell c) external accept {
        _ram[a] = c;
    }
    function ld(uint32 a) external view returns (TvmCell c) {
        c = _ram[a];
    }

    function _dev_info() internal view returns (string out) {
        out.append(format("version: {}\n", _version));
    }

    function onCodeUpgrade() internal {
        _version++;
    }

}