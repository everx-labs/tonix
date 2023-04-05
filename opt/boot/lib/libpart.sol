pragma ton-solidity >= 0.67.0;
import "bio.h";
import "disk.h";
import "fs.h";

import "libufs.sol";
import "libvmem.sol";

library libpart {
    using libvmem for vector(TvmBuilder);
    using libpart for partition;
    string constant	_PATH_DISKTAB = "/etc/disktab";
    uint8 constant BSD_NPARTS_MIN	= 8;
    uint8 constant BSD_NPARTS_MAX	= 20;
    uint16 constant BSD_BOOTBLOCK_SIZE= 3800;// Size of bootblock area in sector-size neutral bytes
    uint8 constant BSD_PART_RAW	    = 2;    // partition containing whole disk
    uint8 constant BSD_PART_SWAP	= 1;// partition normally containing swap
    uint8 constant BSD_NDRIVEDATA	= 5;// Drive-type specific data size (in number of 32-bit inegrals)
    uint8 constant BSD_NSPARE		= 5;    // Number of spare 32-bit integrals following drive-type data
    uint16 constant BSD_MAGIC   = 0x8256; // The disk magic number
    uint8 constant LABELSECTOR	= 1;			// sector containing label
    uint8 constant LABELOFFSET	= 0;			// offset of label in sector
    uint16 constant DISKMAGIC	= BSD_MAGIC;	// The disk magic number
    uint8 constant MAXPARTITIONS= BSD_NPARTS_MIN;
    uint16 constant BBSIZE		= BSD_BOOTBLOCK_SIZE; // Size of bootblock area in sector-size neutral bytes
    uint8 constant LABEL_PART	= BSD_PART_RAW;
    uint8 constant RAW_PART	    = BSD_PART_RAW;
    uint8 constant SWAP_PART	= BSD_PART_SWAP;
    uint8 constant NDDATA		= BSD_NDRIVEDATA;
    uint8 constant NSPARE		= BSD_NSPARE;
    uint8 constant SCHEME_UNKNOWN = 0;
    uint8 constant SCHEME_GPT   = 1;
    uint8 constant SCHEME_MBR   = 2;
    uint8 constant SCHEME_VTOC  = 3;
    uint8 constant DTYPE_DEC	= 3;  // other DEC (rk, rl)
    uint8 constant FS_UNUSED	= 0;	// unused
    uint8 constant FS_SWAP		= 1;	// swap
    uint8 constant FS_TOFS		= 2;	// ToFS
    uint8 constant D_REMOVABLE	= 0x01;	// removable media
    uint8 constant D_ECC		= 0x02;	// supports ECC
    uint8 constant D_BADSECT	= 0x04;	// supports bad sector forw.
    uint8 constant D_RAMDISK	= 0x08;	// disk emulator
    uint8 constant D_CHAIN		= 0x10;	// can do back-back transfers
    string[31] constant FN = [
    "unused", "swap", "ToFS", "Version 7", "System V", "4.1BSD", "Eighth Edition", "4.2BSD", "MSDOS", "4.4LFS",
    "unknown", "OS/2 HPFS", "ISO 9660", "boot", "vinum", "raid", "Filecore", "ext2fs", "NTFS", "?", "ccd", "JFS2",
    "Hammer", "Hammer2", "UDF", "?", "EFS", "ZFS", "?", "?", "nandfs"];
    uint8 constant BIO_READ	    = 0x01;	// Read I/O data
    uint8 constant BIO_WRITE	= 0x02;	// Write I/O data
    uint8 constant BIO_DELETE	= 0x03;	// TRIM or free blocks, i.e. mark as unused
    uint8 constant BIO_GETATTR	= 0x04;	// Get GEOM attributes of object
    uint8 constant BIO_FLUSH	= 0x05;	// Commit outstanding I/O now
    uint8 constant BIO_CMD0	    = 0x06;	// Available for local hacks
    uint8 constant BIO_CMD1	    = 0x07;	// Available for local hacks
    uint8 constant BIO_CMD2	    = 0x08;	// Available for local hacks
    uint8 constant BIO_ZONE	    = 0x09;	// Zone command
    uint8 constant BIO_SPEEDUP	= 0x0a;	// Upper layers face shortage
    uint8 constant BIO_ERROR	= 0x01;	// An error occurred processing this bio.
    uint8 constant BIO_DONE	    = 0x02;	// This bio is finished.
    uint8 constant BIO_ONQUEUE	= 0x04;	// This bio is in a queue & not yet taken.
    function assess() internal returns (uint8 sbsize, uint8 cssize, uint8 cgsize, uint8 inosize, uint8 desize) {
        TvmBuilder b;
        fsb f;
        b.store(f);
        sbsize = uint8(b.bits() / 8);
        csum_total ct;
        b.store(ct);
        TvmBuilder b1;
        csum cs;
        b1.store(cs);
        cssize = uint8(b1.bits() / 8);
        delete b1;
        cg g;
        b1.store(g);
        cgsize = uint8(b1.bits() / 8);
        delete b1;
//        dinode di;
        udinode di;
        b1.store(di);
        inosize = uint8(b1.bits() / 8);
        delete b1;
//        idirent de;
        udirent de;
        b1.store(de);
        desize = uint8(b1.bits() / 8);
    }
    function create_default_ufs_disk(fsb f, fss s, cg g) internal returns (uufsd ud) {
        ud = uufsd("", 1, 0, f.bsize, f.sblkno, s.si, f.iblkno, 0, 0, 0, f, s, g, 0, 0, 0, s.sblockloc, 0, 0);
    }
    function create_default_fsb(partition p) internal returns (fsb f) {
        (, uint32 p_offset, uint8 p_fsize, uint8 p_fstype, uint8 p_frag, ) = p.unpack();
        if (p_fstype >= FS_TOFS && p_fsize > 0) {
            uint8 frag = p_frag / p_fsize;
            uint8 ng = libufs.MINCYLGRPS;
            uint16 id = (uint16(FS_TOFS) << 8) + 2;
            (uint8 sbsize, uint8 cssize, uint8 cgsize, uint8 inosize, uint8 desize) = assess();
            uint8 ipg = libufs.IPG;
            uint8 inoblocks = math.muldivc(inosize, ipg, p_frag);
            uint8 sblkno = uint8(p_offset & 0xFF);
            uint8 cblkno = sblkno + 2;
            uint8 iblkno = cblkno + ng * 3;
            uint8 dblkno = iblkno + ng * inoblocks;
            f = fsb(libufs.CGFS_MAGIC, sblkno, cblkno, iblkno, dblkno, ng, p_frag, p_fsize, frag, libufs.MINFREE,
                libufs.FS_MAXCONTIG, libufs.MAXBPG, id, libufs.FSBTODB,
                ipg, libufs.MAXBPG, libufs.MAXBPG * frag, id, sbsize, 0, cssize, cgsize, inosize, desize, 0);
        }
    }
    function create_default_cgroups(fsb f) internal returns (cg[] cgs, fss s, fs_summary_info fsi) {
        (, uint8 sblkno, uint8 cblkno, , uint8 dblkno, uint8 ng, uint8 bsize, ,
        , , , , , , uint8 ipg, uint16 bpg, , , , , , , , , ) = f.unpack();
        csum cg_cs = csum(0, bpg, ipg, 0);
        csum[] csp;
        uint8 cg_iusedoff = cblkno + ng * 2;
        uint8 cg_freeoff = cblkno + ng;
        uint8 cg_niblk = cblkno + ng * 3;
        uint8 ibpg = ipg / 4 + 1;
        uint16 cs_ndir;
        uint16 cs_nbfree;
        uint16 cs_nifree;
        uint16 cs_nffree;
        uint16 cs_numclusters;
        cg g = cg(libufs.CG_MAGIC, 0, cg_cs, 0, cg_iusedoff, cg_freeoff, 0, 0, cg_niblk, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        uint i;
        while (true) {
            csp.push(cg_cs);
            cgs.push(g);
            cs_nbfree += bpg;
            cs_nifree += ipg;
            if (i + 1 >= ng)
                break;
            i++;
            g.cg_cgx++;
            g.cg_iusedoff++;
            g.cg_freeoff++;
            g.cg_niblk += ibpg;
        }
        fsi.si_csp = csp;
        csum_total cstotal = csum_total(cs_ndir, cs_nbfree, cs_nifree, cs_nffree, cs_numclusters);
        uint16 metaspace = uint16(bsize) * dblkno;
        uint16 size = cs_nbfree;
        uint16 dsize = size - dblkno;
        uint16 sblockloc = sblkno;
        uint16 si = sblockloc + 2;
        s = fss(0, 1, 0, si, metaspace, sblockloc, sblockloc, cstotal, block.timestamp, size, dsize, 0);
    }
    function queue_bio(bio_queue bq, bio b, uint32 a) internal {
        bq.queue.push(b);
        bq.total++;
        bq.batched++;
        bq.insert_point = a;
    }
    function create_bio(uint8 cmd, bytes[] bb) internal returns (bio) {
        uint8 flags;
        uint32 dev;
        uint32 dsk;
        uint bcount;
        uint32 data;
        TvmCell[] ma;
        uint8 ma_n = uint8(bb.length);
        uint32 resid;
        if (cmd == BIO_WRITE) {
            for (bytes b: bb) {
                bcount += b.length;
                ma.push(abi.encode(b));
            }
            resid = uint32(bcount);
        } else if (cmd == BIO_READ) {
            for (bytes b: bb) {
                b;
            }
        }
        uint32 pblkno;
        return bio(cmd, flags, dev, dsk, 0, resid, data, ma, ma_n, 0, resid, resid, 0, block.timestamp, pblkno);
    }
    function create_disk(string name, uint8 t, uint8 n) internal returns (s_disk d) {
        disk_geometry dg = def_disk_geometry(t);
        disk_type dt = def_disk_type(t);
        (, uint16 d_secsize, uint16 d_nsectors, , uint16 d_ncylinders, uint16 d_secpercyl, uint32 d_secperunit) = dg.unpack();
        (, , uint8 d_subtype, bytes8 d_typename, bytes8 d_packname, ) = dt.unpack();
	    uint16 d_flags;
	    uint32 d_mediasize = d_secpercyl * d_ncylinders;
	    uint32 d_maxsize = d_secperunit;
        return s_disk(false, false, disk_init_level.DISK_INIT_CREATE, d_flags, name, n, d_secsize, d_mediasize,
            d_nsectors, d_ncylinders, d_maxsize, bytes(d_typename), bytes(d_packname), t, d_subtype, name + format("{}", n));
    }
    function parse_part_scheme(string ssch) internal returns (uint8 scheme) {
        if (ssch == "GPT")
            scheme = SCHEME_GPT;
        else if (ssch == "MBR")
            scheme = SCHEME_MBR;
        else if (ssch == "VTOC")
            scheme = SCHEME_VTOC;
        else
            scheme = SCHEME_UNKNOWN;
    }
    function read_disk_label(disklabel l) internal returns (s_disk d) {
        (, uint8 dtype, uint8 subtype, bytes8 typename, bytes8 packname, , uint8 secsize, uint8 nsectors, ,
            uint16 ncylinders, uint16 secpercyl, uint16 secperunit, , , , , , uint8 flags, bytes16 drivedata, ) = l.unpack();
        bytes bb = bytes(drivedata);
        uint len = bb.length;
	    string name = len > 2 ? bb [ : 2] : "";
	    uint8 unit = len > 2 ? uint8(bb[2]) : 0;
        if (unit >= 0x30)
            unit -= 0x30;
        return s_disk(false, false, disk_init_level.DISK_INIT_CREATE, flags, name, unit, secsize, uint32(ncylinders) * secpercyl,
            nsectors, ncylinders, secperunit, bytes(typename), bytes(packname), dtype, subtype, bb);
    }
    function read_standard_label(s_disk d) internal returns (disklabel l) {
        (, , , uint16 d_flags, string d_name, uint8 d_unit, uint16 d_sectorsize,
            uint32 d_mediasize, uint16 d_fwsectors, uint16 d_fwheads, uint32 d_maxsize, string d_ident,
            string d_descr, uint16 d_hba_vendor, uint16 d_hba_device, string d_attachment) = d.unpack();
        uint8 d_ntracks = 1;
        d_maxsize;
        (uint32 d_secpercyl, uint32 d_sparespercyl) = math.divmod(d_mediasize, d_fwheads);
        uint8 d_sparespertrack = uint8(d_sparespercyl / d_ntracks);
        uint8 d_acylinders;
        return disklabel(DISKMAGIC, uint8(d_hba_vendor), uint8(d_hba_device), bytes8(d_ident), bytes8(d_descr), 0, uint8(d_sectorsize),
            uint8(d_fwsectors), d_ntracks,
            d_fwheads, uint16(d_secpercyl), uint16(d_mediasize), d_sparespertrack, uint8(d_sparespercyl), d_acylinders, 0,
            0, uint8(d_flags), bytes16(d_attachment.empty() ? d_name + format("{}", d_unit) : d_attachment), DISKMAGIC);
    }
    function get_part(part_table pt, uint8 npart, bytes name) internal returns (uint8 i, partition p) {
        if (npart > 0) {
            i = npart;
        } else if (!name.empty()) {
            uint8 v = uint8(name[0]);
            if (v >= 0x61)
                i = v - 0x60;
        }
        if (i > 0 && i <= pt.d_npartitions)
            p = pt.d_partitions[i - 1];
        else
            i = 0;
    }
    function map_ufs_disk(uufsd ud) internal returns (vector(TvmBuilder) argv) {
        fsb f = ud.d_fsb;
        (, , uint8 cblkno, , , uint8 ng, , , , , , , , , uint8 ipg, uint16 bpg, , , , , , , , , ) = f.unpack();
        uint8 ibpg = ipg / 4 + 1;
        TvmBuilder b2;
        b2.store(f);
        argv.vadd(b2, 1);
        delete b2;
        b2.store(ud.d_fss);
        argv.vadd(b2, 1);
        delete b2;
        csum cs = csum(0, bpg, ipg, 0);
        cg g0 = cg(libufs.CG_MAGIC, 0, cs, 0, cblkno + ng * 2, cblkno + ng, 0, 0, cblkno + ng * 3, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        TvmBuilder b;
        b.store(g0);
        argv.vadd(b, 1);
        delete b;
        cg g = g0;
        repeat (ng - 1) {
            g.cg_cgx++;
            g.cg_iusedoff++;
            g.cg_freeoff++;
            g.cg_niblk += ibpg;
            TvmBuilder b3;
            b3.store(g);
            argv.vadd(b3, 1);
        }
        uint248 bbmp;
        uint248 bbmp0 = 1;
        b.store(bbmp0, bbmp, bbmp, bbmp);
        repeat (ng)
            argv.vadd(b, 4);
        uint248 bino;
        delete b;
        b.store(bino);
        repeat (ng)
            argv.vadd(b, 1);
        TvmCell citbl = libsb.scratch_nodes(libufs.CG_MAGIC);
        (dinode d1, dinode d2, dinode d3, idirent id1, idirent id2) = abi.decode(citbl, (dinode, dinode, dinode, idirent, idirent));
        delete b;
        b.store(d1, d2, d3);
        argv.vadd(b, 3);
        delete b;
        b.store(id1, id2);
        argv.vadd(b, 2);
    }
    function add_partition(part_table t, uint16 sz) internal {
        partition p;
        if (t.d_npartitions > 0)
            p = t.d_partitions[t.d_npartitions - 1];
        p.p_offset += p.p_size;
        p.p_size = sz;
        t.d_partitions.push(p);
        t.d_npartitions++;
    }
    function def_disk_type(uint8 t) internal returns (disk_type dt) {
        if (t == DTYPE_DEC) {
	        bytes16 d_drivedata;
            return disk_type(DISKMAGIC, t, 2, "Wombat", "Wild", d_drivedata);
        }
    }
    function def_disk_geometry(uint8 t) internal returns (disk_geometry dg) {
        if (t == DTYPE_DEC) {
    	    uint8 d_secsize = 31;
    	    uint8 d_nsectors = 4;
    	    uint8 d_ntracks = 1;//2;
    	    uint16 d_ncylinders = 1211;
            uint16 d_secpercyl = uint16(d_nsectors) * d_ntracks;
            uint32 d_secperunit = uint32(d_secpercyl) * d_ncylinders;
            dg = disk_geometry(DISKMAGIC, d_secsize, d_nsectors, d_ntracks, d_ncylinders, d_secpercyl, d_secperunit);
        }
    }
    function create_partition(partition p, uint32 sz, uint32 off) internal returns (uint32 next_off) {
        p.p_size = sz;
        p.p_offset = off;
        return math.divc(sz + off, 4) * 4;
    }
    function create_part_table(uint8 scheme) internal returns (part_table pt) {
        disk_geometry dg = def_disk_geometry(DTYPE_DEC);
        (, uint16 d_secsize, uint16 d_nsectors, , uint16 d_ncylinders, uint16 d_secpercyl, uint32 d_secperunit) = dg.unpack();
        uint16 blksz = d_secsize * d_nsectors;
        d_ncylinders;
        if (scheme == SCHEME_GPT || scheme == SCHEME_MBR || scheme == SCHEME_VTOC) {
            partition praw;
            partition pboot;
            partition pswap;
            partition pufs_total;
            partition proot;
            partition pufs1;
            partition pufs2;
            partition pufs3;
            uint32 next_off = LABELSECTOR * d_secpercyl + LABELOFFSET;
            uint32 psiz = BBSIZE / d_secsize - next_off;
            next_off = pboot.create_partition(psiz, next_off);
            praw.create_partition(d_secperunit, 0);
            next_off = pswap.create_partition(psiz, next_off);
            pufs_total.create_partition(d_secperunit - next_off, next_off);
            next_off = proot.create_partition(psiz, next_off + LABELSECTOR * d_secpercyl);
            if (scheme == SCHEME_VTOC) {
                next_off = pufs1.create_partition(pufs_total.p_size / 4, next_off);
                next_off = pufs2.create_partition(pufs_total.p_size / 4, next_off);
                next_off = pufs3.create_partition(pufs_total.p_size / 2, next_off);
            } else {
            }
            pt = part_table(BSD_NPARTS_MIN, blksz, uint8(d_secsize),
                [pboot, pswap, praw, proot, pufs1, pufs2, pufs3, pufs_total]);
        }
    }
    function print_partition(uint8 i, partition p) internal returns (string out) {
        (uint32 p_size, uint32 p_offset, uint8 p_fsize, uint8 p_fstype, uint8 p_frag, uint8 p_cpg) = p.unpack();
        string nums = p_fstype >= FS_TOFS ? format("\t  {}    {}    {}", p_fsize, p_frag, p_cpg) : "";
        out.append(format("  {}:\t{}\t{}\t{} {}\n", bytes(bytes1(0x61 + i)), p_size, p_offset, FN[p_fstype], nums));
    }
    function print_part_table(part_table t) internal returns (string out) {
	    (uint8 d_npartitions, uint16 d_bbsize, uint8 d_sbsize, partition[8] d_partitions) = t.unpack();
        out.append(format("{} partitions:  bbsize: {} sbsize: {}\n", d_npartitions, d_bbsize, d_sbsize));
        out.append("#  \tsize\toffset\tfstype\t[fsize bsize bps/cpg]\n");
        for (uint8 i = 0; i < d_npartitions; i++)
            out.append(print_partition(i, d_partitions[i]));
    }
    function print_label(disklabel l) internal returns (string out) {
	    (uint16 d_magic, uint8 d_type, uint8 d_subtype, bytes8 d_typename, bytes8 d_packname, , uint8 d_secsize,
        uint8 d_nsectors, uint8 d_ntracks, uint16 d_ncylinders, uint16 d_secpercyl, uint16 d_secperunit, uint8 d_sparespertrack,
        uint8 d_sparespercyl, uint8 d_acylinders, uint8 d_trackskew, uint8 d_cylskew, uint8 d_flags, bytes16 d_drivedata,
        uint16 d_magic2) = l.unpack();
        out.append(format("0x{:X} type {} sub {} {} pack {} secsz {} nsec {} ntrk {} ncyl {} sec/cyl {} sec/unit {} sp/trk {} sp/cyl {} ",
            d_magic, d_type, d_subtype, bytes(d_typename), bytes(d_packname), d_secsize, d_nsectors, d_ntracks, d_ncylinders,
            d_secpercyl, d_secperunit, d_sparespertrack, d_sparespercyl));
        out.append(format("acyl {} ts{} cs{} flags {} 0x{:X}\n", d_acylinders, d_trackskew, d_cylskew, d_flags, d_magic2));
        out.append(format("type: {}\ndisk: {}\nlabel: {}\nflags: {}\nbytes/sector: {}\nsectors/track: {}\ntracks/cylinder: {}\nsectors/cylinder: {}\n",
            bytes(d_typename), bytes(d_drivedata), "", "", d_secsize, d_nsectors, d_ntracks, d_secpercyl));
        out.append(format("cylinders: {}\nsectors/unit: {}\ntrackskew: {}\ncylinderskew: {}\ndrivedata: {}\n",
            d_ncylinders, d_secperunit, d_trackskew, d_cylskew, bytes(d_drivedata)));
    }
    function print_disk(s_disk d) internal returns (string out) {
	    (bool d_goneflag, bool d_destroyed, disk_init_level	d_init_level, uint16 d_flags, string d_name, uint8 d_unit, uint16 d_sectorsize, uint32 d_mediasize, uint16 d_fwsectors, uint16 d_fwheads, uint32 d_maxsize, string d_ident, string d_descr, uint16 d_hba_vendor, uint16 d_hba_device, string d_attachment) = d.unpack();
        string sinit = d_init_level == disk_init_level.DISK_INIT_NONE ? "None" : d_init_level == disk_init_level.DISK_INIT_CREATE ?
        "Create" : d_init_level == disk_init_level.DISK_INIT_START ? "Start" : d_init_level == disk_init_level.DISK_INIT_DONE ? "DONE" : "Unknown";
        out.append(format("{} {} init {} flags {} name {} unit {} sectorsize {} mediasize {} sectors {} heads {} maxsize {} ident {} descr {} vendor {} device {} attach {}\n",
            d_goneflag ? "gone" : "", d_destroyed ? "destroyed" : "", sinit, d_flags, d_name, d_unit, d_sectorsize, d_mediasize, d_fwsectors, d_fwheads, d_maxsize, d_ident, d_descr, d_hba_vendor, d_hba_device, d_attachment));
    }
    function print_bio(bio b) internal returns (string out) {
        (uint8 cmd, uint8 flags, uint32 dev, uint32 dsk, uint32 offset, uint32 bcount, uint32 data, TvmCell[] ma,
        uint8 ma_n, uint8 error, uint32 resid, uint32 length, uint32 completed, uint32 t0, uint32 pblkno) = b.unpack();
        out.append(format("cmd {} flags {} dev {} disk {} offset {} bcount {} data {} ma {} ma_n {} error {} resid {} length {} completed {} t0 {} pblkno {}\n",
        cmd, flags, dev, dsk, offset, bcount, data, ma.empty() ? "" : abi.decode(ma[0], bytes), ma_n, error, resid, length, completed, t0, pblkno));
    }
    function print_bio_queue(bio_queue bq) internal returns (string out) {
	    (bio[] queue, uint32 last_offset, uint32 insert_point, uint8 total, uint8 batched) = bq.unpack();
        out.append(format("last_offset {} insert_point {} total {} batched {}\n", last_offset, insert_point, total, batched));
        for (bio b: queue)
            out.append(print_bio(b));
    }
}