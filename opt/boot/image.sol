pragma ton-solidity >= 0.67.0;
import "disk_loader.sol";
contract image is disk_loader {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, TvmCell c, mapping (uint32 => TvmCell) m) {
        c;
        m = _ram;
        uint len = args.length;
        string arg0 = len > 0 ? args[0] : "";
//        uint v0 = tou(arg0);
//        v0;
        (bool fb, bool fo, , ) = libflags.flags_set(flags, "boIQ");
        fo;
//        out.append(libvmem.mem_check(m));
//        if (fb)
        out.append(libvmem.dump_mem(m));
        out.append("\n===================\n");
//        mapping (uint32 => TvmCell) m3 = libvmem.remap_pages(m, 0);
//////        if (fo)
//        out.append(libvmem.dump_mem(m3));
//        (disklabel l, part_table pt) = read_label();
//        disk d = libpart.create_disk(arg0, 2, 0);
//        out.append(libpart.print_disk(d));
        uufsd ud = read_ufs_disk();
        fsb f = ud.d_fsb;
        uint ng = f.ncg;
//        vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
//        while (!vino.empty()) {
//            TvmSlice s = vino.pop();
//            if (s.bits() >= 248) {
//                dinode dd = s.decode(dinode);
//                out.append(libsb.print_dino(dd));
//            } else
//                out.append("Thin ino\n");
//        }
//        if ((fa || fr) && !fn) {
//            c = libufs.pack_fs(ud, m);
//        }
//        if (fo) {
//            string s0 = flags[uint8(byte('o'))];
//            uint32 u0 = uint32(tou(s0));
//            out.append(format("Arg: {} val: {}\n", s0, u0));
//            if (u0 > 0) {
//                TvmCell c0 = _ram[u0];
//                (uufsd ud1, mapping (uint32 => TvmCell) m1) = libufs.unpack_fs(c0);
//                m1;
//                out.append(libufs.print_disk(ud1));
//            out.append(libsb.print_sb(f));
//                out.append("\n===================\n");
////            out.append(libufs.print_sb(f1));
//                out.append(libufs.print_disk(ud));
//            }
//            //            (uufsd disk, mapping (uint32 => TvmCell) m1) = libufs.unpack_fs(c);
//        }
////         else {
////            uint16 i;
////            repeat (ng) {
////                cg g = libufs.fetch_cg(f, m, i);
////                out.append(libufs.print_cg(f, g));
////                i++;
////            }
////        }
//        if (fa) {
//            (uufsd ud1, mapping (uint32 => TvmCell) m1) = libufs.unpack_fs(c);
//            out.append(libvmem.dump_bin(m1));
//            out.append(libufs.print_disk(ud1));
////            out.append(libufs.print_sb(f));
//            out.append("\n===================\n");
////            out.append(libufs.print_sb(f1));
//            out.append(libufs.print_disk(ud));
//        }
//
//        out.append("       000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e | 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e");
//        out.append(libvmem.dump_bin(m));
//        out.append(libsb.print_sb(f));
//        out.append(libsb.print_cg(f, ud.d_cg));
//        uint16 i;
//        repeat (ng) {
//            cg g = libsb.fetch_cg(f, m, i);
//            out.append(libsb.print_cg(f, g));
//            i++;
//        }

    }
}
