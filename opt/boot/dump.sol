pragma ton-solidity >= 0.67.0;
import "disk_loader.sol";
import "libufsd.sol";
contract dump is disk_loader {

    function pp(uint8 t, TvmCell c) external pure returns (string out) {
        if (t == 0)
            out.append("Invalid content type");
        else if (t == 11)
            out = libufs.print_disk(abi.decode(c, uufsd));
        else if (t == 12)
            out = (libpart.print_disk(abi.decode(c, s_disk)));
        else if (t == 13)
            out = libpart.print_label(abi.decode(c, disklabel));
        else if (t == 14)
            out.append(libpart.print_part_table(abi.decode(c, part_table)));
        else if (t == 15)
            out.append(libsb.print_sb(abi.decode(c, fsb)));
        else if (t == 16) {
            ufsd d = abi.decode(c, ufsd);
            out.append(libufsd.print_disk_header(d));
            out.append(libufsd.print_ug(d.cg));
            out.append(libufsd.print_sb(d.fs));
        } else if (t == 17) {
            ug g = abi.decode(c, ug);
            out.append(libufsd.print_ug(g));
        } else if (t == 18) {
            ufsb sb = abi.decode(c, ufsb);
            out.append(libufsd.print_sb(sb));
        } else if (t == 19) {
            udinode di = abi.decode(c, udinode);
            out.append(libufsd.print_udino(di));
        } else if (t == 20) {
            udirent[] des = abi.decode(c, udirent[]);
            for (udirent de: des)
                out.append(libufsd.print_de(de));
        } else if (t == 21) {
            udinode[] dis = abi.decode(c, udinode[]);
            for (udinode di: dis)
                out.append(libufsd.print_udino(di));
        }
    }
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out) {
        (bool fa, bool fb, bool fc, bool fd) = libflags.flags_set(flags, "abcd");
        uufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m = _ram;//libvmem.mmap(_ram, 0, 4);
        mapping (uint32 => TvmCell) m0 = _ram;//libvmem.mmap(_ram, 0, 4);
        string arg = args.length > 0 ? args[0] : "";
        out.append(libvmem.dump_mem(m0));
        (s_disk d, disklabel l, part_table pt) = read_disk();
        fsb f = read_sb(pt.d_partitions[0]);
        if (arg == "ufs") out.append(libufs.print_disk(ud));
        else if (arg == "ud") out.append(libufs.print_disk_header(ud));

        if (arg == "label") out.append(libpart.print_label(l));
        else if (arg == "disk") out.append(libpart.print_disk(d));
        else if (arg == "part") out.append(libpart.print_part_table(pt));
        else if (arg == "sb") out.append(libsb.print_sb(f));
        else if (arg == "cg") {
            uint16 i;
            repeat (f.ncg) {
                cg g = abi.decode(m[f.cblkno + i], cg);
//                cg g = libufs.fetch_cg(f, m, i);
                out.append(libsb.print_cg(f, g));
                i++;
            }
        } else if (arg == "inodes") {
            vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
            out.append("USER\tTYPE   DEVICE SIZE/OFF  NODE\n");
            while (!vino.empty()) {
                TvmSlice s = vino.pop();
                if (s.bits() >= 248) {
                    dinode dd = s.decode(dinode);
//                    out.append(libfattr.print_mode(dd.di_mode));
    //                out.append(libsb.print_dino(dd));
                    out.append(libfdt.print_dino_lsof(dd));
                } else
                    out.append("Thin ino\n");
            }
        }

        out.append(libvmem.dump_bin(m));
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
    function read_sb(partition p) internal view returns (fsb) {
        uint32 a = p.p_offset;
        if (_ram.exists(a))
            return abi.decode(_ram[a], fsb);
    }
}
