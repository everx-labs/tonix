pragma ton-solidity >= 0.63.0;

import "librman.sol";
import "bus_h.sol";
import "sbuf_h.sol";
library libbus {

    uint8 constant DL_DEFERRED_PROBE = 1; // Probe deferred on this
    uint8 constant DC_HAS_CHILDREN = 1;

    uint16 constant BUS_USER_VERSION   = 2;
    uint16 constant BUS_USER_BUFFER    = 3 * 1024;
    /*uint16 constant DF_ENABLED         = 0x01;  // device should be probed/attached
    uint16 constant DF_FIXEDCLASS      = 0x02;  // devclass specified at create time
    uint16 constant DF_WILDCARD        = 0x04;  // unit was originally wildcard
    uint16 constant DF_DESCMALLOCED    = 0x08;  // description was malloced
    uint16 constant DF_QUIET           = 0x10;  // don't print verbose attach message
    uint16 constant DF_DONENOMATCH     = 0x20;  // don't execute DEVICE_NOMATCH again
    uint16 constant DF_EXTERNALSOFTC   = 0x40;  // softc not allocated by us
    uint16 constant DF_SUSPENDED       = 0x100;	// Device is suspended.
    uint16 constant DF_QUIET_CHILDREN  = 0x200;	// Default to quiet for all my children
    uint16 constant DF_ATTACHED_ONCE   = 0x400;	// Has been attached at least once
    uint16 constant DF_NEEDNOMATCH     = 0x800;	// Has a pending NOMATCH event*/

    uint16 constant	RLE_RESERVED    = 0x0001; // Reserved by the parent bus.
    uint16 constant	RLE_ALLOCATED   = 0x0002; // Reserved resource is allocated.
    uint16 constant	RLE_PREFETCH    = 0x0004; // Resource is a prefetch range.
//#define	RESOURCE_SPEC_END	{-1, 0, 0}

    function resource_list_init(s_resource_list rl) internal {}
    function resource_list_free(s_resource_list rl) internal {}
    function resource_list_add(s_resource_list rl, uint8 rtype, uint8 rid, uint32 start, uint32 end, uint32 count) internal returns (s_resource_list_entry) {}
    function resource_list_add_next(s_resource_list rl, uint8 rtype, uint32 start, uint32 end, uint32 count) internal returns (uint8) {}
    function resource_list_busy(s_resource_list rl, uint8 rtype, uint8 rid) internal returns (uint8) {}
    function resource_list_reserved(s_resource_list rl, uint8 rtype, uint8 rid) internal returns (uint8) {}
    function resource_list_find(s_resource_list rl, uint8 rtype, uint8 rid) internal returns (s_resource_list_entry) {}
    function resource_list_delete(s_resource_list rl, uint8 rtype, uint8 rid) internal {}
    function resource_list_alloc(s_resource_list rl, device_t bus, device_t child, uint8 rtype, uint8[] rid, uint32 start, uint32 end, uint32 count, uint16 flags) internal returns (s_resource) {}
    function resource_list_release(s_resource_list rl, device_t bus, device_t child, uint8 rtype, uint8 rid, s_resource res) internal returns (uint8) {}
    function resource_list_release_active(s_resource_list rl, device_t bus, device_t child, uint8 rtype) internal returns (uint8) {}
    function resource_list_reserve(s_resource_list rl, device_t bus, device_t child, uint8 rtype, uint8[] rid, uint32 start, uint32 end, uint32 count, uint16 flags) internal returns (s_resource) {}
    function resource_list_unreserve(s_resource_list rl, device_t bus, device_t child, uint8 rtype, uint8 rid) internal returns (uint8) {}
    function resource_list_purge(s_resource_list rl) internal {}
    function resource_list_print_type(s_resource_list rl, string name, uint8 rtype, string sfmt) internal returns (uint8) {}
    function bus_generic_activate_resource(device_t dev, device_t child, uint8 rtype, uint8 rid, s_resource r) internal returns (uint8) {}
    function bus_generic_add_child(device_t dev, uint8 order, string name, uint8 unit) internal returns (device_t) {}
    function bus_generic_adjust_resource(device_t bus, device_t child, uint8 rtype, s_resource r, uint32 start, uint32 end) internal returns (uint8) {}
    function bus_generic_alloc_resource(device_t bus, device_t child, uint8 rtype, uint8[] rid, uint32 start, uint32 end, uint32 count, uint16 flags) internal returns (s_resource) {}
    function bus_generic_translate_resource(device_t dev, uint8 rtype, uint32 start) internal returns (uint8, uint32 newstart) {}
    function bus_generic_attach(device_t dev) internal returns (uint8) {}
    function bus_generic_bind_intr(device_t dev, device_t child, s_resource irq, uint8 cpu) internal returns (uint8) {}
    function bus_generic_child_location(device_t dev, device_t child, s_sbuf sb) internal returns (uint8) {}
    function bus_generic_child_pnpinfo(device_t dev, device_t child, s_sbuf sb) internal returns (uint8) {}
    function bus_generic_child_present(device_t dev, device_t child) internal returns (uint8) {}
    function bus_generic_config_intr(device_t, uint8, intr_trigger, intr_polarity) internal returns (uint8) {}
    function bus_generic_describe_intr(device_t dev, device_t child, s_resource irq, bytes cookie, string descr) internal returns (uint8) {}
    function bus_generic_deactivate_resource(device_t dev, device_t child, uint8 rtype, uint8 rid, s_resource r) internal returns (uint8) {}
    function bus_generic_detach(device_t dev) internal returns (uint8) {}
    function bus_generic_driver_added(device_t dev, driver_t driver) internal {}
    function bus_generic_get_dma_tag(device_t dev, device_t child) internal returns (uint32) {}
    function bus_generic_get_bus_tag(device_t dev, device_t child) internal returns (uint32) {}
    function bus_generic_get_domain(device_t dev, device_t child, uint8[] domain) internal returns (uint8) {}
    function bus_generic_get_property(device_t dev, device_t child, string propname, bytes propvalue, uint16 size, device_property_type ptype) internal returns (uint32) {}
    function bus_generic_get_resource_list(device_t, device_t) internal returns (s_resource_list) {}
    function bus_generic_map_resource(device_t dev, device_t child, uint8 rtype, s_resource r, s_resource_map_request args, s_resource_map map) internal returns (uint8) {}
    function bus_generic_new_pass(device_t dev) internal {}
    function bus_print_child_header(device_t dev, device_t child) internal returns (uint8) {}
    function bus_print_child_domain(device_t dev, device_t child) internal returns (uint8) {}
    function bus_print_child_footer(device_t dev, device_t child) internal returns (uint8) {}
    function bus_generic_print_child(device_t dev, device_t child) internal returns (uint8) {}
    function bus_generic_probe(device_t dev) internal returns (uint8) {}
    function bus_generic_read_ivar(device_t dev, device_t child, uint8 which) internal returns (uint8, string result) {}
    function bus_generic_release_resource(device_t bus, device_t child, uint8 rtype, uint8 rid, s_resource r) internal returns (uint8) {}
    function bus_generic_resume(device_t dev) internal returns (uint8) {}
    function bus_generic_resume_child(device_t dev, device_t child) internal returns (uint8) {}
    function bus_generic_rl_alloc_resource (device_t, device_t, uint8, uint8, uint32, uint32, uint32, uint32) internal returns (s_resource) {}
    function bus_generic_rl_delete_resource (device_t, device_t, uint8, uint8) internal {}
    function bus_generic_rl_get_resource (device_t, device_t, uint8, uint8) internal returns (uint8, uint32, uint32) {}
    function bus_generic_rl_set_resource (device_t, device_t, uint8, uint8, uint32, uint32) internal returns (uint8) {}
    function bus_generic_rl_release_resource (device_t, device_t, uint8, uint8, s_resource) internal returns (uint8) {}
    function bus_generic_shutdown(device_t dev) internal returns (uint8) {}
    function bus_generic_suspend(device_t dev) internal returns (uint8) {}
    function bus_generic_suspend_child(device_t dev, device_t child) internal returns (uint8) {}
    function bus_generic_teardown_intr(device_t dev, device_t child, s_resource irq, bytes cookie) internal returns (uint8) {}
    function bus_generic_suspend_intr(device_t dev, device_t child, s_resource irq) internal returns (uint8) {}
    function bus_generic_resume_intr(device_t dev, device_t child, s_resource irq) internal returns (uint8) {}
    function bus_generic_unmap_resource(device_t dev, device_t child, uint8 rtype, s_resource r, s_resource_map map) internal returns (uint8) {}
    function bus_generic_write_ivar(device_t dev, device_t child, uint8 which, uint32 value) internal returns (uint8) {}
    function bus_generic_get_device_path(device_t bus, device_t child, string locator, s_sbuf sb) internal returns (uint8) {}
    function bus_helper_reset_post(device_t dev, uint8 flags) internal returns (uint8) {}
    function bus_helper_reset_prepare(device_t dev, uint8 flags) internal returns (uint8) {}
    function bus_null_rescan(device_t dev) internal returns (uint8) {}
    function bus_alloc_resources(device_t dev, s_resource_spec rs, s_resource[] res) internal returns (uint8) {}
    function bus_release_resources(device_t dev, s_resource_spec rs, s_resource[] res) internal {}
    function bus_adjust_resource(device_t child, uint8 rtype, s_resource r, uint32 start, uint32 end) internal returns (uint8) {}
    function bus_translate_resource(device_t child, uint8 rtype, uint32 start) internal returns (uint8, uint32 newstart) {}
    function bus_alloc_resource(device_t dev, uint8 rtype, uint8 rid, uint32 start, uint32 end, uint32 count, uint16 flags) internal returns (s_resource) {}
    function bus_activate_resource(device_t dev, uint8 rtype, uint8 rid, s_resource r) internal returns (uint8) {}
    function bus_deactivate_resource(device_t dev, uint8 rtype, uint8 rid, s_resource r) internal returns (uint8) {}
    function bus_map_resource(device_t dev, uint8 rtype, s_resource r, s_resource_map_request args, s_resource_map map) internal returns (uint8) {}
    function bus_unmap_resource(device_t dev, uint8 rtype, s_resource r, s_resource_map map) internal returns (uint8) {}
    function bus_get_dma_tag(device_t dev) internal returns (uint32) {}
    function bus_get_bus_tag(device_t dev) internal returns (uint32) {}
    function bus_get_domain(device_t dev, uint8[] domain) internal returns (uint8) {}
    function bus_release_resource(device_t dev, uint8 rtype, uint8 rid, s_resource r) internal returns (uint8) {}
    function bus_free_resource(device_t dev, uint8 rtype, s_resource r) internal returns (uint8) {}
    function bus_teardown_intr(device_t dev, s_resource r, bytes cookie) internal returns (uint8) {}
    function bus_suspend_intr(device_t dev, s_resource r) internal returns (uint8) {}
    function bus_resume_intr(device_t dev, s_resource r) internal returns (uint8) {}
    function bus_bind_intr(device_t dev, s_resource r, uint16 cpu) internal returns (uint8) {}
    function bus_describe_intr(device_t dev, s_resource irq, bytes cookie, string fmt) internal returns (uint8) {}
    function bus_set_resource(device_t dev, uint16 rtype, uint16 rid, uint32 start, uint32 count) internal returns (uint8) {}
    function bus_get_resource(device_t dev, uint16 rtype, uint16 rid) internal returns (uint8, uint32 startp, uint32 countp) {}
    function bus_get_resource_start(device_t dev, uint16 rtype, uint16 rid) internal returns (uint32) {}
    function bus_get_resource_count(device_t dev, uint16 rtype, uint16 rid) internal returns (uint32) {}
    function bus_delete_resource(device_t dev, uint8 rtype, uint8 rid) internal{}
    function bus_child_present(device_t child) internal returns (uint8) {}
    function bus_child_pnpinfo(device_t child, s_sbuf sb) internal returns (uint8) {}
    function bus_child_location(device_t child, s_sbuf sb) internal returns (uint8) {}
    function bus_enumerate_hinted_children(device_t bus) internal {}
    function bus_delayed_attach_children(device_t bus) internal returns (uint8) {}
    function resource_int_value(string name, uint8 unit, string resname) internal returns (uint8, uint8 result) {}
    function resource_long_value(string name, uint8 unit, string resname) internal returns (uint8, uint32 result) {}
    function resource_string_value(string name, uint8 unit, string resname) internal returns (uint8,  string result) {}
    function resource_disabled(string name, uint8 unit) internal returns (uint8) {}
    function resource_find_match(uint8 anchor, string[] name, uint16 unit, string resname, string value) internal returns (uint8) {}
    function resource_find_dev(uint8 anchor, string name, uint16 unit, string resname, string value) internal returns (uint8) {}
    function resource_unset_value(string name, uint16 unit, string resname) internal returns (uint8) {}
    function bus_data_generation_check(uint16 generation) internal returns (bool) {}
    function bus_data_generation_update() internal {}
    function bus_set_pass(uint8 pass) internal {}
//    function driver_module_handler(struct module *, int, void *) internal returns (int) {}
    function dev_wired_cache_init() internal returns (uint32) {}
    function dev_wired_cache_fini(uint32 dcp) internal {}
    function dev_wired_cache_match(uint32 dcp, device_t dev, string at) internal returns (bool) {}

    function bus_alloc_resource_any(device_t dev, uint8 rtype, uint8 rid, uint16 flags) internal returns (s_resource)  {
	    return bus_alloc_resource(dev, rtype, rid, 0, 0, 1, flags);
    }
    function bus_alloc_resource_anywhere(device_t dev, uint8 rtype, uint8 rid, uint32 count, uint16 flags) internal returns (s_resource) {
        return bus_alloc_resource(dev, rtype, rid, 0, 0, count, flags);
    }

    int32 constant BUS_PROBE_SPECIFIC   = 0;   // Only I can use this device
    int32 constant BUS_PROBE_VENDOR     = -10; // Vendor supplied driver
    int32 constant BUS_PROBE_DEFAULT    = -20; // Base OS default driver
    int32 constant BUS_PROBE_LOW_PRIORITY = -40; // Older, less desirable drivers
    int32 constant BUS_PROBE_GENERIC    = -100;	// generic driver for dev
    int32 constant BUS_PROBE_HOOVER     = -1000000; // Driver for any dev on bus
    int32 constant BUS_PROBE_NOWILDCARD = -2000000000; // No wildcard device matches
    uint8 constant BUS_PASS_ROOT		= 0;  // Used to attach root0
    uint8 constant BUS_PASS_BUS	        = 10; // Buses and bridges
    uint8 constant BUS_PASS_CPU	        = 20; // CPU devices
    uint8 constant BUS_PASS_RESOURCE	= 30; // Resource discovery
    uint8 constant BUS_PASS_INTERRUPT	= 40; // Interrupt controllers
    uint8 constant BUS_PASS_TIMER		= 50; // Timers and clocks
    uint8 constant BUS_PASS_SCHEDULER	= 60; // Start scheduler
    uint8 constant BUS_PASS_DEFAULT     = 0xFF; // Everything else.

    uint8 constant BUS_PASS_ORDER_FIRST  = 0;
    uint8 constant BUS_PASS_ORDER_EARLY  = 2;
    uint8 constant BUS_PASS_ORDER_MIDDLE = 5;
    uint8 constant BUS_PASS_ORDER_LATE   = 7;
    uint8 constant BUS_PASS_ORDER_LAST   = 9;
    string constant BUS_LOCATOR_ACPI    = "ACPI";
    string constant BUS_LOCATOR_FREEBSD = "FreeBSD";
    string constant BUS_LOCATOR_UEFI    = "UEFI";

/*#include "device_if.h"
#include "bus_if.h"

struct driver_module_data {
	int		(*dmd_chainevh)(struct module *, int, void *);
	void		*dmd_chainarg;
	string dmd_busname;
	kobj_class_t	dmd_driver;
	devclass_t	*dmd_devclass;
	int		dmd_pass;
}*/
}