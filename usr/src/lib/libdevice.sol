pragma ton-solidity >= 0.64.0;

import "bus_h.sol";
import "conf.sol";
import "str.sol";
import "sbuf.sol";

/*struct s_bdev {
    uint8 major_id;
    uint8 minor_id;
    uint8 major_version;
    uint8 minor_version;
    uint16 block_size;
    uint32 updated_at;
    string name;
    TvmCell code;
}

struct bio {
    uint16 ordinal;
    uint48 part_no;
    address addr;
}*/

struct device_location_cache_t {
    s_device_location_node[] list;
}
library libdevice {

    uint8 constant MAKEDEV_ARGS_SIZE = 14;

    uint8 constant ENOMEM   = 12; // Cannot allocate memory
    uint8 constant EBUSY    = 16; // Device busy
    uint8 constant EINVAL   = 22; // Invalid argument

    uint16 constant DEF_BLOCK_SIZE = 0x3DED;

    uint16 constant SI_ETERNAL   = 0x0001; // never destroyed
    uint16 constant SI_ALIAS     = 0x0002; // carrier of alias name
    uint16 constant SI_NAMED     = 0x0004; // make_dev{_alias} has been called
    uint16 constant SI_UNUSED1   = 0x0008; // unused
    uint16 constant SI_CHILD     = 0x0010; // child of another struct cdev *
    uint16 constant SI_DUMPDEV   = 0x0080; // is kernel dumpdev
    uint16 constant SI_CLONELIST = 0x0200; // on a clone list
    uint16 constant SI_UNMAPPED  = 0x0400; // can handle unmapped I/O
    uint16 constant SI_NOSPLIT   = 0x0800; // I/O should not be split up

    uint8 constant MAKEDEV_REF	   = 0x01;
    uint8 constant MAKEDEV_WHTOUT  = 0x02;
    uint8 constant MAKEDEV_NOWAIT  = 0x04;
    uint8 constant MAKEDEV_WAITOK  = 0x08;
    uint8 constant MAKEDEV_ETERNAL = 0x10;
    uint8 constant MAKEDEV_CHECKNAME = 0x20;

    uint32 constant D_VERSION       = 22;
    uint32 constant M_devopen       = 50;
    uint32 constant M_devclose      = 51;
    uint32 constant M_devread       = 52;
    uint32 constant M_devioctl      = 53;
    uint32 constant M_devpoll       = 54;
    uint32 constant M_devkqfilter   = 55;
    uint32 constant M_ioctl2        = 455;

    uint8 constant DEV_ATTACH       = 1;  // _IOW('D', 1, struct devreq);
    uint8 constant DEV_DETACH       = 2;  // _IOW('D', 2, struct devreq);
    uint8 constant DEV_ENABLE       = 3;  // _IOW('D', 3, struct devreq);
    uint8 constant DEV_DISABLE      = 4;  // _IOW('D', 4, struct devreq);
    uint8 constant DEV_SUSPEND      = 5;  // _IOW('D', 5, struct devreq);
    uint8 constant DEV_RESUME       = 6;  // _IOW('D', 6, struct devreq);
    uint8 constant DEV_SET_DRIVER   = 7;  // _IOW('D', 7, struct devreq);
    uint8 constant DEV_CLEAR_DRIVER = 8;  // _IOW('D', 8, struct devreq);
    uint8 constant DEV_RESCAN       = 9;  // _IOW('D', 9, struct devreq);
    uint8 constant DEV_DELETE       = 10; // _IOW('D', 10, struct devreq);
    uint8 constant DEV_FREEZE       = 11; // _IOW('D', 11, struct devreq);
    uint8 constant DEV_THAW         = 12; // _IOW('D', 12, struct devreq);
    uint8 constant DEV_RESET        = 13; // _IOW('D', 13, struct devreq);
    uint8 constant DEV_GET_PATH     = 14; // _IOWR('D', 14, struct devreq);
    uint8 constant DEVF_FORCE_DETACH        = 1; // Flags for DEV_DETACH and DEV_DISABLE.
    uint8 constant DEVF_SET_DRIVER_DETACH   = 1; // Detach existing driver.
    uint8 constant DEVF_CLEAR_DRIVER_DETACH = 1; // Detach existing driver.
    uint8 constant DEVF_FORCE_DELETE        = 1;
    uint8 constant DEVF_RESET_DETACH        = 1; // Detach drivers vs suspend device

    using sbuf for s_sbuf;
    using libdevice for device_t;
    uint16 constant DF_ENABLED         = 0x01;	// device should be probed/attached
    uint16 constant DF_FIXEDCLASS      = 0x02;	// devclass specified at create time
    uint16 constant DF_WILDCARD        = 0x04;	// unit was originally wildcard
    uint16 constant DF_DESCMALLOCED    = 0x08;	// description was malloced
    uint16 constant DF_QUIET           = 0x10;	// don't print verbose attach message
    uint16 constant DF_DONENOMATCH     = 0x20;	// don't execute DEVICE_NOMATCH again
    uint16 constant DF_EXTERNALSOFTC   = 0x40;	// softc not allocated by us
    uint16 constant DF_SUSPENDED       = 0x100;	// Device is suspended.
    uint16 constant DF_QUIET_CHILDREN  = 0x200;	// Default to quiet for all my children
    uint16 constant DF_ATTACHED_ONCE   = 0x400;	// Has been attached at least once
    uint16 constant DF_NEEDNOMATCH     = 0x800;	// Has a pending NOMATCH event

    function add_child(device_t parent, string name, uint8 unit, uint8 link) internal returns (device_t dev) {
        dev.link = link;
        dev.parent = parent.link;
        dev.unit = unit;
        dev.flags = DF_ENABLED;
        dev.desc = bytes20("generic " + name + " device");
        if (unit == 0)
            dev.flags |= DF_WILDCARD;
        if (!name.empty()) {
            dev.flags |= DF_FIXEDCLASS;
            dev.nameunit = bytes12(name + str.toa(unit));
        }
        if (parent.has_quiet_children())
            dev.flags |= DF_QUIET | DF_QUIET_CHILDREN;
        dev.state = device_state.DS_NOTPRESENT;
        parent.children.push(link);
    }

    function quiet(device_t dev) internal {
        dev.flags |= DF_QUIET;
    }
    function quiet_children(device_t dev) internal {
        dev.flags |= DF_QUIET_CHILDREN;
    }
    function set_desc(device_t dev, bytes desc) internal {
        dev.desc = bytes20(desc);
    }
    function is_devclass_fixed(device_t dev) internal returns (bool) {
        return (dev.flags & DF_FIXEDCLASS) > 0;
    }

    function set_devclass(device_t dev, uint8 pdc) internal returns (uint8) {
        if (is_devclass_fixed(dev))
            return EINVAL;
        dev.devclass = pdc;
//    function set_devclass(device_t dev, devclass_t dc) internal {
//        dev.devclass = dc.link;
    }
    function set_flags(device_t dev, uint8 flags) internal {
        dev.devflags = flags;
    }
    function claim_softc(device_t dev) internal {
        if (dev.softc > 0)
		    dev.flags |= DF_EXTERNALSOFTC;
	    else
		    dev.flags &= ~DF_EXTERNALSOFTC;
    }

    function prep_devname(string name, uint8 un) internal returns (bytes12 res) {
        return bytes12(name + str.toa(un));
    }
    function prep_devname_old(bytes10 name, uint8 un) internal returns (bytes12 res) {
        return bytes12(string(bytes(name)) + str.toa(un));
    }
    function set_softc(device_t dev, uint32 softc) internal {
	    if (dev.softc > 0 && (dev.flags & DF_EXTERNALSOFTC) == 0)
	    	delete dev.softc;
	    dev.softc = softc;
	    if (dev.softc != 0)
	    	dev.flags |= DF_EXTERNALSOFTC;
	    else
	    	dev.flags &= ~DF_EXTERNALSOFTC;
    }

    function disable(device_t dev) internal {
        dev.flags &= ~DF_ENABLED;
    }
    function enable(device_t dev) internal {
        dev.flags |= DF_ENABLED;
    }
    function get_desc(device_t dev) internal returns (string) {
        return libstring.null_term(bytes(dev.desc));
    }
    function get_flags(device_t dev) internal returns (uint8) {
        return dev.devflags;
    }
    function get_parent(device_t dev) internal returns (uint32) {
        return dev.parent;
    }
    function get_ivars(device_t dev) internal returns (uint32) {
        return dev.ivars;
    }
    function set_ivars(device_t dev, uint32 ivars) internal {
        dev.ivars = ivars;
    }

//    function set_driver(device_t dev, uint32 driver) internal returns (uint8) {
    function set_driver(device_t dev, uint8 driver) internal returns (uint8) {
//    	uint8 domain;
    	//s_domainset policy;
    	if (dev.state >= device_state.DS_ATTACHED)
    		return EBUSY;
    	if (dev.driver == driver)
    		return 0;
    	if (dev.softc > 0 && (dev.flags & DF_EXTERNALSOFTC) == 0) {
//    		free(dev.softc, M_BUS_SC);
    		dev.softc = 0;
    	}
    	//kobj_delete(dev, 0);
        delete dev.desc;
    	dev.driver = driver;
    	if (driver > 0) {
    		/*kobj_init(dev, driver);
    		if ((dev.flags & DF_EXTERNALSOFTC) == 0 && driver.size > 0) {
    			if (bus_get_domain(dev, domain) == 0)
    				policy = DOMAINSET_PREF(domain);
    			else
    				policy = DOMAINSET_RR();
    			dev.softc = malloc_domainset(driver.size, M_BUS_SC, policy, M_NOWAIT | M_ZERO);
    			if (dev.softc == 0) {
    				kobj_delete(dev, 0);
    				kobj_init(dev, null_class);
    				dev.driver = 0;
    				return err.ENOMEM;
    			}
    		}*/
    	} else {
//    		kobj_init(dev, null_class);
    	}
    }

    function get_name(device_t dev) internal returns (string) {
        bytes bb = bytes(dev.nameunit);
        uint len = get_blen(bb); //dev.nameunit.length;
        if (len > 0)
            return string(bb[ : len - 1]);
    }

    function get_devclass(device_t dev) internal returns (uint32) {
        return dev.devclass;
    }

    function get_driver(device_t dev) internal returns (uint32) {
        return dev.driver;
    }

    function get_nameunit(device_t dev) internal returns (string) {
        return libstring.null_term(bytes(dev.nameunit));
    }
    function get_softc(device_t dev) internal returns (uint32) {
        return dev.softc;
    }
    function get_state(device_t dev) internal returns (device_state) {
        return dev.state;
    }
    function get_unit(device_t dev) internal returns (uint16) {
        return dev.unit;
    }

    function set_desc_internal(device_t dev, bytes desc, bool copy) internal {
        if (dev.desc > 0 && (dev.flags & DF_DESCMALLOCED) == 0) {
            delete dev.desc;
            dev.flags &= ~DF_DESCMALLOCED;
        }
        if (copy && !desc.empty()) {
            dev.desc = bytes20(desc);
            dev.flags |= DF_DESCMALLOCED;
        }
    }

    function set_unit(device_t dev, uint8 unit) internal returns (uint8) {
        dev.unit = unit;
    }
    function has_quiet_children(device_t dev) internal returns (bool) {
        return (dev.flags & DF_QUIET_CHILDREN) > 0;
    }
    function is_alive(device_t dev) internal returns (bool) {
        return dev.state >= device_state.DS_ALIVE;
    }
    function is_attached(device_t dev) internal returns (bool) {
        return dev.state >= device_state.DS_ATTACHED;
    }
    function is_enabled(device_t dev) internal returns (bool) {
        return (dev.flags & DF_ENABLED) > 0;
    }
    function is_suspended(device_t dev) internal returns (bool) {
        return (dev.flags & DF_SUSPENDED) > 0;
    }
    function is_quiet(device_t dev) internal returns (bool) {
        return (dev.flags & DF_QUIET) > 0;
    }

    function verbose(device_t dev) internal {
        dev.flags &= ~DF_QUIET;
    }

    function is_busy(device_t dev) internal returns (bool) {
        return dev.busy > 0;
    }
    function set_busy(device_t dev) internal {
        dev.busy++;
    }
    function set_unbusy(device_t dev) internal {
        dev.busy--;
    }

    function get_property(device_t dev, string prop, bytes val, uint16 sz, device_property_type ptype) internal returns (uint16) {

    }
    function has_property(device_t dev, string prop) internal returns (bool) {
//	    return dev.get_property(prop, "", "", device_property_type.DEVICE_PROP_ANY) >= 0;
    }

    function sprintf(device_t dev, string sfmt, string[] ss, uint16[] dd) internal returns (uint8 retval) {
	    string buf;
	    s_sbuf sb;
	    retval = 0;
	    sb.sbuf_new(buf, 128, sbuf.SBUF_FIXEDLEN);
	    string name;// = bytes(get_name(dev));
	    if (name.empty())
	    	sb.sbuf_cat("unknown: ");
	    else {
	    	sb.sbuf_cat(name);
            sb.sbuf_cat(str.toa(dev.unit));
        }
        sb.sbuf_vprintf(sfmt, ss, dd);
//        dev.softc.append(sb.buf);
	    sb.sbuf_finish();
	    sb.sbuf_delete();
	    return retval;
    }

    function newdev(s_make_dev_args args) internal returns (s_cdev) {
        (uint16 mda_size, uint16 mda_flags, uint32 mda_devsw, uint32 mda_cr, uint16 mda_uid, uint16 mda_gid, uint16 mda_mode, uint8 mda_unit, uint32 mda_si_drv1, uint32 mda_si_drv2, string mda_name) = args.unpack();
        uint16 si_mount;
        uint32 tnow = block.timestamp;
        return s_cdev(mda_flags, tnow, tnow, tnow, mda_uid, mda_gid, mda_mode, mda_cr, mda_unit, 0, 0, si_mount, mda_si_drv1, mda_si_drv2, mda_devsw, mda_size, 1, 1, mda_name);
    }
    //function dev_dependsl(s_cdev cdev, s_cdev pdev) internal {
    function dev_dependsl(s_cdev cdev, uint32 pdev) internal {
    	cdev.si_parent = pdev;
    	cdev.si_flags |= SI_CHILD;
//    	LIST_INSERT_HEAD(&pdev->si_children, cdev, si_siblings);
    }

    function make_dev_credf(uint16 flags, uint32 cdevsw, uint8 unit, uint32 cr, uint16 uid, uint16 gid, uint16 perms, string fmt) internal returns (uint8 res, s_cdev dev) {
//	va_list ap;
//	int res;
//	va_start(ap, fmt);
	    (res, dev) = make_dev_credv(flags, cdevsw, unit, cr, uid, gid, perms, fmt);
//	va_end(ap);
//	KASSERT(((flags & MAKEDEV_NOWAIT) != 0 && res == ENOMEM) || ((flags & MAKEDEV_CHECKNAME) != 0 && res != ENOMEM) || res == 0, ("make_dev_credf: failed make_dev_credv (error=%d)", res));
//        return res == 0 ? dev : NULL;
//        return s_cdev()
    }
    function dev2unit(s_cdev d) internal returns (uint8) {
    	return d.si_drv0;
    }
    function make_dev_credv(uint16 flags, uint32 cdevsw, uint8 unit, uint32 cr, uint16 uid, uint16 gid, uint16 mode, string sfmt) internal returns (uint8, s_cdev dres) {
    	s_make_dev_args args = s_make_dev_args(MAKEDEV_ARGS_SIZE, flags, cdevsw, cr, uid, gid, mode, unit, 0, 0, sfmt);
    	return make_dev_s(args);
    }
    //function prep_devname(s_cdev dev, string sfmt) internal returns (uint8) {}
    function make_dev_s(s_make_dev_args args) internal returns (uint8, s_cdev dres) {
        (uint16 mda_size, uint16 mda_flags, uint32 mda_devsw, uint32 mda_cr, uint16 mda_uid, uint16 mda_gid, uint16 mda_mode, uint8 mda_unit, uint32 mda_si_drv1, uint32 mda_si_drv2, string mda_name) = args.unpack();
        uint16 si_mount;
        uint32 tnow = block.timestamp;
        return (0, s_cdev(mda_flags, tnow, tnow, tnow, mda_uid, mda_gid, mda_mode, mda_cr, mda_unit, 0, 0, si_mount, mda_si_drv1, mda_si_drv2, mda_devsw, mda_size, 1, 1, mda_name));
    }
    function devtoname(s_cdev dev) internal returns (string) {
        return dev.si_name;
    }
    function get_dev_cdevsw() internal returns (s_cdevsw dev_cdevsw) {
//        return s_cdevsw(D_VERSION, [M_devopen, M_devclose, M_devread, M_devioctl, M_devpoll, M_devkqfilter], "devctl");
        return s_cdevsw(conf.D_VERSION, 0, "devctl", M_devopen, 0, M_devclose, M_devread, 0, M_devioctl, M_devpoll, 0,
        0, M_devkqfilter, 0, 0, 0);
    }
    function get_dev_cdevsw2() internal returns (s_cdevsw dev_cdevsw) {
//        return s_cdevsw(D_VERSION, [M_ioctl2], "devctl2");
        dev_cdevsw.d_version = conf.D_VERSION;
        dev_cdevsw.d_name = "devctl2";
        dev_cdevsw.d_ioctl = M_ioctl2;
    }
    /*function print_child_header(device_t, device_t child) internal returns (string retval) {
        retval = get_desc(child);
        if (retval.empty())
            return get_nameunit(child);
    }*/

    function get_blen(bytes bb) internal returns (uint len) {
        for (bytes1 b: bb) {
            if (b == 0)
                return len;
            len++;
        }
    }
}