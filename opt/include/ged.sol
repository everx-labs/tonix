pragma ton-solidity >= 0.64.0;
import "bus_h.sol";
import "libdevice.sol";

abstract contract generic_bus {
    function BUS_CHILD_DELETED(TvmCell dev, TvmCell child) external {}
    function BUS_CHILD_DETACHED(TvmCell dev, TvmCell child) external {}
}

/*
 * A generic non-bus device. Stores certain pieces of information about the parent device.
 */
contract ged {

    uint32 constant NULL = 0;

    uint16 constant DF_ENABLED         = 0x01;  // device should be probed/attached
    uint16 constant DF_FIXEDCLASS      = 0x02;  // devclass specified at create time
    uint16 constant DF_WILDCARD        = 0x04;  // unit was originally wildcard
    uint16 constant DF_DESCMALLOCED    = 0x08;  // description was malloced
    uint16 constant DF_QUIET           = 0x10;  // don't print verbose attach message
    uint16 constant DF_DONENOMATCH     = 0x20;  // don't execute DEVICE_NOMATCH again
    uint16 constant DF_EXTERNALSOFTC   = 0x40;  // softc not allocated by us
    uint16 constant DF_SUSPENDED       = 0x100;	// Device is suspended.
    uint16 constant DF_QUIET_CHILDREN  = 0x200;	// Default to quiet for all my children
    uint16 constant DF_ATTACHED_ONCE   = 0x400;	// Has been attached at least once
    uint16 constant DF_NEEDNOMATCH     = 0x800;	// Has a pending NOMATCH event

    uint8 _pdev;
    uint8 _dev;
    bytes12 static _nameunit;
    uint8 _cred; // s_ucred
    mapping (uint32 => TvmCell) _mem;

    function store_cell(uint32 addr, TvmCell c) external accept {
        _st(addr, c);
    }
    function read_cell(uint32 addr) external view returns (TvmCell) {
        return _ld(addr);
    }
    function load_cell(uint32 addr) external view {
        ged(msg.sender).store_cell(addr, _mem[addr]);
    }

    constructor(device_t pdev) public {
        _pdev = pdev.link;
//        device_store(pdev, _pdev);
        TvmBuilder b;
        b.store(pdev);
        _st((uint32(6) << 8) + _pdev, b.toCell());
        tvm.accept();
    }

    function dev_init(devclass_t dc, device_t dev, s_ucred cr) external {
        tvm.accept();
        _dev = dev.link;
        dev.devclass = dc.link;
//        device_store(dev, dev.link);
        TvmBuilder b;
        b.store(dev);
        _st((uint32(6) << 8) + _dev, b.toCell());
        delete b;
        b.store(cr);
        _cred = 1;
        _st((uint32(13) << 8) + _cred, b.toCell());
    }

    function dump() external view returns (mapping (uint32 => TvmCell), uint32, uint32, string, uint8) {
        return (_mem, _pdev, _dev, bytes(_nameunit), _cred);
    }
    function mem_map_in(mapping (uint32 => TvmCell) mem) external accept {
        for ((uint32 a, TvmCell c): mem)
            _st(a, c);
    }

    function mem_read() external view accept {
        ged(msg.sender).mem_map_in{flag: 1}(_mem);
    }

//    function mem_read_range(uint32 from, uint32 to) external view accept {
//        mapping (uint32 => TvmCell) mem;
//        for ((uint32 a, TvmCell c): _mem)
//            if (from <= a && a <= to)
//                mem[a] = c;
//        ged(msg.sender).mem_map_in{flag: 1}(mem);
//    }

//    function dump_core() external view returns (mapping (uint32 => TvmCell)) {
//        return _mem;
//    }

    function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }
    function reset_storage() external {
        tvm.accept();
        tvm.resetStorage();
    }

//    function _ck(uint32 addr) internal view returns (uint8) {
//        if (addr == 0)
//            return err.EINVAL;
//        if (_mem.exists(addr))
//            return 0;
//    }
    function _st(uint32 addr, TvmCell c) internal {
        _mem[addr] = c;
    }
    function _ld(uint32 addr) internal view returns (TvmCell) {
        return _mem[addr];
    }

//    function delete_child(device_t dev, device_t child) internal returns (uint8) {
//    }
//    function add_child(device_t dev, string name, uint8 unit) internal returns (device_t res) {
//        res = find_child(dev, name, unit);
//    }
//    function add_child_ordered(device_t dev, uint8 order, string name, uint8 unit) internal returns (device_t) {
//    }
//    function find_child(device_t dev, string classname, uint8 unit) internal returns (device_t) {
//        devclass_t dc = libdevclass.find(classname);
//    }

    function DEVICE_SUSPEND(device_t dev) internal returns (uint8) { // 3430270576
    }
    function DEVICE_RESUME(device_t dev) internal returns (uint8) { // 779178141
    }

    /*function detach(device_t dev) external accept {
        DEVICE_DETACH(dev);
    }*/
    function DEVICE_DETACH(device_t dev) external accept returns (uint8) {
//    function DEVICE_DETACH(device_t dev) internal returns (uint8) {
//        selfdestruct(dev.devlink);
        address addr = dev.devlink;
        generic_bus(addr).BUS_CHILD_DETACHED{value: 0.033 ton, flag: 1}(_ld((uint32(6) << 8) + _pdev), _ld((uint32(6) << 8) + _dev));
        selfdestruct(addr);
    }
    function DEVICE_PROBE(device_t dev) internal returns (uint8) { // 2377098690

    }
    function shutdown(device_t dev) external {
        address addr = dev.devlink;
        generic_bus(addr).BUS_CHILD_DELETED{value: 0.034 ton, flag: 1}(_ld((uint32(6) << 8) + _pdev), _ld((uint32(6) << 8) + _dev));
        selfdestruct(addr);
    }
    function DEVICE_IDENTIFY(driver_t driver, device_t parent) internal {} // 2563821249
    function onCodeUpgrade() internal {
        tvm.resetStorage();
    }
    modifier accept {
        tvm.accept();
        _;
    }
}