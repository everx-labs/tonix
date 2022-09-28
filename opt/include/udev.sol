pragma ton-solidity >= 0.64.0;

import "ged.sol";
//contract udev is ged {
contract udev {

    device_t _dev;
    constructor(device_t pdev, device_t dev) public {
//        _pdev = pdev;
//        _dev = dev.link;
//        TvmBuilder b;
//        b.store(dev);
//        _st((uint32(6) << 8) + _dev, b.toCell());
        tvm.accept();
        _dev = dev;
    }

    function set_desc(string desc) external {
        tvm.accept();
        _dev.desc = bytes20(desc);
    }

    function get_name() external view returns (string) {
        return libdevice.get_name(_dev);
    }

    function get_devclass() external view returns (uint32) {
        return libdevice.get_devclass(_dev);
    }

    function get_driver() external view returns (uint32) {
        return libdevice.get_driver(_dev);
    }

    function get_nameunit() external view returns (string) {
        return libdevice.get_nameunit(_dev);
    }
    function get_softc() external view returns (uint32) {
        return libdevice.get_softc(_dev);
    }
    function get_state() external view returns (device_state) {
        return libdevice.get_state(_dev);
    }
    function get_unit() external view returns (uint16) {
        return libdevice.get_unit(_dev);
    }

    function set_unit(uint8 unit) internal returns (uint8) {
        _dev.unit = unit;
    }
    function has_quiet_children() external view returns (bool) {
        return libdevice.has_quiet_children(_dev);
    }
    function is_alive() external view returns (bool) {
        return libdevice.is_alive(_dev);
    }
    function is_attached() external view returns (bool) {
        return libdevice.is_attached(_dev);
    }
    function is_enabled() external view returns (bool) {
        return libdevice.is_enabled(_dev);
    }
    function is_suspended() external view returns (bool) {
        return libdevice.is_suspended(_dev);
    }

}