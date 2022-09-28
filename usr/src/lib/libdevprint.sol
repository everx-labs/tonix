pragma ton-solidity >= 0.64.0;
import "libtable.sol";
import "bus_h.sol";
import "libdevclass.sol";
library libdevprint {
//    using libtable for s_table;

    function print_cdev(s_cdev[] cdevs) internal returns (string out) {
        string[][] table = [["Flags", "Accessed", "Changed", "Modified", "UID", "GID", "Mode", "Par", "Mnt", "CR", "I/O", "UC", "TC", "Name"]];
        for (s_cdev c: cdevs) {
	        (uint16 si_flags, uint32 si_atime, uint32 si_ctime, uint32 si_mtime, uint16 si_uid, uint16 si_gid, uint16 si_mode, uint32 si_cred, uint8 si_drv0,
            uint8 si_refcount, uint32 si_parent, uint32 si_mount, uint32 si_drv1, uint32 si_drv2, uint32 si_cdevsw, uint16 si_iosize_max, uint16 si_usecount, uint16 si_threadcount, string si_name) = c.unpack();
            table.push([str.toa(si_flags), str.toa(si_atime), str.toa(si_ctime), str.toa(si_mtime), str.toa(si_uid), str.toa(si_gid), str.toa(si_mode),
                str.toa(si_parent), str.toa(si_mount), str.toa(si_cred), str.toa(si_iosize_max), str.toa(si_usecount), str.toa(si_threadcount), si_name]);
        }
        //out = libtable.format_rows(table, [uint(5), 8, 8, 8, 5, 5, 5, 3, 3, 3, 5, 2, 2, 20], libtable.LEFT);
        return libtable.table_view([uint(5), 8, 8, 8, 5, 5, 5, 3, 3, 3, 5, 2, 2, 20], libtable.LEFT, table);
    }
    function as_row(device_t dev) internal returns (string[]) {
        (uint32 link, address devlink, uint32 parent, uint8[] children, uint32 driver, uint32 devclass, uint8 unit, bytes12 nameunit, bytes20 desc, uint8 busy, device_state state, uint8 devflags, uint16 flags, uint8 order, uint32 ivars, uint32 softc) = dev.unpack();
        return [str.toa(link), str.toa(parent), str.toa(driver), str.toa(devclass), str.toa(unit), str.toa(busy), str.toa(uint8(state)),
            str.toa(devflags), str.toa(flags), str.toa(order), str.toa(ivars), str.toa(softc), format("{}", devlink),
            libstring.null_term(bytes(desc)), libstring.null_term(bytes(nameunit)), libstring.print_byte_array(children)];
    }
    function print_device_table(device_t[] devs) internal returns (string out) {
        if (devs.empty())
            return "No devices";
        string[][] rows = [["N", "par", "drv", "DC", "unit", "B", "St", "Dfl", "fl", "ord", "IV", "SC", "devlink", "desc", "nameunit", "children"]];
        for (device_t dev: devs)
            rows.push(as_row(dev));
        return libtable.table_view([uint(4), 3, 4, 3, 3, 2, 4, 4, 5, 2, 4, 4, 66, 20, 12, 20], libtable.CENTER, rows);
        /*s_table t = libtable.with_header(
            ["N", "par", "drv", "DC", "unit", "B", "St", "Dfl", "fl", "ord", "IV", "SC", "devlink", "desc", "nameunit", "children"],
            [uint(4), 3, 4, 3, 3, 2, 4, 4, 5, 2, 4, 4, 66, 20, 12, 20], libtable.CENTER);
        for (device_t dev: devs)
            t.add_row(as_row(dev));
        return t.compute();*/
    }
    function print_ucred(s_ucred[] creds) internal returns (string out) {
        string[][] table = [["Used", "UID", "RUID", "SvUID", "NG", "RGID", "SvGID", "Login Class", "Flags", "Groups"]];
        for (s_ucred c: creds) {
            (uint16 cr_users, uint16 cr_uid, uint16 cr_ruid, uint16 cr_svuid, uint8 cr_ngroups, uint16 cr_rgid, uint16 cr_svgid, string cr_loginclass, uint16 cr_flags, uint16[] cr_groups) = c.unpack();
            table.push([str.toa(cr_users), str.toa(cr_uid), str.toa(cr_ruid), str.toa(cr_svuid), str.toa(cr_ngroups), str.toa(cr_rgid), str.toa(cr_svgid), cr_loginclass, 
                str.toa(cr_flags), str.toa(cr_groups[0])]);
        }
        return libtable.table_view([uint(3), 5, 5, 5, 3, 5, 5, 20, 5, 15], libtable.LEFT, table);
//        out = libtable.format_rows(table, [uint(3), 5, 5, 5, 3, 5, 5, 20, 5, 15], libtable.LEFT);
    }

    function print_devclass_table(devclass_t[] dcs) internal returns (string out) {
        if (dcs.empty())
            return "No device classes";
        string[][] rows = [["link", "parent", "name", "maxunit", "flags", "drivers", "devices"]];
        // s_table t = libtable.with_header(
        //     ["link", "parent", "name", "maxunit", "flags", "drivers", "devices"],
        //     [uint(4), 4, 20, 10, 4, 7, 7, 20, 20], libtable.CENTER);
        for (devclass_t dc: dcs)
            rows.push(libdevclass.devclass_as_row(dc));
        return libtable.table_view([uint(4), 4, 20, 10, 4, 7, 7, 20, 20], libtable.CENTER, rows);
//            t.add_row(libdevclass.devclass_as_row(dc));
        //return t.compute();
    }
    function print_driver_table(driver_t[] drvs) internal returns (string out) {
        if (drvs.empty())
            return "No drivers";
        string[][] rows = [["version", "name", "methods", "size", "classes", "refs", "updated_at"]];

        //s_table t = libtable.with_header(
        //    ["version", "name", "methods", "size", "classes", "refs", "updated_at"],
        //    [uint(4), 10, 5, 6, 20, 4, 20],  libtable.CENTER);
        for (driver_t dr: drvs)
            rows.push(libdevclass.driver_as_row(dr));
        return libtable.table_view([uint(4), 10, 5, 6, 20, 4, 20], libtable.CENTER, rows);
        //    t.add_row(libdevclass.driver_as_row(dr));
        //return t.compute();
    }
}