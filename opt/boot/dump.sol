pragma ton-solidity >= 0.67.0;
import "label_loader.sol";
contract dump is label_loader {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, TvmCell c) {
        return _dump(args, flags);
    }
    function _dump(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, TvmCell c) {
        (bool fa, bool fb, bool fc, bool fd) = libflags.flags_set(flags, "abcd");
//        fsb f = ud.d_fsb;
        mapping (uint32 => TvmCell) m0 = _ram;//libvmem.mmap(_ram, 0, 4);
//        TvmCell c = _ram[0];
//        tvm.hexdump(c);
//        tvm.bindump(c);
        string arg = args.length > 0 ? args[0] : "";
        out.append(libvmem.dump_mem(m0));
        (s_disk d, disklabel l, part_table pt) = read_disk();
//        if (arg == "ufs") out.append(libufs.print_disk(ud));
//        else if (arg == "ud") out.append(libufs.print_disk_header(ud));
        if (arg == "label") out.append(libpart.print_label(l));
        else if (arg == "disk") out.append(libpart.print_disk(d));
        else if (arg == "part") out.append(libpart.print_part_table(pt));
//        else if (arg == "sb") out.append(libsb.print_sb(f));
//        else if (arg == "cg") {
//            uint16 i;
//            repeat (f.ncg) {
//                cg g = libufs.fetch_cg(f, m, i);
//                out.append(libsb.print_cg(f, g));
//                i++;
//            }
//        } else if (arg == "inodes") {
//            vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
//            out.append("USER\tTYPE   DEVICE SIZE/OFF  NODE\n");
//            while (!vino.empty()) {
//                TvmSlice s = vino.pop();
//                if (s.bits() >= 248) {
//                    dinode dd = s.decode(dinode);
////                    out.append(libfattr.print_mode(dd.di_mode));
//    //                out.append(libsb.print_dino(dd));
//                    out.append(libfdt.print_dino_lsof(dd));
//                } else
//                    out.append("Thin ino\n");
//            }
//        }

//        out.append(libvmem.dump_bin(m));
//        uufsd ud = read_ufs_disk();
//        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, ud.d_fsb.cblkno, 20);
//        out.append(libufs.print_disk(ud));

//        vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
//        out.append("USER\tTYPE   DEVICE SIZE/OFF  NODE\n");
//        while (!vino.empty()) {
//            TvmSlice s = vino.pop();
//            if (s.bits() >= 248) {
//                dinode dd = s.decode(dinode);
//                out.append(libfattr.print_mode(dd.di_mode));
////                out.append(libsb.print_dino(dd));
//                out.append(libfdt.print_dino_lsof(dd));
//            } else
//                out.append("Thin ino\n");
//        }
//        fs_summary_info fsi;
////	    uint8[]	si_contigdirs;	// # of contig. allocated dirs
//	    csum[] si_csp;		    // cg summary info buffer
////	    uint32[] si_maxcluster;	// max cluster in each cyl group
////	    uint16 si_active;		// used by snapshots to track fs
//        fsi.si_contigdirs.push(2);
//        si_csp.push(ud.d_cg.cg_cs);
//        fsi.si_csp = si_csp;
//        out.append(libsb.print_fsi(fsi));
//        out.append(libufs.print_disk(ud));
        if (fa) {
//            out.append(libcgfs.print_cgs(m));
        }
//        m.mkdefsb();
//        out.append("\n=======\n");
//        out.append(m.print_sb());
//        m.mksub(FT_DIR, ROOT_DIR, ["bin", "dev", "etc", "home", "mnt", "usr", "var"]);
//        out.append("\n=======\n");
//        out.append(m.print_sb());
        if (fb) {
//            TvmSlice s = m[3].toSlice();
//            out.append(libvmem.dump_slice(s));
        }
        if (fb) {}
        if (fc) {
//            out.append(libvmem.dump_slices(m));
        }
        if (fd) {}

    }
}
