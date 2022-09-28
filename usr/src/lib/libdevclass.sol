pragma ton-solidity >= 0.64.0;
import "bus_h.sol";
import "libdevice.sol";

library libdevclass {
    using libstring for string;
    uint16 constant DC_HAS_CHILDREN = 1;
    uint8 constant EEXIST   = 17; // File exists
//    using libtable for s_table;

    function create(string classname) internal returns (devclass_t dc) {
        dc.name = bytes10(classname);
    }
    function get_name(devclass_t dc) internal returns (string) {
    	return libstring.null_term(bytes(dc.name));
    }
    function set_parent(devclass_t dc, devclass_t pdc) internal {
    	dc.parent = pdc.link;
    }
    function get_parent(devclass_t dc) internal returns (uint32) {
    	return dc.parent;
    }
    function get_maxunit(devclass_t dc) internal returns (uint8) {
    	if (dc.link == 0)
    		return 0;
    	return dc.maxunit;
    }
    function get_device(devclass_t dc, uint8 unit) internal returns (uint32) {
    	if (dc.link != 9 && unit >= 0 && unit < dc.maxunit)
    	    return dc.devices[unit];
    }
    function get_count(devclass_t dc) internal returns (uint8 count) {
        return uint8(dc.devices.length);
    }

    /*function get_drivers(devclass_t dc) internal returns (uint8 ec, driverlink_t[] listp, uint8 countp) {
        return (0, dc.drivers, uint8(dc.drivers.length));
    }*/

    function delete_device(devclass_t dc, device_t dev) internal returns (uint8) {
    	if (dc.link == 0 || dev.link == 0)
    		return 0;
//    	PDEBUG("%s in devclass %s", [DEVICENAME(dev), DEVCLANAME(dc)]);
    	if (dev.devclass != dc.link || dc.devices[dev.unit] != dev.link)
//    		panic("devclass_delete_device: inconsistent device class");
            return 0;
    	dc.devices[dev.unit] = 0;
    	if ((dev.flags & libdevice.DF_WILDCARD) > 0)
    		dev.unit = 0;
    	dev.devclass = 0;
        delete dev.nameunit;
    }
    function alloc_unit(devclass_t dc, device_t , uint8 unitp) internal returns (uint8 ec, uint8 unit) {
        unit = unitp;
      	if (unit != 0) {
    		if (unit >= 0 && unit < dc.maxunit && dc.devices[unit] != 0)
    			ec = EEXIST;
    	} else {
    		unit = 0;
    		for (unit = 0;; unit++) {
    			// If this device slot is already in use, skip it
    			if (unit < dc.maxunit && dc.devices[unit] != 0)
    				continue;
    			// If there is an "at" hint for a unit then skip it
//    			if (resource_string_value(dc.name, unit, "at", s) == 0)
//    				continue;
    			break;
    		}
    	}
    	//  We've selected a unit beyond the length of the table, so let's extend the table to make room for all units up to and including this one.
    	if (unit >= dc.maxunit)
            dc.maxunit++;
//    	PDEBUG("now: unit %d in devclass %s", [str.toa(unit), DEVCLANAME(dc)]);
    	ec = 0;
    }

    function PDEBUG2(string a, string[] b, uint16[] d) internal returns (string) {
        return printf(a, b, d) + "\n";
    }
    function printf(string fmts, string[] ss, uint16[] dd) internal returns (string) {
        for (string s: ss)
            fmts.subst("%s", s);
        for (uint16 d: dd)
            fmts.subst("%d", str.toa(d));
        return fmts;
    }
    function indentprintf(string fmts, string[] p, uint16[] d, uint indent) internal returns (string s) {
        s = ".";
        repeat (indent)
            s.append("  ");
        s.append(printf(fmts, p, d));
    }

    function devclass_as_row(devclass_t dc) internal returns (string[]) {
        (uint8 link, uint8 parent, uint8[] drivers, bytes10 name, uint8[] devices, uint8 maxunit, uint16 flags) = dc.unpack();
        return ([str.toa(link), str.toa(parent), libstring.null_term(bytes(name)),
                str.toa(maxunit), str.toa(flags), libstring.print_byte_array(drivers), libstring.print_byte_array(devices)]);
    }

    function driver_as_row(driver_t dr) internal returns (string[]) {
        (uint16 version, bytes10 name, uint32 methods, uint16 size, uint8[] baseclasses, uint8 refs, uint32 updated_at) = dr.unpack();
        return [str.toa(version), libstring.null_term(bytes(name)), str.toa(methods), str.toa(size), 
            libstring.print_byte_array(baseclasses), str.toa(refs), str.toa(updated_at)];
    }
}
