pragma ton-solidity >= 0.64.0;

import "udev.sol";
import "libdevice.sol";
import "fmt.sol";
import "libtable.sol";
contract tdev is udev {

    device_t _pdev;
    using libtable for s_table;
    constructor(device_t pdev) udev (pdev) public {
        _pdev = pdev;
        tvm.accept();
    }

    function encode(device_t dev) external pure returns (TvmCell) {
        return _encode(dev);
    }
//    function encode(uint8 link, address devlink, uint8 parent, uint8[] children, uint8 driver, bytes10 devclass, uint8 unit, bytes12 nameunit, bytes20 desc, uint8 busy, device_state state, uint8 devflags, uint16 flags, uint8 order, TvmCell ivars, TvmCell softc) internal pure returns (TvmCell) {
    function _encode(device_t dev) internal pure returns (TvmCell) {
        (uint8 link, address devlink, uint8 parent, , uint8 driver, bytes10 devclass, uint8 unit, bytes12 nameunit, bytes20 desc, uint8 busy, device_state state, uint8 devflags, uint16 flags, uint8 order, TvmCell ivars, TvmCell softc) = dev.unpack();
        TvmBuilder b;
        b.store(link, devlink, parent, driver, devclass, unit, nameunit, desc, busy, uint8(state), devflags, flags, order);
        b.store(ivars, softc);
        return b.toCell();
    }

    function decode(TvmCell c) external pure returns (device_t dev) {
        return _decode(c);
    }
//    function decode(TvmCell c) internal pure returns (uint8 link, address devlink, uint8 parent, uint8[] children, uint8 driver, bytes10 devclass, uint8 unit, bytes12 nameunit, bytes20 desc, uint8 busy, uint8 state, uint8 devflags, uint16 flags, uint8 order, TvmCell ivars, TvmCell softc) {
    function _decode(TvmCell c) internal pure returns (device_t dev) {
        uint8[] children;
        TvmSlice s = c.toSlice();
        (uint8 link, address devlink, uint8 parent, uint8 driver, bytes10 devclass, uint8 unit, bytes12 nameunit, bytes20 desc, uint8 busy,
            uint8 state, uint8 devflags, uint16 flags, uint8 order) = s.decode(uint8, address, uint8, uint8, bytes10, uint8, bytes12, bytes20, uint8, uint8, uint8, uint16, uint8);
        (TvmCell ivars, TvmCell  softc) = s.decode(TvmCell, TvmCell);
        return device_t(link, devlink, parent, children, driver, devclass, unit, nameunit, desc, busy, device_state(state), devflags, flags, order, ivars, softc);
    }

    function print_drivers(devclass_t[] devclasses) external pure returns (string out) {
        s_table t = libtable.generic([uint(3), 3, 20, 6, 30], libtable.CENTER);
        for (devclass_t dc: devclasses) {
            (uint8 link, , driver_t[] drivers, bytes10 name, , , ) = dc.unpack();
            for (driver_t d: drivers) {
                (uint16 version, , , uint16 size, , , uint32 updated_at) = d.unpack();
                t.add_row([str.toa(link + 1), str.toa(version), bytes(name), str.toa(size), fmt.ts(updated_at)]);
            }
        }
        return t.compute();
    }
    function print_devices(device_t[] devs) external pure returns (string out) {
        s_table t = libtable.generic([uint(66), 20], libtable.LEFT);
        for (device_t dev: devs)
            t.add_row([format("{}", dev.devlink), bytes(dev.nameunit)]);
        return t.compute();
    }

    function b12(bytes12 bb) external pure returns (string out) {
        TvmBuilder b;
        b.store(bb);
        return bn_to_string(b);
    }
    function b10(bytes10 bb) external pure returns (string out) {
        TvmBuilder b;
        b.store(bb);
        return bn_to_string(b);
    }
    function bn_to_string(TvmBuilder b) internal pure returns (string out) {
        TvmSlice s = b.toSlice();
        return to_string(s);
    }
    function to_string(TvmSlice s) internal pure returns (bytes res) {
        uint nbytes = s.bits() / 8;
        uint len;
        //while (nbytes > 0) {
        //    uint8 b = s.decode(uint8);
        //    if (b == 0)
        //        return len;
        //    len++;
        //    nbytes--;
        //}

        if (nbytes > 2) {
            uint8 len = s.decode(uint8);
            if (nbytes < len + 2)
                return res;
            TvmSlice s1 = s.loadSlice(len * 8);
            res = s1.decode(bytes);
            return res;
        }
    }
    function get_len(TvmSlice s) internal pure returns (uint len) {
        uint nbytes = s.bits() / 8;
        while (nbytes > 0) {
            uint8 b = s.decode(uint8);
            if (b == 0)
                return len;
            len++;
            nbytes--;
        }
    }
}