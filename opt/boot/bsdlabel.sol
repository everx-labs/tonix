pragma ton-solidity >= 0.67.0;
import "disk_loader.sol";
contract bsdlabel is disk_loader {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, TvmCell c) {
        uint len = args.length;
        string arg = len > 0 ? args[0] : "";
        err;
        (bool fe, , bool fw, ) = libflags.flags_set(flags, "enwR");
        (bool fA, , , ) = libflags.flags_set(flags, "A");
        s_disk d;
        disklabel l;
        part_table pt;

        if (fw) {
            uint8 scheme = libpart.SCHEME_VTOC;
            d = libpart.create_disk(arg, scheme, 0);
            disklabel l1 = libpart.read_standard_label(d);
            out.append(libpart.print_label(l1));
//            c = abi.encode(l1);
//            c = abi.encode(d);
            pt = libpart.create_part_table(scheme);
            c = abi.encode(pt);
        } else
            (d, l, pt) = read_disk();
//        d = abi.decode(_ram[0], disk);
//        out.append(libpart.print_disk(d));
        pt = libpart.create_part_table(3);
        if (fA)
            out.append(libpart.print_label(l));
        if (fe) {
            d = libpart.read_disk_label(l);
            out.append(libpart.print_disk(d));
            out.append(libpart.print_label(l));
            c = abi.encode(d);
        }
        if (arg.empty())
            out.append(libpart.print_part_table(pt));
        else {
            (uint8 i, partition p) = libpart.get_part(pt, uint8(0), arg);
            if (i == 0)
                err.append("partition " + arg + " not found");
            else
                out.append(libpart.print_partition(i - 1, p));
            if (fe) {
                c = abi.encode(i, p);
                (uint8 i1, partition p1) = abi.decode(c, (uint8, partition));
                out.append(libpart.print_partition(i1 - 1, p1));
            }
        }
        if (fw) {
//            (TvmCell lc, TvmCell ptc) = libpart.def_label();
//            c = v0 > 0 ? ptc : lc;
        }
    }
}
