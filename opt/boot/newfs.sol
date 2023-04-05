pragma ton-solidity >= 0.67.0;
import "label_loader.sol";
contract newfs is label_loader {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, TvmCell c) {
        uint len = args.length;
//        (bool fa, bool fb, bool fc, ) = libflags.flags_set(flags, "abcp");
//        (uint ubsize, uint ubpcg, uint umaxbpg, uint ufsize) = option_values_uint(flags, "bcef");
//        (string svolname, string sdisktype, string sfstype, string spart) = option_values(flags, "LTOp");
        (string spart, , , ) = libflags.option_values(flags, "p");

        (s_disk d, disklabel l, part_table pt) = read_disk();
        l;
        uint8 npart;// = 1;
        string arg0 = len > 0 ? args[0] : "";
        string arg1 = len > 1 ? args[1] : "";
        arg0;
        arg1;
        (uint8 i, partition p) = libpart.get_part(pt, npart, spart);
        if (i == 0)
            (i, p) = libpart.get_part(pt, 1, "");
        if (i == 0)
            err.append("partition " + spart + " not found");
        else {
            out.append(libpart.print_partition(i - 1, p));
            if (p.p_fstype == 0) {
	            uint32 p_size = p.p_size;
	            uint32 p_offset = p.p_offset;
	            uint8 p_fsize = uint8(d.d_sectorsize);
	            uint8 p_fstype = libpart.FS_TOFS;
	            uint8 p_frag = p_fsize * uint8(d.d_fwsectors);
	            uint8 p_cpg = uint8(d.d_fwheads / p_fsize);
                p = partition(p_size, p_offset, p_fsize, p_fstype, p_frag, p_cpg);
                out.append(libpart.print_partition(i - 1, p));
                pt.d_partitions[i - 1] = p;
                out.append(libpart.print_part_table(pt));
                c = abi.encode(pt);
            }
        }
//            fsb f = read_sb(p);
            fsb f = libpart.create_default_fsb(p);
            out.append(libsb.print_sb(f));
//            c = abi.encode(f);
            (cg[] cgs, fss s, fs_summary_info fsi) = libpart.create_default_cgroups(f);
            fsi;
            out.append(libsb.print_fss(s));
            for (cg g: cgs)
                out.append(libsb.print_cg(f, g));
            uufsd ud = libpart.create_default_ufs_disk(f, s, cgs[0]);
//            c = abi.encode(ud);
            c = abi.encode(cgs[3]);
//            out.append(libufs.print_disk(ud));
//            out.append(libufs.print_disk_header(ud));
//            uufsd ud = read_ufs_disk();
//            fsb f = ud.d_fsb;
    }
}
