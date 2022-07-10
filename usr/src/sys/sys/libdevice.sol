pragma ton-solidity >= 0.61.2;
import "bus.sol";
import "liberr.sol";
import "str.sol";
import "sbuf.sol";
import "libtable.sol";

struct s_bdev {
    uint8 major_id;
    uint8 minor_id;
    uint8 major_version;
    uint8 minor_version;
    uint16 block_size;
    uint32 updated_at;
    string name;
    TvmCell code;
}

struct s_make_dev_args {
	uint16 mda_size;
	uint16 mda_flags;
	string mda_name;
	s_ucred mda_cr;
	uint16 mda_uid;
	uint16 mda_gid;
	uint16 mda_mode;
	uint16 mda_unit;
}

struct s_cdevsw {
	uint32 d_version;
	uint32[] d_methods;
	string d_name;
}

struct s_cdev {
	uint16 si_flags;
	uint32 si_atime;
	uint32 si_ctime;
	uint32 si_mtime;
	uint16 si_uid;
	uint16 si_gid;
	uint16 si_mode;
    uint16 si_parent;
    uint16 si_mount;
	s_ucred si_cred;	// cached clone-time credential
//	s_cdev si_parent;
//	s_mount si_mountpt;
	uint16 si_iosize_max;	// maximum I/O size (for physio &al)
	uint16 si_usecount;
	uint16 si_threadcount;
	string si_name;
}

struct s_device_location_node {
	string dln_locator;
	string dln_path;
    uint16 dln_link;
}

struct bio {
    uint16 ordinal;
    uint48 part_no;
    address addr;
}

struct device_location_cache_t {
    s_device_location_node[] list;
}
library libdevice {

    uint16 constant MAKEDEV_ARGS_SIZE = 14;

    uint16 constant DEF_BLOCK_SIZE = 0x3DED;

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

    uint16 constant	DEV_ATTACH       = 1;  // _IOW('D', 1, struct devreq);
    uint16 constant	DEV_DETACH       = 2;  // _IOW('D', 2, struct devreq);
    uint16 constant	DEV_ENABLE       = 3;  // _IOW('D', 3, struct devreq);
    uint16 constant	DEV_DISABLE      = 4;  // _IOW('D', 4, struct devreq);
    uint16 constant	DEV_SUSPEND      = 5;  // _IOW('D', 5, struct devreq);
    uint16 constant	DEV_RESUME       = 6;  // _IOW('D', 6, struct devreq);
    uint16 constant	DEV_SET_DRIVER   = 7;  // _IOW('D', 7, struct devreq);
    uint16 constant	DEV_CLEAR_DRIVER = 8;  // _IOW('D', 8, struct devreq);
    uint16 constant	DEV_RESCAN       = 9;  // _IOW('D', 9, struct devreq);
    uint16 constant	DEV_DELETE       = 10; // _IOW('D', 10, struct devreq);
    uint16 constant	DEV_FREEZE       = 11; // _IOW('D', 11, struct devreq);
    uint16 constant	DEV_THAW         = 12; // _IOW('D', 12, struct devreq);
    uint16 constant	DEV_RESET        = 13; // _IOW('D', 13, struct devreq);
    uint16 constant	DEV_GET_PATH     = 14; // _IOWR('D', 14, struct devreq);
    uint32 constant DEVF_FORCE_DETACH        = 0x0000001; // // Flags for DEV_DETACH and DEV_DISABLE.
    uint32 constant DEVF_SET_DRIVER_DETACH   = 0x0000001; // Detach existing driver.
    uint32 constant DEVF_CLEAR_DRIVER_DETACH = 0x0000001; // Detach existing driver.
    uint32 constant DEVF_FORCE_DELETE        = 0x0000001;
    uint32 constant DEVF_RESET_DETACH        = 0x0000001; // Detach drivers vs suspend device

    using sbuf for s_sbuf;
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


    function quiet(device_t dev) internal {
        dev.flags |= DF_QUIET;
    }
    function quiet_children(device_t dev) internal {
        dev.flags |= DF_QUIET_CHILDREN;
    }
    function set_desc(device_t dev, string desc) internal {
        dev.desc = desc;
    }
    function is_devclass_fixed(device_t dev) internal returns (bool) {
        return (dev.flags & DF_FIXEDCLASS) > 0;
    }

    function set_flags(device_t dev, uint32 flags) internal {
        dev.devflags = flags;
    }
    function claim_softc(device_t dev) internal {
        if (!dev.softc.empty())
		    dev.flags |= DF_EXTERNALSOFTC;
	    else
		    dev.flags &= ~DF_EXTERNALSOFTC;
    }

    function set_softc(device_t dev, bytes softc) internal {
	    if (!dev.softc.empty() && (dev.flags & DF_EXTERNALSOFTC) == 0)
	    	delete dev.softc;
	    dev.softc = softc;
	    if (!dev.softc.empty())
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
        return dev.desc;
    }
    function get_flags(device_t dev) internal returns (uint32) {
        return dev.devflags;
    }
    function get_parent(device_t dev) internal returns (uint16) {
        return dev.parent;
    }
    function get_ivars(device_t dev) internal returns (string) {
        return dev.ivars;
    }
    function set_ivars(device_t dev, string ivars) internal {
        dev.ivars = ivars;
    }

    function get_name(device_t dev) internal returns (string) {
        uint len = dev.nameunit.byteLength();
        if (len > 0)
            return dev.nameunit.substr(0, len - 1);
    }

    function get_devclass(device_t dev) internal returns (uint16) {
        return dev.devclass;
    }

    function get_driver(device_t dev) internal returns (uint16) {
        return dev.driver;
    }

    function get_nameunit(device_t dev) internal returns (string) {
        return dev.nameunit;
    }
    function get_softc(device_t dev) internal returns (bytes) {
        return dev.softc;
    }
    function get_state(device_t dev) internal returns (device_state) {
        return dev.state;
    }
    function get_unit(device_t dev) internal returns (uint16) {
        return dev.unit;
    }

    function set_unit(device_t dev, uint16 unit) internal returns (uint16) {
        dev.unit = unit;
    }
//    function device_get_sysctl_ctx(device_t dev) internal returns (s_sysctl_ctx_list);
//    function device_get_sysctl_tree(device_t dev) internal returns (s_sysctl_oid);
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

    function set_desc_internal(device_t dev, string desc, bool copy) internal {
    	if (!dev.desc.empty() && (dev.flags & libdevice.DF_DESCMALLOCED) == 0) {
    		delete dev.desc;
    		dev.flags &= ~libdevice.DF_DESCMALLOCED;
    	}
    	if (copy && !desc.empty())
    		dev.desc = desc;
    }

    /**
     * Produce the indenting, indent * 2 spaces plus a '.' ahead of that to
     * prevent syslog from deleting initial spaces
     */
    function indentprintf(string[] p, uint indent) internal returns (string s) {
        s = ".";
        for (string s0: p) {
            for (uint iJ = 0; iJ < indent; iJ++)
                s.append("  ");
            s.append(s0);
        }
    }
    function print_device_short(device_t dev, uint indent) internal returns (string) {
	    if (dev.link == 0)
		    return "";
	    indentprintf(["device %d: <%s> %sparent,%schildren,%s%s%s%s%s,%sivars,%ssoftc,busy=%d\n",
	    str.toa(dev.unit), dev.desc,
	    dev.parent > 0 ? "":"no ",
	    dev.children.empty() ? "no ":"",
	    (dev.flags & DF_ENABLED) > 0 ? "enabled,":"disabled,",
	    (dev.flags & DF_FIXEDCLASS) > 0 ? "fixed,":"",
	    (dev.flags & DF_WILDCARD) > 0 ? "wildcard,":"",
	    (dev.flags & DF_DESCMALLOCED) > 0 ? "descmalloced,":"",
	    (dev.flags & DF_SUSPENDED) > 0 ? "suspended,":"",
	    (!dev.ivars.empty() ? "":"no "),
	    (!dev.softc.empty() ? "":"no "),
	     str.toa(dev.busy)], indent);
    }

    function printf(device_t dev, string fmt, string[] ss, uint16[] dd) internal returns (uint8 retval) {
	    string buf;
	    s_sbuf sb;
	    string name;
	    retval = 0;
	    sb.sbuf_new(buf, 128, sbuf.SBUF_FIXEDLEN);
//	    sb.sbuf_set_drain(sbuf_printf_drain, &retval);
	    name = get_name(dev);
	    if (name.empty())
	    	sb.sbuf_cat("unknown: ");
	    else {
//	    	sbuf_printf(&sb, "%s%d: ", name, device_get_unit(dev));
	    	sb.sbuf_cat(name);
            sb.sbuf_cat(str.toa(get_unit(dev)));
        }
        sb.sbuf_vprintf(fmt, ss, dd);
        dev.softc.append(sb.buf);
	    sb.sbuf_finish();
	    sb.sbuf_delete();
	    return retval;
    }

    function make_dev_credf(uint16 flags, s_cdevsw cdevsw, uint16 unit, s_ucred cr, uint16 uid, uint16 gid, uint16 perms, string fmt) internal returns (s_cdev) {
//        return s_cdev()
    }

    function make_dev_credv(uint16 flags, uint16 unit, s_ucred cr, uint16 uid, uint16 gid, uint16 mode, string fmt) internal returns (s_cdev dres) {
    	s_make_dev_args args = s_make_dev_args(MAKEDEV_ARGS_SIZE, flags, fmt, cr, uid, gid, mode, unit);
    	return make_dev_s(args);
    }
    function print_cdev(s_cdev[] cdevs) internal returns (string out) {
        string[][] table = [["Flags", "Accessed", "Changed", "Modified", "UID", "GID", "Mode", "Par", "Mnt", "CR", "I/O", "UC", "TC", "Name"]];
        for (s_cdev c: cdevs) {
	        (uint16 si_flags, uint32 si_atime, uint32 si_ctime, uint32 si_mtime, uint16 si_uid, uint16 si_gid, uint16 si_mode, uint16 si_parent, uint16 si_mount, s_ucred si_cred, uint16 si_iosize_max, uint16 si_usecount, uint16 si_threadcount, string si_name) = c.unpack();
            table.push([str.toa(si_flags), str.toa(si_atime), str.toa(si_ctime), str.toa(si_mtime), str.toa(si_uid), str.toa(si_gid), str.toa(si_mode),
                str.toa(si_parent), str.toa(si_mount), si_cred.cr_loginclass, str.toa(si_iosize_max), str.toa(si_usecount), str.toa(si_threadcount), si_name]);
        }
        out = libtable.format_rows(table, [uint(5), 8, 8, 8, 5, 5, 5, 3, 3, 3, 5, 2, 2, 20], libtable.LEFT);
    }
    function print_ucred(s_ucred[] creds) internal returns (string out) {
        string[][] table = [["Used", "UID", "RUID", "SvUID", "NG", "RGID", "SvGID", "Login Class", "Flags", "Groups"]];
        for (s_ucred c: creds) {
            (uint16 cr_users, uint16 cr_uid, uint16 cr_ruid, uint16 cr_svuid, uint8 cr_ngroups, uint16 cr_rgid, uint16 cr_svgid, string cr_loginclass, uint16 cr_flags, uint16[] cr_groups) = c.unpack();
            table.push([str.toa(cr_users), str.toa(cr_uid), str.toa(cr_ruid), str.toa(cr_svuid), str.toa(cr_ngroups), str.toa(cr_rgid), str.toa(cr_svgid), cr_loginclass, 
                str.toa(cr_flags), str.toa(cr_groups[0])]);
        }
        out = libtable.format_rows(table, [uint(3), 5, 5, 5, 3, 5, 5, 20, 5, 15], libtable.LEFT);
    }

    function newdev(s_make_dev_args args) internal returns (s_cdev) {
        (uint16 mda_size, uint16 mda_flags, string mda_name, s_ucred mda_cr, uint16 mda_uid, uint16 mda_gid, uint16 mda_mode, uint16 mda_unit) = args.unpack();
        uint16 si_mount;
        return s_cdev(mda_flags, now, now, now, mda_uid, mda_gid, mda_mode, mda_unit, si_mount, mda_cr, mda_size, 1, 1, mda_name);
    }
    function prep_devname(s_cdev dev, string fmt) internal returns (uint8) {}
    function make_dev_s(s_make_dev_args args) internal returns (s_cdev dres) {
        (uint16 mda_size, uint16 mda_flags, string mda_name, s_ucred mda_cr, uint16 mda_uid, uint16 mda_gid, uint16 mda_mode, uint16 mda_unit) = args.unpack();
        uint16 si_mount;
        return s_cdev(mda_flags, now, now, now, mda_uid, mda_gid, mda_mode, mda_unit, si_mount, mda_cr, mda_size, 1, 1, mda_name);
    }
    function devtoname(s_cdev dev) internal returns (string) {
        return dev.si_name;
    }
    function get_dev_cdevsw() internal returns (s_cdevsw dev_cdevsw) {
        return s_cdevsw(D_VERSION, [M_devopen, M_devclose, M_devread, M_devioctl, M_devpoll, M_devkqfilter], "devctl");
    }
    function get_dev_cdevsw2() internal returns (s_cdevsw dev_cdevsw) {
        return s_cdevsw(D_VERSION, [M_ioctl2], "devctl2");
    }
}