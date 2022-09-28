pragma ton-solidity >= 0.61.2;

import "bus_h.sol";

library librman {

    uint16 constant  RM_TEXTLEN = 32;
//    uint16 constant  RM_MAX_END = (~(rman_res_t)0)
//    uint16 constant  RMAN_IS_DEFAULT_RANGE = (s,e)	((s) == 0 && (e) == RM_MAX_END)
    uint16 constant RF_ALLOCATED    = 0x0001;	// resource has been reserved
    uint16 constant RF_ACTIVE       = 0x0002;	// resource allocation has been activated
    uint16 constant RF_SHAREABLE    = 0x0004;	// resource permits contemporaneous sharing
    uint16 constant RF_SPARE1       = 0x0008;
    uint16 constant RF_SPARE2       = 0x0010;
    uint16 constant RF_FIRSTSHARE   = 0x0020;	// first in sharing list
    uint16 constant RF_PREFETCHABLE = 0x0040;	// resource is prefetchable
    uint16 constant RF_OPTIONAL     = 0x0080;	// for bus_alloc_resources()
    uint16 constant RF_UNMAPPED     = 0x0100;	// don't map resource when activating
    uint32 constant RF_ALIGNMENT_SHIFT =  10; // alignment size bit starts bit 10
    uint32 constant RF_ALIGNMENT_MASK = uint32(0x003F) << RF_ALIGNMENT_SHIFT; // resource address alignment size bit mask
//    uint16 constant  RF_ALIGNMENT_LOG2 = (x)	((x) << RF_ALIGNMENT_SHIFT)
    //uint16 constant  RF_ALIGNMENT = (x)		(((x) & RF_ALIGNMENT_MASK) >> RF_ALIGNMENT_SHIFT)

    function rman_activate_resource(s_resource r) internal returns (uint8) {}
    function rman_adjust_resource(s_resource r, uint32 start, uint32 end) internal returns (uint8) {}
    function rman_first_free_region(s_rman rm) internal returns (uint8, uint32 start, uint32 end) {}
    function rman_get_bushandle(s_resource ) internal returns (uint32) {}
    function rman_get_bustag(s_resource ) internal returns (uint32) {}
    function rman_get_end(s_resource ) internal returns (uint32) {}
    function rman_get_device(s_resource ) internal returns (device_t) {}
    function rman_get_flags(s_resource ) internal returns (uint16) {}
    function rman_get_irq_cookie(s_resource ) internal returns (bytes) {}
    function rman_get_mapping(s_resource ) internal returns (s_resource_map) {}
    function rman_get_rid(s_resource ) internal returns (uint8) {}
    function rman_get_size(s_resource ) internal returns (uint32) {}
    function rman_get_start(s_resource ) internal returns (uint32) {}
    function rman_get_virtual(s_resource ) internal returns (bytes) {}
    function rman_deactivate_resource(s_resource r) internal returns (uint8) {}
    function rman_fini(s_rman rm) internal returns (uint8) {}
    function rman_init(s_rman rm) internal returns (uint8) {}
    function rman_init_from_resource(s_rman rm, s_resource r) internal returns (uint8) {}
    function rman_last_free_region(s_rman rm) internal returns (int, uint32 start, uint32 end) {}
    function rman_make_alignment_flags(uint32 size) internal returns (uint32) {}
    function rman_manage_region(s_rman rm, uint32 start, uint32 end) internal returns (uint8) {}
    function rman_is_region_manager(s_resource r, s_rman rm) internal returns (uint8) {}
    function rman_release_resource(s_resource r) internal returns (uint8) {}
    function rman_reserve_resource(s_rman rm, uint32 start, uint32 end, uint32 count, uint16 flags, device_t dev) internal returns (s_resource) {}
    function rman_reserve_resource_bound(s_rman rm, uint32 start, uint32 end, uint32 count, uint32 bound, uint16 flags, device_t dev) internal returns (s_resource) {}
    function rman_set_bushandle(s_resource _r, uint32 _h) internal {}
    function rman_set_bustag(s_resource _r, uint32 _t) internal {}
    function rman_set_device(s_resource _r, device_t _dev) internal {}
    function rman_set_end(s_resource _r, uint32 _end) internal {}
    function rman_set_irq_cookie(s_resource _r, bytes _c) internal {}
    function rman_set_mapping(s_resource , s_resource_map) internal {}
    function rman_set_rid(s_resource _r, uint8 _rid) internal {}
    function rman_set_start(s_resource _r, uint32 _start) internal {}
    function rman_set_virtual(s_resource _r, bytes _v) internal {}
}