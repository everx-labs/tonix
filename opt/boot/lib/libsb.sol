pragma ton-solidity >= 0.67.0;
import "fs.h";
import "sb.h";
import "uio.h";
import "libfattr.sol";
import "libvmem.sol";
import "libufs.sol";

library libsb {
    using libvmem for vector(TvmBuilder);
    uint16 constant CG_MAGIC    = 0x4347;
    uint8 constant CK_SUPERBLOCK= 0x01;// the superblock
    uint8 constant CK_CYLGRP	= 0x02;	// the cylinder groups
    uint8 constant CK_INODE	    = 0x04;	// inodes
    uint8 constant CK_INDIR	    = 0x08;	// indirect blocks
    uint8 constant CK_DIR		= 0x10;	// directory contents
    uint8 constant CK_SUPPORTED	= 0x07;	// supported flags, others cleared at mount
    function dir_dots(uint16 cur, uint16 par) internal returns (idirent, idirent) {
        return (dir_ent(FT_DIR, cur, "."), dir_ent(FT_DIR, par, ".."));
    }
    function dir_ent(uint8 ft, uint16 ino, bytes nm) internal returns (idirent) {
        return idirent(ft, ino, uint8(nm.length), bytes11(nm));
    }
    function dir_ents(uint8 ft, uint16 start, string[] nms) internal returns (TvmBuilder b) {
        for (bytes bb: nms)
            b.store(dir_ent(ft, start++, bb));
    }
    function scratch_nodes(uint16 dev_id) internal returns (TvmCell c) {
        stat stdev = libfattr.def_bdev_inode(dev_id, BLK_SIZE);
        stat stdir = libfattr.def_dir_inode(stdev);
        (, , , uint16 st_mode, uint16 st_uid, uint16 st_gid, , , , , , , , uint16 st_blksize, ) = stdir.unpack();
        uint8 cnt;
        uint32 tnow = block.timestamp;
        dinode d1 = dinode(stdev.st_mode, cnt++, 1, 0, tnow, tnow, tnow, 0, 0, 0, 0, 0, st_uid, st_gid, 0);
        dinode d2 = d1;
        d2.di_mode = S_IFREG;
        d2.di_ino = cnt++;
        (idirent id1, idirent id2) = dir_dots(cnt, cnt);
        TvmBuilder b;
        b.store(id1, id2);
        uint16 sz = b.bits() / 8;
        uint8 nb = uint8(sz / st_blksize) + 1;
        dinode d3 = d2;
        d3.di_mode = st_mode;
        d3.di_nlink++;
        d3.di_ino = cnt++;
        d3.di_size = sz;
        d3.di_blocks = nb;
        return abi.encode(d1, d2, d3, id1, id2);
    }
    function uconv(TvmBuilder b, uint16 n) internal returns (TvmCell) {
        TvmSlice s = b.toSlice();
        uint16 nb = s.bits();
        uint16 sz = nb / n;
        vector(uint248) vv;
        repeat (n) {
            uint248 v = s.loadUnsigned(sz);
            vv.push(v);
        }
        TvmBuilder b0;
        b0.storeUnsigned(n - 1, 2);
        while (!vv.empty())
            b0.store(vv.pop());
        return b0.toCell();
    }
    function pack_sbs(fsb f, mapping (uint32 => TvmCell) m) internal returns (TvmCell) {
        TvmBuilder b;
        uint8 p = f.sblkno;
        b.store(m[p++]);
        b.store(m[p++]);
        return b.toCell();
    }
    function pack_cgs(fsb f, mapping (uint32 => TvmCell) m) internal returns (TvmCell) {
        TvmBuilder b;
        uint8 ng = f.ncg;
        TvmBuilder bcgs;
        uint8 p = f.cblkno;
        repeat (ng)
            bcgs.store(m[p++]);
        b.store(bcgs.toCell());
        TvmBuilder bbbm;
        repeat (ng)
            bbbm.store(m[p++]);
        b.store(bbbm.toCell());
        TvmBuilder bibm;
        repeat (ng)
            bibm.store(m[p++]);
        b.store(bibm.toCell());
        return b.toCell();
    }
    function pack_inode_tables(fsb f, mapping (uint32 => TvmCell) m) internal returns (TvmCell) {
        TvmBuilder bitbl;
        uint8 ng = f.ncg;
        uint16 n;
        repeat (ng) {
            cg g = libsb.fetch_cg(f, m, n);
            if (g.cg_magic == CG_MAGIC)
                bitbl.store(pack_cg_nodes(g, m));
            n++;
        }
        return bitbl.toCell();
    }
    function pack_cg_nodes(cg g, mapping (uint32 => TvmCell) m) internal returns (TvmCell) {
        uint nitbls = math.divc(g.cg_initediblk, 4);
        TvmBuilder b;
        uint16 i;
        repeat (nitbls) {
            b.store(m[g.cg_niblk + i]);
            i++;
        }
        return b.toCell();
    }
    function fetch_cg(fsb f, mapping (uint32 => TvmCell) m, uint16 n) internal returns (cg) {
        TvmSlice s = libvmem.fuword(m, uint16(f.cblkno + n) * 4);
        if (s.bits() >= 248)
            return s.decode(cg);
    }
    function fetch_ino(fsb f, mapping (uint32 => TvmCell) m, uint16 n) internal returns (dinode) {
        TvmSlice s = libvmem.fuword(m, uint16(f.iblkno + n) * 4);
        if (s.bits() >= 248)
            return s.decode(dinode);
    }
    function print_sb(fsb f) internal returns (string out) {
        (uint16 magic, uint8 sblkno, uint8 cblkno, uint8 iblkno, uint8 dblkno, uint8 ncg, uint8 bsize, uint8 fsize,
        uint8 frag, uint8 minfree, uint8 maxcontig, uint16 maxbpg, uint16 id, uint8 fsbtodb, uint8 ipg, uint16 bpg,
        uint16 fpg, , uint8 sbsize, uint8 csaddr, uint8 cssize, uint8 cgsize, uint8 ino_size, uint8 de_size, ) = f.unpack();
        out.append(format("M 0x{:X} S{} C{} I{} D{} BSZ{} FSZ{} frag{} MF{} MXC{} MXB{} id{} ",
            magic, sblkno, cblkno, iblkno, dblkno, bsize, fsize, frag, minfree, maxcontig, maxbpg, id));
        out.append(format("F2DB{} ipg{} bpg{} fpg{} ncg{} csa{} SZ: sb{} cs{} cg{} ino{} de{}\n",
            fsbtodb, ipg, bpg, fpg, ncg, csaddr, sbsize, cssize, cgsize, ino_size, de_size));
    }
    function print_fss(fss f) internal returns (string out) {
        (uint8 fmod, uint8 clean, uint8 cgrotor, uint16 si, uint16 metaspace, uint16 sblockactualloc, uint16 sblockloc,
        csum_total cstotal, uint32 time, uint16 size, uint16 dsize, ) = f.unpack();
        out.append(format("metaspc {} sbact {} sbloc {} ", metaspace, sblockactualloc, sblockloc));
        out.append(format("fmod {} clean {} cgrotor {} si {} time {} size {} dsize {}\n",
            fmod, clean > 0 ? "Y" : "N", cgrotor, si, time, size, dsize));
        out.append(print_fs_summary(cstotal));
    }

    function print_cg_header(cg g) internal returns (string out) {
        (uint16 magic, uint8 cgx, csum cs, uint8 ndblk, uint8 iusedoff, uint8 freeoff, uint8 clusteroff,
        uint8 nclusterblks, uint8 niblk, uint8 rotor, uint8 frotor, uint8 irotor, uint8 nextfreeoff,
        uint8 initediblk, uint8 unrefs, uint8 ckhash, uint8 space, )  = g.unpack();
        out.append(format("0x{:X} cgx{} ndblk{} iused{} freeoff{} clusoff{} nclust{} niblk{} rotor{} frotor{} irotor{} nfreeoff{} initediblk{} unrefs {} ckhash {} space {}\n",
            magic, cgx, ndblk, iusedoff, freeoff, clusteroff, nclusterblks, niblk, rotor, frotor, irotor, nextfreeoff, initediblk, unrefs, ckhash, space));
        out.append(print_cg_summary(cs));
    }
    function print_cg(fsb f, cg g) internal returns (string out) {
        (, uint8 cg_cgx, csum cg_cs, , uint8 cg_iusedoff, uint8 cg_freeoff, , , uint8 cg_niblk, , , , uint8 cg_nextfreeoff, , , uint8 cg_ckhash, , ) = g.unpack();
        uint32 cgbase = uint32(f.maxbpg) * cg_cgx;
        (uint8 cs_ndir, uint16 cs_nbfree, uint8 cs_nifree, ) = cg_cs.unpack();
        out.append(format("Group {}: (Blocks 0x{:x}-0x{:x})\n", cg_cgx, cgbase, cgbase + f.maxbpg));
        if ((cg_ckhash & CK_SUPERBLOCK) > 0)
            out.append(format("  Primary superblock at {}, Group descriptors at {}-{}\n", f.sblkno, f.cblkno, f.cblkno + f.ncg - 1));
        out.append(format("  Block bitmap at 0x{:x} (bg #0 + {})\n", cg_freeoff, cg_freeoff));
        out.append(format("  Inode bitmap at 0x{:x} (bg #0 + {})\n", cg_iusedoff, cg_iusedoff));
        out.append(format("  Inode table at 0x{:x} (bg #0 + {})\n", cg_niblk, cg_niblk));
        out.append(format("  {} free blocks, {} free inodes, {} directories\n", cs_nbfree, cs_nifree, cs_ndir));
        out.append(format("  Free blocks: {}-{}\n", cgbase + cg_nextfreeoff, cgbase + f.maxbpg));
//        out.append(format("cg_magic: 0x{:X} cg_cgx: {} cg_ndblk: {} cg_iusedoff: {} cg_freeoff: {} cg_clusteroff: {} cg_nclusterblks: {} cg_niblk: {} cg_space: {}\n",
//            cg_magic, cg_cgx, cg_ndblk, cg_iusedoff, cg_freeoff, cg_clusteroff, cg_nclusterblks, cg_niblk, cg_space));
//        out.append(format("cg_rotor: {} cg_frotor: {} cg_irotor: {} cg_nextfreeoff: {} cg_initediblk: {} cg_unrefs: {} cg_ckhash: {}\n",
//            cg_rotor, cg_frotor, cg_irotor, cg_nextfreeoff, cg_initediblk, cg_unrefs, cg_ckhash));
//        out.append(format("Free inodes: {}-{}\n", 0, ));
    }
    function print_dino(dinode di) internal returns (string out) {
        (uint16 di_mode, uint8 di_ino, uint8 di_nlink, uint16 di_size, uint32 di_mtime, uint32 di_ctime, uint32 di_btime, uint16 di_db1, uint16 di_db2, uint16 di_flags, uint8 di_blocks, uint8 di_gen, uint16 di_uid, uint16 di_gid, ) = di.unpack();
        return format("M {} I {} N {} S {} M {} C {} B {} 1 {} 2 {} F {} B {} G {} U {} G {}\n",
            di_mode, di_ino, di_nlink, di_size, di_mtime, di_ctime, di_btime, di_db1, di_db2, di_flags, di_blocks, di_gen, di_uid, di_gid);
    }
    function print_uio(uio auio) internal returns (string out) {
        (iovec[] uio_iov, uint8 uio_iovcnt, uint16 uio_offset, uint16 uio_resid, uio_seg uio_segflg, uio_rw uio_rwo) = auio.unpack();
        uio_segflg;
        uio_rwo;
        out.append(format("uio_iovcnt {} uio_offset {} uio_resid {}\n", uio_iovcnt, uio_offset, uio_resid));
        for (iovec i: uio_iov)
            out.append(format("{} {} ", i.iov_base, i.iov_len));
    }
    function print_fs_summary(csum_total cst) internal returns (string out) {
        (uint16 ndir, uint16 nbfree, uint16 nifree, uint16 nffree, uint16 numclusters) = cst.unpack();
        out.append(format("ndir {} nbfree {} nifree {} nffree {} numclusters {}\n",
            ndir, nbfree, nifree, nffree, numclusters));
    }
    function print_cg_summary(csum cgs) internal returns (string out) {
        (uint8 cs_ndir, uint16 cs_nbfree, uint8 cs_nifree, ) = cgs.unpack();
        out.append(format("{} free blocks, {} free inodes, {} directories\n", cs_nbfree, cs_nifree, cs_ndir));
    }
    function print_fsi(fs_summary_info fsi) internal returns (string out) {
        (uint8[] si_contigdirs, csum[] si_csp, uint32[] si_maxcluster, uint16 si_active) = fsi.unpack();
        out = "si_contigdirs:";
        for (uint i: si_contigdirs)
            out.append(format(" {}", i));
        out.append(" si_csp:");
        for (csum cs: si_csp)
            out.append(print_cg_summary(cs));
        out.append(" si_maxcluster:");
        for (uint i: si_maxcluster)
            out.append(format(" {}", i));
        out.append(format(" si_active: {}\n", si_active));
    }
    function print_fsrecovery(fsrecovery fsr) internal returns (string out) {
        (uint16 fsr_magic, uint8 fsr_fsbtodb, uint8 fsr_sblkno, uint16 fsr_fpg, uint8 fsr_ncg) = fsr.unpack();
        return format("fsr_magic: 0x{:X} fsr_fsbtodb: {} fsr_sblkno: {} fsr_fpg: {} fsr_ncg: {}\n", fsr_magic, fsr_fsbtodb, fsr_sblkno, fsr_fpg, fsr_ncg);
    }
}