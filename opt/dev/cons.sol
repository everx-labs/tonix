pragma ton-solidity >= 0.67.0;

import "cons_h.sol";

contract cons {

    uint8 constant CN_DEAD		= 0;	// device doesn't exist
    uint8 constant CN_LOW		= 1;	// device is a last restort only
    uint8 constant CN_NORMAL	= 2;	// device exists but is nothing special
    uint8 constant CN_INTERNAL	= 3;	// "internal" bit-mapped display
    uint8 constant CN_REMOTE	= 4;	// serial interface with remote bit set

    s_consdev _cn;
    bytes[] _buf;
    TvmCell[] _cells;

   function dcn_probe(s_consdev) internal {
        _cn.cn_pri = CN_INTERNAL;
    }
    function dcn_init(s_consdev) internal {
        bytes buf;
        TvmCell c;
        repeat (3) {
            _buf.push(buf);
            _cells.push(c);
        }
        consdev_ops ops = consdev_ops(dcn_probe, dcn_init, dcn_term, dcn_getc, dcn_putc, dcn_grab, dcn_ungrab, dcn_resume);
        _cn = s_consdev(ops, CN_INTERNAL, 0, 0, "dcn0");
    }
    function dcn_term(s_consdev) internal {
        _cn.cn_pri = CN_DEAD;
    }
    function dcn_getc(s_consdev) internal returns (byte c) {
        TvmSlice s = _cells[0].toSlice();
        if (s.hasNBits(8)) {
            c = s.decode(byte);
            TvmBuilder b;
            b.store(s);
            _cells[0] = b.toCell();
        } else
            c = 0xFF;
    }
    function dcn_putc(s_consdev, byte c) internal {
        TvmSlice s = _cells[1].toSlice();
        TvmBuilder b;
        b.store(s);
        if (b.remBits() > 8) {
            b.store(c);
            _cells[1] = b.toCell();
        }
    }
    function dcn_grab(s_consdev cn) internal {

    }
    function dcn_ungrab(s_consdev cn) internal {

    }
    function dcn_resume(s_consdev cn) internal {

    }

    function hook(uint8 n, uint8 i) external {
        tvm.accept();
        s_consdev cn;
        if (n == 1) dcn_probe(cn);
        if (n == 2) dcn_init(cn);
        if (n == 3) dcn_term(cn);
        if (n == 4) dcn_getc(cn);
        if (n == 5) dcn_putc(cn, byte(i));
        if (n == 6) dcn_grab(cn);
        if (n == 7) dcn_ungrab(cn);
        if (n == 8) dcn_resume(cn);
    }
    function set(uint8 i, bytes data) external {
        tvm.accept();
        TvmSlice s = _cells[i].toSlice();
        TvmBuilder b;
        uint len = data.length;
        b.store(s);
        if (b.remBits() > len * 8) {
            for (byte c: data)
                b.store(c);
        } else if (b.remRefs() > 0)
            b.store(data);
        _cells[i] = b.toCell();
    }
    function drop(uint8 i) external {
        tvm.accept();
        delete _cells[i];
    }
    function flush(uint8 i) external view returns (bytes res) {
        TvmSlice s = _cells[i].toSlice();
        TvmBuilder b;
        while (s.hasNBits(8)) {
            b.store(s.decode(byte));
        }
        TvmBuilder b0;
        b0.storeRef(b);
        TvmSlice s2 = b0.toSlice();
        res = s2.decode(bytes);

    }
    function cdump() external view returns (bytes[], TvmCell[]) {
        return (_buf, _cells);
    }
}