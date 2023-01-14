pragma ton-solidity >= 0.62.0;

import "bus_h.sol";

interface idevclass {
    function devclass_create(string classname) external returns (devclass_t);

    function devclass_add_driver(uint16 dc, driver_t driver, uint16 pass, uint16 dcp) external returns (uint8);
    function devclass_delete_driver(uint16 busclass, uint16 ddi) external returns (uint8);
    function devclass_find(string classname) external returns (devclass_t);
    function devclass_find_free_unit(uint16 dc, uint16 unit) external view returns (uint16);
    function devclass_get_name(uint16 dc) external view returns (string);
    function devclass_get_device(uint16 dc, uint16 unit) external view returns (device_t);
    function devclass_get_softc(uint16 dc, uint16 unit) external view returns (bytes);
    function devclass_get_devices(uint16 dc) external view returns (uint8, device_t[] listp, uint16 countp);
    function devclass_get_drivers(uint16 dc) external view returns (uint8, driver_t[] listp, uint16 countp);
    function devclass_get_count(uint16 dc) external view returns (uint16);
    function devclass_get_maxunit(uint16 dc) external view returns (uint16);
    function devclass_get_parent(uint16 dc) external view returns (devclass_t);
    function devclass_set_parent(uint16 dc, uint16 pdc) external;
    function devclass_add_device(uint16 dci, device_t dev) external returns (uint8 error);
//    function devclass_get_sysctl_ctx(devclass_t dc) internal returns (s_sysctl_ctx_list) {}
//    function devclass_get_sysctl_tree(devclass_t dc) internal returns (s_sysctl_oid) {}
}