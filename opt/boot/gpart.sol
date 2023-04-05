pragma ton-solidity >= 0.67.0;
import "label_loader.sol";
contract gpart is label_loader {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, TvmCell c) {
        return _gpart(args, flags);
    }
    function _gpart(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, TvmCell c) {
        uint len = args.length;
        string arg0 = len > 0 ? args[0] : "";
        string arg1 = len > 1 ? args[1] : "";
        uint v1 = tou(arg1);
        (bool fa, bool fb, bool ff, bool fi) = libflags.flags_set(flags, "abfi");
        (bool fn, bool ffs, bool ft, ) = libflags.flags_set(flags, "nst");
        (string sattr, string sflags, string ssch, string stype) = libflags.option_values(flags, "afst");
        (uint ustart, uint uindex, uint unentries, uint usize) = libflags.option_values_uint(flags, "bins");
        if (fa) sattr;
        if (ff) sflags;
        if (fb) ustart;
        v1;
        usize;
        if (ft) {
            if (stype == "boot") {}
            else if (stype == "swap") {}
            else if (stype == "ufs") {}
        }
        uint8 scheme;
        if (ffs) {
            scheme = libpart.parse_part_scheme(ssch);
        }
//        part_table pt = read_part_table((uint32(15) << 8) + scheme);
        (s_disk d, disklabel l, part_table pt) = read_disk();
        l;
        uint8 ui = uint8(uindex);
//        (disklabel l, part_table pt) = read_label();
        uint8 i;
        partition p;
        if (fi) {
            (i, p) = libpart.get_part(pt, ui, arg1);
            if (i == 0)
                err.append("partition " + arg1 + " not found");
            else
                out.append(libpart.print_partition(i - 1, p));
        }
        if (arg0 == "add") {
        } else if (arg0 == "backup") {

        } else if (arg0 == "commit") {
        } else if (arg0 == "create") {
            unentries;
//            uint8 nen = (unentries > 0 && unentries <= libpart.MAXPARTITIONS) ? uint8(unentries) : libpart.MAXPARTITIONS;
            d = libpart.create_disk(arg1, scheme, 0);
            part_table pt0 = libpart.create_part_table(scheme);
            if (!fn) {
                out.append(libpart.print_part_table(pt0));
                out.append(libpart.print_disk(d));
            }
            c = abi.encode(pt0);
        } else if (arg0 == "delete") {
        } else if (arg0 == "modify") {
            out.append("modify type: " + stype);
            if (stype == "boot") {}
            else if (stype == "swap") {
                p.p_fstype = libpart.FS_SWAP;
                pt.d_partitions[i - 1] = p;
                out.append(libpart.print_part_table(pt));
                c = abi.encode(pt);
            }
            else if (stype == "ufs") {}
        } else if (arg0 == "recover") {
        } else if (arg0 == "resize") {
        } else if (arg0 == "restore") {
        } else if (arg0 == "set") {
        } else if (arg0 == "show") {
            if (!fi)
                out.append(libpart.print_part_table(pt));
        } else if (arg0 == "undo") {
        } else if (arg0 == "unset") {
        }
    }
    function tou(string s) internal pure returns (uint val) {
        optional (int) p = stoi(s);
        if (p.hasValue())
            return uint(p.get());
    }
}
