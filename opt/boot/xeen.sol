pragma ton-solidity >= 0.66.0;

import "disk.h";
import "libstr.sol";
import "libflags.sol";
import "libvmem.sol";
import "libufs.sol";
import "libpart.sol";

struct uufsd2 {
	string d_name;	    // disk name
	uint8 d_ufs;        // decimal UFS version
	uint8 d_fd;		    // raw device file descriptor
	uint32 d_bsize;		// device bsize
	uint32 d_sblock;	// superblock location
	fs_summary_info d_si;// Superblock summary info // fs_summary_info *
	uint16 d_inoblock;	// inode block
	uint16 d_inomin;	// low ino, not ino_t for ABI compat
	uint16 d_inomax;	// high ino, not ino_t for ABI compat
	uint16 d_dp;		// pointer to currently active inode // di_inode *
	ufs d_fs;		    // filesystem information
	fsb d_fsb;		    // filesystem information
    TvmCell d_sb;       // superblock as buffer
	fss d_fss;		    // filesystem information
	cg d_cg;		    // cylinder group
    TvmCell d_buf;      // cylinder group storage
	uint8 d_ccg;		// current cylinder group
	uint8 d_lcg;		// last cylinder group (in d_cg)
    uint8 errno;
	string d_error;		// human readable disk error
	uint16 d_sblockloc;	// where to look for the superblock
	uint8 d_lookupflags;// flags to superblock lookup
	uint8 d_mine;		// internal flags
    string[] dlog;
    mapping (uint32 => TvmCell) d_m;
}

struct ufs {
	uint16 fs_sblkno;		// offset of super-block in filesys
	uint16 fs_cblkno;		// offset of cyl-block in filesys
	uint16 fs_iblkno;		// offset of inode-blocks in filesys
	uint16 fs_dblkno;		// offset of first data after cg
	uint8 fs_ncg;		    // number of cylinder groups
	uint16 fs_bsize;		// size of basic blocks in fs
	uint16 fs_fsize;		// size of frag blocks in fs
	uint8 fs_frag;		    // number of frags in a block in fs
	uint8 fs_minfree;		// minimum percentage of free blocks
	uint32 fs_bmask;		// ``blkoff'' calc of blk offsets
	uint32 fs_fmask;		// ``fragoff'' calc of frag offsets
	uint32 fs_bshift;		// ``lblkno'' calc of logical blkno
	uint32 fs_fshift;		// ``numfrags'' calc number of frags
	uint8 fs_maxcontig;	    // max number of contiguous blks
	uint16 fs_maxbpg;		// max number of blks per cyl group
	uint32 fs_fragshift;	// block to frag shift
	uint8 fs_fsbtodb;		// fsbtodb and dbtofsb shift constant
	uint16 fs_sbsize;		// actual size of super block
	uint32 fs_nindir;		// value of NINDIR
	uint8 fs_inopb;		    // value of INOPB
	uint32 fs_id;		    // unique filesystem id
	uint32 fs_cssize;		// size of cyl grp summary area
	uint16 fs_cgsize;		// cylinder group size
	uint16 fs_old_ncyl;		// cylinders in filesystem
	uint8 fs_old_cpg;		// cylinders per group
	uint8 fs_ipg;		    // inodes per group
	uint16 fs_fpg;		    // blocks per group * fs_frag
	uint8 fs_fmod;		    // super block modified flag
	uint8 fs_clean;		    // filesystem is clean flag
	uint8 fs_ronly;		    // mounted read-only flag
	string fs_fsmnt;	    // name mounted on
	string fs_volname;	    // volume name
	uint32 fs_swuid;		// system-wide uid
	uint8 fs_cgrotor;		// last cg searched
	fs_summary_info fs_si;  // In-core pointer to summary info
	uint16 fs_unrefs;		// number of unreferenced inodes
	uint32 fs_metaspace;	// size of area reserved for metadata
	uint32 fs_sblockactualloc;	// byte offset of this superblock
	uint32 fs_sblockloc;	// byte offset of standard superblock
	csum_total fs_cstotal;	// cylinder summary information
	uint32 fs_time;		    // last time written
	uint32 fs_size;		    // number of blocks in fs
	uint32 fs_dsize;		// number of data blocks in fs
	uint32 fs_csaddr;		// blk addr of cyl grp summary area
	uint16 fs_pendingblocks;// blocks being freed
	uint16 fs_pendinginodes;// inodes being freed
	uint16 fs_avgfilesize;	// expected average file size
	uint8 fs_avgfpdir;		// expected # of files per directory
	uint32 fs_mtime;		// Last mount or fsck time.
	uint8 fs_flags;		    // see FS_ flags below
	uint32 fs_contigsumsize;// size of cluster summary array
	uint8 fs_maxsymlinklen; // max length of an internal symlink
	uint8 fs_old_inodefmt;	// format of on-disk inodes
	uint32 fs_maxfilesize;	// maximum representable file size
	uint32 fs_magic;		// magic number
}

library libufs2 {

    uint32 constant CG_MAGIC = 0x090255;
    using libufs2 for uufsd2;

    uint8 constant	MINE_NAME	= 0x01; /* Internally, track the 'name' value, it's ours. */
    uint8 constant	MINE_WRITE	= 0x02; /* Track if its fd points to a writable device. */
    uint16 constant	AVFILESIZ	= 200;	/* expected average file size */
    uint8 constant	AFPDIR		= 15;	/* expected number of files per directory */
    uint32 constant FS_UFS1_MAGIC	= 0x011954;	// UFS1 fast filesystem magic number
    uint32 constant FS_UFS2_MAGIC	= 0x19540119;	// UFS2 fast filesystem magic number
    uint32 constant FS_BAD_MAGIC	= 0x19960408;	// UFS incomplete newfs magic number
    uint8 constant FS_42INODEFMT	= 1;		// 4.2BSD inode format
    uint8 constant FS_44INODEFMT	= 2;		// 4.4BSD inode format


    uint8 constant EIO      = 5;  // Input/output error
    uint8 constant EBADF    = 9; // Bad file descriptor
    uint8 constant EDOOFUS      = 88; // Programming error
    uint8 constant EINTEGRITY   = 97; // Integrity check failed
    function ERROR(uufsd2 u, string str) internal {
//	if (str != NULL) {
//		fprintf(stderr, "libufs: %s", str);
//		if (errno != 0)
//			fprintf(stderr, ": %s", strerror(errno));
//		fprintf(stderr, "\n");
//	}
	    u.d_error = str;
    }

    function INOPB(ufs f) internal returns (uint16) {
        return f.fs_inopb;
    }

    // Cylinder group macros to locate things in cylinder groups.
    // They calc filesystem addresses of cylinder group data structures.
    function cg_chkmagic(cg cgp) internal returns (bool) {
//        return cgp.cg_magic == CG_MAGIC;
        return cgp.cg_magic == libsb.CG_MAGIC;
    }
    function cg_inosused(cg cgp) internal returns (uint16) {
        return cgp.cg_iusedoff;
    }
    function cg_blksfree(cg cgp) internal returns (uint16) {
        return cgp.cg_freeoff;
    }
    function cg_clustersfree(cg cgp) internal returns (uint16) {
        return cgp.cg_clusteroff;
    }
//    function cg_clustersum(cg cgp) internal returns (uint16) {
//        return cgp.cg_clustersumoff;
//    }
    function fsbtodb(ufs f, uint32 b) internal returns (uint32) {
        return b << f.fs_fsbtodb;
    }
    function dbtofsb(ufs f, uint32 b) internal returns (uint32) {
        return b >> f.fs_fsbtodb;
    }
    function cgbase(ufs f, uint8 c) internal returns (uint32) {
        return f.fs_fpg * c;
    }
    function cgdata(ufs f, uint8 c) internal returns (uint32) {
        return cgdmin(f, c) + f.fs_metaspace;
    }
    function cgmeta(ufs f, uint8 c) internal returns (uint32) {
        return cgdmin(f, c);
    }
    function cgdmin(ufs f, uint8 c) internal returns (uint32) {
        return cgstart(f, c) + f.fs_dblkno;
    }
    function cgimin(ufs f, uint8 c) internal returns (uint32) {
        return cgstart(f, c) + f.fs_iblkno;
    }
    function cgsblock(ufs f, uint8 c) internal returns (uint32) {
        return cgstart(f, c) + f.fs_sblkno;
    }
    function cgtod(ufs f, uint8 c) internal returns (uint32) {
//        return cgstart(f, c) + f.fs_cblkno;
        return c + f.fs_cblkno;
    }
    function cgstart(ufs f, uint8 c) internal returns (uint32) {
        return cgbase(f, c);
    }
    // Macros for handling inode numbers:
    //     inode number to filesystem block offset.
    //     inode number to cylinder group number.
    //     inode number to filesystem block address.
    function ino_to_cg(ufs f, uint16 x) internal returns (uint8) {
        return uint8(x / f.fs_ipg);
    }
    function ino_to_fsba(ufs f, uint16 x) internal returns (uint32) {
        return cgimin(f, ino_to_cg(f, x)) + blkstofrags(f, (x % (f.fs_ipg) / INOPB(f)));
    }
    function ino_to_fsbo(ufs f, uint16 x) internal returns (uint32) {
        return x % INOPB(f);
    }
    // Give cylinder group number for a filesystem block.
    // Give cylinder group block number for a filesystem block.
    function dtog(ufs f, uint32 d) internal returns (uint8) {
        return uint8(d / f.fs_fpg);
    }
    function dtogd(ufs f, uint32 d) internal returns (uint16) {
        return uint16(d % f.fs_fpg);
    }
    function blkoff(ufs f, uint32 loc) internal returns (uint32) {
        return loc & f.fs_bmask;
    }
    function fragoff(ufs f, uint32 loc) internal returns (uint32) {
        return loc & f.fs_fmask;
    }
    function lfragtosize(ufs f, uint32 frag) internal returns (uint32) {
        return frag << f.fs_fshift;
    }
    function lblktosize(ufs f, uint32 blk) internal returns (uint32) {
        return blk << f.fs_bshift;
    }
    function smalllblktosize(ufs f, uint32 blk) internal returns (uint32) {
        return blk << f.fs_bshift;
    }
    function lblkno(ufs f, uint32 loc) internal returns (uint32) {
        return loc >> f.fs_bshift;
    }
    function numfrags(ufs f, uint32 loc) internal returns (uint32) {
        return loc >> f.fs_fshift;
    }
    function blkroundup(ufs f, uint32 size) internal returns (uint32) {
        return size + f.fs_bmask & f.fs_bmask;
    }
    function fragroundup(ufs f, uint32 size) internal returns (uint32) {
        return size + f.fs_fmask & f.fs_fmask;
    }
    function fragstoblks(ufs f, uint32 frags) internal returns (uint32) {
        return frags >> f.fs_fragshift;
    }
    function blkstofrags(ufs f, uint32 blks) internal returns (uint32) {
        return blks << f.fs_fragshift;
    }
    function fragnum(ufs f, uint32 fsb) internal returns (uint32) {
        return fsb & (f.fs_frag - 1);
    }
    function blknum(ufs f, uint32 fsb) internal returns (uint32) {
        return fsb &~ (f.fs_frag - 1);
    }

    function fs_cs(ufs fs, uint8 indx) internal returns (csum) {
        return fs.fs_si.si_csp[indx];
    }
    function strerror(uint8 ec) internal returns (string) {
        return format("{}", ec);
    }

    function clone(uufsd2 d, uufsd ud) internal {
        d.d_name = string(ud.d_name);
        d.d_ufs = ud.d_ufs;
        d.d_fd = ud.d_fd;
        d.d_bsize = ud.d_bsize;
        d.d_sblock = ud.d_sblock;
        d.d_inoblock = ud.d_inoblock;
        d.d_inomin = ud.d_inomin;
        d.d_inomax = ud.d_inomax;
        d.d_dp = ud.d_dp;
        d.d_fsb = ud.d_fsb;
        d.d_fss = ud.d_fss;
        d.d_cg = ud.d_cg;
        d.d_ccg = ud.d_ccg;
        d.d_lcg = ud.d_lcg;
        d.d_sblockloc = ud.d_sblockloc;
        d.d_lookupflags = ud.d_lookupflags;
        d.d_mine = ud.d_mine;
    }
    function map(uufsd2 d, mapping (uint32 => TvmCell) m) internal {
        d.d_m = m;
    }
    function cgread(uufsd2 d) internal returns (int8 rv) {
	    if (d.d_ccg >= d.d_fs.fs_ncg)
	    	return 0;
	    return d.cgread1(d.d_ccg++);
    }
    function cgread1(uufsd2 d, uint8 c) internal returns (int8) {
        uint8 ec = d.cgget(d.d_fd, d.d_fs, c);
        TvmSlice s = libvmem.fuword(d.d_m, uint16(d.d_fsb.cblkno + c) * 4);
        if (s.bits() < 248) {
            d.ERROR("short read from block device");
            return -1;
        }
        cg g = s.decode(cg);
        d.dlog.push(libsb.print_cg_header(g));
    	if (ec == 0) {
    		d.d_lcg = c;
    		return 1;
    	}
	    if (ec == EINTEGRITY) d.ERROR("cylinder group checks failed");
	    else if (ec == EIO) d.ERROR("read error from block device");
        else d.ERROR(strerror(ec));
	    return -1;
    }
    function cgwrite1(uufsd2 disk, uint8 c) internal returns (int8) {
//    	static char errmsg[BUFSIZ];
    	if (c == disk.d_cg.cg_cgx) {
            int8 rv = disk.cgput(disk.d_fd, disk.d_fs, disk.d_cg);
    		if (rv == 0)
    			return 0;
    		if (disk.errno == EIO)
    			disk.ERROR("unable to write cylinder group");
    		else disk.ERROR(strerror(disk.errno));
    		return -1;
    	}
    	string errmsg = format("Cylinder group {} in buffer does not match the cylinder group {} that cgwrite1 requested", disk.d_cg.cg_cgx, c);
    	disk.ERROR(errmsg);
    	disk.errno = EDOOFUS;
    	return -1;
    }
    function cgget(uufsd2 d, uint8 devfd, ufs fs, uint8 n) internal returns (uint8) {
        d.dlog.push(format("cgget: n {} cgtod {} fsz {}", n, cgtod(fs, n), fs.fs_fsize));
    	(uint8 ec, uint16 cnt, TvmCell c) = d.pread(devfd, fs.fs_cgsize, cgtod(fs, n));
        d.dlog.push(format("pread returned ec {} cnt {}", ec, cnt));
//            fsbtodb(fs, cgtod(fs, n)) * (fs.fs_fsize / fsbtodb(fs, 1)));
        cg cgp = libsb.fetch_cg(d.d_fsb, d.d_m, n);
        ec;
    	if (cnt == 0) {
    		d.d_error = "end of file from block device";
    		return EIO;
    	}
    	if (cnt != fs.fs_cgsize) {
    		d.d_error = "short read from block device";
    		return EIO;
    	}
        //TvmSlice s = libvmem.fuword(m, uint16(f.cblkno + n) * 4);
//        TvmSlice s = c.toSlice();
//        if (s.bits() < 248)
//            return EDOOFUS;
//        cg cgp = s.decode(cg);
        d.dlog.push(libsb.print_cg_header(cgp));
        d.dlog.push(libsb.print_cg(d.d_fsb, cgp));
//        d.dlog.push(libsb.print_cg(d.d_fs, cgp));
        if (!cg_chkmagic(cgp) || cgp.cg_cgx != n)
		    return EINTEGRITY;

        d.d_buf = c;
    	return 0;
    }
    function cgput(uufsd2 disk, uint8 devfd, ufs fs, cg cgp) internal returns (int8) {
    	(uint8 ec, uint16 cnt) = disk.pwrite(devfd, abi.encode(cgp), fs.fs_cgsize,
            fsbtodb(fs, cgtod(fs, cgp.cg_cgx)) * (fs.fs_fsize / fsbtodb(fs,1)));
        ec;
    	if (cnt == 0)
    		return -1;
    	if (cnt != fs.fs_cgsize) {
    		disk.d_error = "short write to block device";
    		return -1;
    	}
    	return 0;
    }
    function cgwrite(uufsd2 disk) internal returns (int8) {
	    return disk.cgwrite1(disk.d_cg.cg_cgx);
    }
    function sbread(uufsd2 d) internal returns (int8) {
	    fsb f = d.sbget(d.d_fd, d.d_sblockloc, d.d_lookupflags);
        f;
    }
    function sbwrite(uufsd2 d, uint8 all) internal returns (int8 rv) {
        ufs f;
    	d.ERROR("");
    	rv = d.ufs_disk_write();
    	if (rv == -1) {
    		d.ERROR("failed to open disk for writing");
    		return -1;
    	}
    	f = d.d_fs;
        uint8 errno = d.sbput(d.d_fd, f, all > 0 ? f.fs_ncg : 0);
    	if (errno != 0) {
    		if (errno == EIO) d.ERROR("failed to write superblock");
    		else d.ERROR("unknown superblock write error");
    		return -1;
    	}
    	return 0;
    }
    function bread(uufsd2 disk, uint32 blockno, uint16 size) internal returns (uint16 cnt, TvmCell c) {
    	(, cnt, c) = disk.pread(disk.d_fd, size, (blockno * disk.d_bsize));
    	if (cnt == 0)
    		disk.ERROR("read error from block device");
    	else if (cnt == 0)
    		disk.ERROR("end of file from block device");
    	else if (cnt != size)
    		disk.ERROR("short read or read error from block device");
    }
    function bwrite(uufsd2 disk, uint32 blockno, TvmCell data, uint16 size) internal returns (uint16 cnt) {
    	int8 rv = disk.ufs_disk_write();
    	if (rv == -1) {
    		disk.ERROR("failed to open disk for writing");
            return 0;
        }
    	(, cnt) = disk.pwrite(disk.d_fd, data, size, (blockno * disk.d_bsize));
    	if (cnt == 0)
    		disk.ERROR("write error to block device");
    	else if (cnt != size)
    		disk.ERROR("short write to block device");
    }
    function close(uint8 fd) internal returns (int8) {
        fd;
    }
    function ufs_disk_close(uufsd2 d) internal returns (int8) {
    	d.ERROR("");
    	close(d.d_fd);
    	d.d_fd = 0;
    	delete d.d_inoblock;
    	if ((d.d_mine & MINE_NAME) > 0)
    		delete d.d_name;
    	delete d.d_si;
    	return 0;
    }
    function ufs_disk_fillout(uufsd2 d, string name) internal returns (int8) {
    	if (ufs_disk_fillout_blank(d, name) == -1)
    		return -1;
    	if (sbread(d) == -1) {
    		d.ERROR("could not read superblock to fill out disk");
    		ufs_disk_close(d);
    		return -1;
    	}
    	return 0;
    }
    function ufs_disk_fillout_blank(uufsd2 d, string name) internal returns (int8) {
        d.d_bsize = 1;
	    d.d_name = name;
    }
    function ufs_disk_write(uufsd2 d) internal returns (int8) {
    	uint8 fd;
    	d.ERROR("");
    	if ((d.d_mine & MINE_WRITE) > 0)
    		return (0);
//        fd = open(d.d_name, O_RDWR);
    	if (fd < 0) {
    		d.ERROR("failed to open disk for writing");
    		return -1;
    	}
    	close(d.d_fd);
    	d.d_fd = fd;
    	d.d_mine |= MINE_WRITE;
    	return 0;
    }

//    function ffs_isblock(ufs f, uint cp, uint32 h) internal returns (bool) {
//    	uint mask;
//        uint8 frag = f.fs_frag;
////    	if (frag == 8) return (cp[h] == 0xff);
////    	else if (frag == 4) {
////    		mask = 0x0f << ((h & 0x1) << 2);
////    		return ((cp[h >> 1] & mask) == mask);
////    	} else if (frag == 2) {
////    		mask = 0x03 << ((h & 0x3) << 1);
////    		return ((cp[h >> 2] & mask) == mask);
////    	} else
//        if (frag == 1) {
////    		mask = 0x01 << (h & 0x7);
////    		return ((cp[h >> 3] & mask) == mask);
//    	}
//    	return false;
//    }


    function cgballoc(uufsd2 d) internal returns (uint32) {
//    	u_int8_t *blksfree;
    	uint16 bno;
    	ufs f = d.d_fs;
    	cg cgp = d.d_cg;
//    	uint blksfree = cg_blksfree(cgp);
//    	for (bno = 0; bno < f.fs_fpg / f.fs_frag; bno++)
//    		if (ffs_isblock(f, blksfree, bno))
//    			break;
//    	f.fs_cs(f, cgp.cg_cgx).cs_nbfree--;
//    	ffs_clrblock(fs, blksfree, (long)bno);
//    	ffs_clusteracct(fs, cgp, bno, -1);
    	cgp.cg_cs.cs_nbfree--;
    	f.fs_cstotal.cs_nbfree--;
    	f.fs_fmod = 1;
    	return (cgbase(f, cgp.cg_cgx) + blkstofrags(f, bno));
    }
    function cgbfree(uufsd2 d, uint32, uint32) internal returns (int8) {

    }
    function cgialloc(uufsd2 disk) internal returns (uint16) {
//    	dinode dp2;
    	uint inosused;
    	uint16 ino;
//    	uint16 i;

    	ufs fs = disk.d_fs;
    	cg cgp = disk.d_cg;
    	inosused = cg_inosused(cgp);
//    	for (ino = 0; ino < fs.fs_ipg; ino++)
//    		if (isclr(inosused, ino))
//    			break;
//    	if (fs.fs_magic == FS_UFS2_MAGIC &&
//    	    ino + INOPB(fs) > cgp.cg_initediblk && cgp.cg_initediblk < cgp.cg_niblk) {
////    		char block[MAXBSIZE];
////    		bzero(block, (int)fs.fs_bsize);
////    		dp2 = (struct ufs2_dinode *)&block;
////    		for (i = 0; i < INOPB(fs); i++) {
//////    			dp2.di_gen = arc4random();
////    			dp2++;
////    		}
//    		if (bwrite(disk, ino_to_fsba(fs, cgp.cg_cgx * fs.fs_ipg + cgp.cg_initediblk), block, fs.fs_bsize))
//    			return (0);
//    		cgp.cg_initediblk += INOPB(fs);
//    	}

//    	setbit(inosused, ino);
    	cgp.cg_irotor = uint8(ino);
    	cgp.cg_cs.cs_nifree--;
    	fs.fs_cstotal.cs_nifree--;
//    	fs.fs_si.si_csp[cgp.cg_cgx].cs_nifree--;
    	fs.fs_fmod = 1;

    	return (ino + (cgp.cg_cgx * fs.fs_ipg));

    }
    function _va(uint32 offset) internal returns (uint8 ng, uint16 nb) {
    }
    function _va2(ufs fs, uint32 offset) internal returns (uint8 ng, uint16 nb) {
        return (dtog(fs, offset), dtogd(fs, offset));
    }

//        (, uint ncyl, uint nfrag) = _va(base);
//        vector(TvmSlice) vs = vuload(m[uint32(ncyl)].toSlice());
//        uint nb = s.bits();
//        if (nb > 2) {
//            uint ni = s.loadUnsigned(2);
//            ni;
//            (uint nf, uint nrem) = math.divmod(nb - 2, 248);
//            repeat (nf)
//                fv.push(s.loadSlice(248));
//            if (nrem > 0)
//                fv.push(s.loadSlice(uint16(nrem)));
//        }    
    function pread(uufsd2 disk, uint8 d, uint16 nbytes, uint32 offset) internal returns (uint8 ec, uint16 cnt, TvmCell c) {
        if (d != disk.d_fd)
            ec = EBADF;
        (uint8 ng, uint16 nb) = _va2(disk.d_fs, offset);
        disk.dlog.push(format("pread: reading {} bytes from offset {} => cg {} block {} {}",
            nbytes, offset, ng, nb, disk.d_m.exists(nb) ? "Block found" : "No block at address"));
        c = disk.d_m[nb];
        cnt = nbytes;
        disk.dlog.push(libvmem.dump_slice(c.toSlice()));
    }

    function pwrite(uufsd2 disk, uint8 d, TvmCell buf, uint16 nbytes, uint32 offset) internal returns (uint8 ec, uint16 cnt) {
        if (d != disk.d_fd)
            ec = EBADF;
        (uint8 ng, uint16 nb) = _va2(disk.d_fs, offset);
        disk.dlog.push(format("pwrite: writing {} bytes from offset {} => cg {} block {} {}",
            nbytes, offset, ng, nb, disk.d_m.exists(nb) ? "Block found" : "No block at address"));
        disk.d_m[nb] = buf;
        cnt = nbytes;
    }
    function getinode(uufsd2 disk, uint16 inum) internal returns (dinode di) {
    	uint16 min;
        uint16 max;
    	uint32 inoblock;
    	ufs fs;
    	fs = disk.d_fs;
    	if (inum >= fs.fs_ipg * fs.fs_ncg) {
    		disk.ERROR("inode number out of range");
            return di;
        }
    	inoblock = disk.d_inoblock;
    	min = disk.d_inomin;
    	max = disk.d_inomax;

//    	if (inoblock == NULL) {
//    		inoblock = malloc(fs->fs_bsize);
//    		if (inoblock == NULL) {
//    			disk.ERROR("unable to allocate inode block");
//    			return (-1);
//    		}
//    		disk.d_inoblock = inoblock;
//    	}
    	if (inum < min || inum >= max) {
        	( , TvmCell c) = disk.bread(fsbtodb(fs, ino_to_fsba(fs, inum)), fs.fs_bsize);
        	disk.d_inomin = min = inum - (inum % INOPB(fs));
        	disk.d_inomax = max = min + INOPB(fs);
            disk.d_m[inoblock] = c;
        }

//    		disk.d_dp = dinode[inum - min];
//    		if (dp != NULL)
//    			*dp = disk.d_dp;
    }
    function putinode(uufsd2 disk) internal returns (int8) {
    	ufs fs = disk.d_fs;
    	if (disk.d_inoblock == 0) {
    		disk.ERROR("No inode block allocated");
    		return -1;
    	}
        uint16 cnt = disk.bwrite(fsbtodb(fs, ino_to_fsba(disk.d_fs, disk.d_inomin)),
            disk.d_m[disk.d_inoblock], disk.d_fs.fs_bsize);
    	if (cnt == 0)
    		return -1;
    	return 0;
    }
    function sbget(uufsd2 d, uint8 devfd, uint16 sblockloc, uint8 flags) internal returns (fsb f) {

    }
    function sbput(uufsd2 d, uint8 devfd, ufs f, uint8 numalt) internal returns (uint8) {

    }

    uint16 constant P_HDR = 0x01;
    uint16 constant P_UFS = 0x02;
    uint16 constant P_MEM = 0x04;
    uint16 constant P_FSB = 0x08;
    uint16 constant P_FSS = 0x10;
    uint16 constant P_CG = 0x20;
    uint16 constant P_FSI = 0x40;
    uint16 constant P_ALL = 0x7F;
    function print_ufs(uufsd2 ud, uint16 flags) internal returns (string out) {
        (string d_name, uint8 d_ufs, uint8 d_fd, uint32 d_bsize, uint32 d_sblock, fs_summary_info d_si,
            uint16 d_inoblock, uint16 d_inomin, uint16 d_inomax, uint16 d_dp, ufs d_fs, fsb d_fsb, ,
            fss d_fss, cg d_cg, TvmCell d_buf, uint8 d_ccg, uint8 d_lcg, uint8 errno, string d_error, uint16 d_sblockloc,
            uint8 d_lookupflags, uint8 d_mine, string[] dlog, mapping (uint32 => TvmCell) d_m) = ud.unpack();
        if (errno > 0 || !d_error.empty())
            out.append(format("!!! en {} error {}\n", errno, d_error));
        if ((flags & P_HDR) > 0) {
            out.append(format("name {} ufs {} fd {} bsize {} sblock {} inoblock {} inomin {} inomax {} dp {} ",
                bytes(d_name), d_ufs, d_fd, d_bsize, d_sblock, d_inoblock, d_inomin, d_inomax, d_dp));
            out.append(format("ccg {} lcg {} error {} sblockloc {} lookupflags {} mine {}\n",
                d_ccg, d_lcg, d_error, d_sblockloc, d_lookupflags, d_mine));
        }
        if ((flags & P_UFS) > 0) out.append(print_ufs(d_fs));
        if ((flags & P_MEM) > 0) out.append(libvmem.dump_mem(d_m));
        if ((flags & P_FSB) > 0) out.append(libsb.print_sb(d_fsb));
        if ((flags & P_FSS) > 0) out.append(libsb.print_fss(d_fss));
        if ((flags & P_CG) > 0) {
            out.append(format("ccg {} lcg {} en {} error {}\n", d_ccg, d_lcg, errno, d_error));
            out.append(libsb.print_cg(d_fsb, d_cg));
            out.append(libvmem.dump_slice(d_buf.toSlice()) + "\n");
//            out.append(libvmem.dump_mem(d_m));
        }
        if ((flags & P_FSI) > 0) out.append(libsb.print_fsi(d_si));
        for (string l: dlog)
            out.append(l + "\n");
//        if ((flags & P_ALL        ) > 0) out.append(print_     )());
    }
    function print_disk_header(uufsd2 ud) internal returns (string out) {
        (string d_name, uint8 d_ufs, uint8 d_fd, uint32 d_bsize, uint32 d_sblock, fs_summary_info d_si,
            uint16 d_inoblock, uint16 d_inomin, uint16 d_inomax, uint16 d_dp, ufs d_fs, fsb d_fsb, TvmCell d_sb,
            fss d_fss, cg d_cg, TvmCell d_buf, uint8 d_ccg, uint8 d_lcg, uint8 errno, string d_error, uint16 d_sblockloc,
            uint8 d_lookupflags, uint8 d_mine, ,) = ud.unpack();
        out.append(print_ufs(d_fs));
        errno;
//        d_fs;
        d_cg;
        d_sb;
        d_buf;
        out.append(format("name {} ufs {} fd {} bsize {} sblock {} inoblock {} inomin {} inomax {} dp {} ",
            bytes(d_name), d_ufs, d_fd, d_bsize, d_sblock, d_inoblock, d_inomin, d_inomax, d_dp));
        out.append(format("ccg {} lcg {} error {} sblockloc {} lookupflags {} mine {}\n",
            d_ccg, d_lcg, d_error, d_sblockloc, d_lookupflags, d_mine));
        out.append(libsb.print_sb(d_fsb));
        out.append(libsb.print_fss(d_fss));
//        out.append(libsb.print_cg(d_fsb, d_cg));
        out.append(libsb.print_fsi(d_si));
    }

    function inherit_ufs(uufsd2 d) internal {
        ufs fs = d.d_fs;
        fsb f = d.d_fsb;
        fs.fs_sblkno = f.sblkno;
        fs.fs_cblkno = f.cblkno;
        fs.fs_iblkno = f.iblkno;
        fs.fs_dblkno = f.dblkno;
        fs.fs_ncg = f.ncg;
        fs.fs_bsize = f.bsize; // 128; // f.bsize;
        fs.fs_fsize = f.fsize; // 32; // f.fsize;
        fs.fs_frag = f.frag;
        fs.fs_minfree = f.minfree;
        fs.fs_bmask = ~(uint32(128) - 1);// ~(fs.fs_bsize - 1);
        fs.fs_fmask = ~(uint32(32) - 1);// ~(fs.fs_fsize - 1);
        fs.fs_bshift = 7; // log2(fs.fs_bsize);
        fs.fs_fshift = 5; // log2(fs.fs_fsize);
        fs.fs_fragshift = 2; //log2(fs.fs_frag);
        fs.fs_maxcontig = f.maxcontig;
        fs.fs_maxbpg = f.maxbpg;
        fs.fs_fsbtodb = f.fsbtodb;
        fs.fs_sbsize = f.sbsize;
//        fs.fs_nindir = f.nindir;

        fs.fs_inopb = uint8(fs.fs_bsize / f.inosize);

        fs.fs_id = f.id;
        fs.fs_cssize = f.cssize;
        fs.fs_cgsize = f.cgsize;
        fs.fs_ipg = f.ipg;
        fs.fs_fpg = f.fpg;

        fss s = d.d_fss;

        fs.fs_fmod = s.fmod;
        fs.fs_clean = s.clean;
        fs.fs_swuid = f.swuid;
        fs.fs_cgrotor = s.cgrotor;

        fs.fs_metaspace = s.metaspace;
        fs.fs_sblockactualloc = s.sblockactualloc;
        fs.fs_sblockloc = s.sblockloc;
        fs.fs_cstotal = s.cstotal;
        fs.fs_time = s.time;
        fs.fs_size = s.size;
        fs.fs_dsize = s.dsize;
        fs.fs_csaddr = f.csaddr;

        fs.fs_avgfilesize = AVFILESIZ;
        fs.fs_avgfpdir = AFPDIR;
        fs.fs_mtime = now;
        fs.fs_maxsymlinklen = 20;
        fs.fs_old_inodefmt = FS_42INODEFMT;
        fs.fs_maxfilesize = 64000;
        fs.fs_magic = FS_UFS1_MAGIC;
        d.d_fs = fs;
//uint32 fs_nindir
//uint16 fs_old_ncyl
//uint8 fs_old_cpg
//fs_summary_info fs_si
//uint8 fs_flags
//uint32 fs_contigsumsize
    }
    function print_ufs(ufs fs) internal returns (string out) {
        (uint16 sblkno, uint16 cblkno, uint16 iblkno, uint16 dblkno, uint8 ncg, uint16 bsize, uint16 fsize, uint8 frag,
        uint8 minfree, , , uint32 bshift, uint32 fshift, uint8 maxcontig, uint16 maxbpg,
        uint32 fragshift, uint8 ufsbtodb, uint16 sbsize, uint32 nindir, uint8 inopb, uint32 id, uint32 cssize,
        uint16 cgsize, uint16 old_ncyl, uint8 old_cpg, uint8 ipg, uint16 fpg, uint8 fmod, uint8 clean, uint8 ronly,
        string fsmnt, string volname, uint32 swuid, uint8 cgrotor, fs_summary_info si, uint16 unrefs, uint32 metaspace,
        uint32 sblockactualloc, uint32 sblockloc, csum_total cstotal, , uint32 size, uint32 dsize, uint32 csaddr,
        uint16 pendingblocks, uint16 pendinginodes, uint16 avgfilesize, uint8 avgfpdir, ,
        uint8 flags, uint32 contigsumsize, uint8 maxsymlinklen, uint8 old_inodefmt, uint32 maxfilesize, uint32 magic) = fs.unpack();
        out.append(format("S{} C{} I{} D{} ncg{} bsize{} fsize{} frag{} mif{} bsh{} fsh{} mxcont{} maxbpg{} fragsh{} fsbtodb{} sbsz{} nindir{} inopb{} id{} cssz{}\n",
            sblkno, cblkno, iblkno, dblkno, ncg, bsize, fsize, frag, minfree, bshift, fshift, maxcontig,
            maxbpg, fragshift, ufsbtodb, sbsize, nindir, inopb, id, cssize));
        out.append(format("cgsize {} ncyl{} cpg{} ipg {} fpg {} {} {} {} fsmnt {} vol {} swuid {} cgrot{} unr{} meta{} sbact {} sbloc {} sz{} dsz{} csaddr {}\n",
            cgsize, old_ncyl, old_cpg, ipg, fpg, fmod > 0 ? "MOD" : "", clean > 0 ? "CL" : "", ronly > 0 ? "RO" : "", fsmnt, volname, swuid, cgrotor, unrefs, metaspace, sblockactualloc, sblockloc, size, dsize, csaddr));
        out.append(format("PB{} PI{} AFS{} AFD{} flags {} ContSum{} MSym{} IFmt {} MAxF {}  0x{:X}\n",
            pendingblocks, pendinginodes, avgfilesize, avgfpdir, flags, contigsumsize, maxsymlinklen, old_inodefmt, maxfilesize, magic));
        out.append(libsb.print_fs_summary(cstotal));
        out.append(libsb.print_fsi(si));
    }
}

contract xeen {
    TvmCell _rom;
    uint32 _version;
    mapping (uint32 => TvmCell) _ram;
    using libvmem for mapping (uint32 => TvmCell);

    using libufs for uufsd;
    using libufs2 for uufsd2;

    function _ufs(string[] args, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal pure returns (string out, string err, uint32 a, TvmCell c) {
        uufsd2 d;
        d.clone(ud);
        out.append(libvmem.dump_bin(m));
        mapping (uint32 => TvmCell) m3 = libvmem.remap_pages(m, 0);
        out.append(libvmem.dump_mem(m3));
        d.map(m);
//        d.map(m3);
//        out.append(libufs2.print_disk_header(d));
        d.inherit_ufs();
//        out.append(libufs2.print_disk_header(d));
//        out.append(libufs2.print_ufs(d, libufs2.P_ALL));
        flags;
        uint len = args.length;
        string cmd = len > 0 ? args[0] : "";
        string arg = len > 1 ? args[1] : "";
        uint8 n = uint8(tou(arg));
        int8 rv;
        uint16 sz;
        uint16 ip;
        dinode di;
        uint16 i;
        fsb f = d.d_fsb;
            repeat (f.ncg) {
                cg g = libufs.fetch_cg(f, m, i);
                out.append(libsb.print_cg(f, g));
                i++;
            }
        if (cmd == "cgread") {
            out.append(libufs2.print_ufs(d, libufs2.P_CG));
            rv = d.cgread();
            out.append(libufs2.print_ufs(d, libufs2.P_CG + libufs2.P_MEM));
        }
        else if (cmd == "cgread1") {
            out.append(libufs2.print_ufs(d, libufs2.P_CG));
            rv = d.cgread1(n);
            out.append(libufs2.print_ufs(d, libufs2.P_CG  + libufs2.P_MEM));
        }
        else if (cmd == "cgwrite1") {
            out.append(libufs2.print_ufs(d, libufs2.P_CG));
            rv = d.cgwrite1(n);
            out.append(libufs2.print_ufs(d, libufs2.P_CG));
        }
        else if (cmd == "sbread") rv = d.sbread();
        else if (cmd == "sbwrite") rv = d.sbwrite(0);
        else if (cmd == "bread") (sz, c) = d.bread(n, 0);
        else if (cmd == "bwrite") sz = d.bwrite(n, c, 0);
        else if (cmd == "ufs_disk_close") rv = d.ufs_disk_close();
        else if (cmd == "ufs_disk_fillout") rv = d.ufs_disk_fillout(arg);
        else if (cmd == "ufs_disk_fillout_blank") rv = d.ufs_disk_fillout_blank(arg);
        else if (cmd == "ufs_disk_write") rv = d.ufs_disk_write();
        else if (cmd == "cgballoc") a = d.cgballoc();
        else if (cmd == "cgbfree") rv = d.cgbfree(a, sz);
        else if (cmd == "cgialloc") ip = d.cgialloc();
        else if (cmd == "cgwrite") rv = d.cgwrite();
        else if (cmd == "getinode") di = d.getinode(n);
        else if (cmd == "putinode") rv = d.putinode();
        else if (cmd == "all") {
            rv = d.cgread();
            rv = d.cgread1(n);
            rv = d.cgwrite1(n);
            rv = d.sbread();
            rv = d.sbwrite(0);
            (sz, c) = d.bread(n, 0);
            sz = d.bwrite(n, c, 0);
            rv = d.ufs_disk_close();
            rv = d.ufs_disk_fillout(arg);
            rv = d.ufs_disk_fillout_blank(arg);
            rv = d.ufs_disk_write();
            a = d.cgballoc();
            rv = d.cgbfree(a, sz);
            ip = d.cgialloc();
            rv = d.cgwrite();
            di = d.getinode(n);
            rv = d.putinode();
        }

        if (rv < 0)
            err.append(format("cmd {}, rv {}\n", cmd, rv));
        else
            out.append(format("cmd {}, rv {}\n", cmd, rv));

//        out.append(libufs2.print_disk_header(d));
    }

    function _help(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err) {
        if (args.empty()) {
            for (cmd_info ci: CI) {
                (, string name, string synopsis, , , , ) = ci.unpack();
                out.append(name + " " +  synopsis + "\n");
            }
        }
        (bool fd, bool fm, bool ffs, ) = libflags.flags_set(flags, "dms");
        for (string s: args) {
            uint8 c2;
            for (uint i = 1; i < CI.length; i++) {
                if (CI[i].name == s) {
                    c2 = uint8(i);
                    break;
                }
            }
            if (c2 == CMD_UNKNOWN)
                return (out, "-gash: help: no help topics match `" + s + "'.  Try `help help' or `man -k " + s + "' or `info " + s + "'.");
            cmd_info ci;
            if (c2 <= CMD_LAST && c2 > 0)
                ci = CI[c2];
            (, string name, string synopsis, , string short_desc, string long_desc, string[] optlist) = ci.unpack();
            if (fd)
                out.append(name + " - " + short_desc + "\n");
            else if (ffs)
                out.append(name + ": " + name + " " + synopsis + "\n");
            else {
                if (fm)
                    out.append("NAME\n    " + name + " - " + short_desc + "\n\nSYNOPSIS\n    " + name + " " + synopsis + "\n\nDESCRIPTION");
                else
                    out.append(name + ": " + name + " " + synopsis);
                out.append("\n    " + short_desc + "\n\n    " + long_desc + "\n\n    Options:");
                for (string o: optlist)
                    out.append("\n      -" + o);
            }
        }
    }

    function _dev_info() internal view returns (string out) {
        out.append(format("version: {}\n", _version));
    }

    uint8 constant UUDISK_LOC = 5;
    function read_disk() internal view returns (s_disk d, disklabel l, part_table pt) {
        uint32 a = libpart.LABELOFFSET;
        if (_ram.exists(a)) {
            d = abi.decode(_ram[a], s_disk);
            a = libpart.LABELSECTOR;
            if (_ram.exists(a)) {
                l = abi.decode(_ram[a], disklabel);
                a++;
                if (_ram.exists(a))
                    pt = abi.decode(_ram[a], part_table);
            }
        }
    }

    function read_ufs_disk() internal view returns (uufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a))
            return abi.decode(_ram[a], uufsd);
    }
    function _dump(string arg, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out) {
        flags;
        fsb f = ud.d_fsb;
        mapping (uint32 => TvmCell) m0 = libvmem.mmap(_ram, 0, 4);
        out.append(libvmem.dump_mem(m0));
        out.append(_dev_info());
        out.append(libvmem.dump_mem(m));
        (s_disk d, disklabel l, part_table pt) = read_disk();
        if (arg == "ufs") out.append(libufs.print_disk(ud));
        else if (arg == "ud") out.append(libufs.print_disk_header(ud));
        else if (arg == "label") out.append(libpart.print_label(l));
        else if (arg == "disk") out.append(libpart.print_disk(d));
        else if (arg == "part") out.append(libpart.print_part_table(pt));
        else if (arg == "sb") out.append(libsb.print_sb(f));
        else if (arg == "cg") {
            uint16 i;
            repeat (f.ncg) {
                cg g = libufs.fetch_cg(f, m, i);
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
    //                out.append(libsb.print_dino(dd));
                    out.append(libfdt.print_dino_lsof(dd));
                } else
                    out.append("Thin ino\n");
            }
        }
    }

    function _label(string arg, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out, string err, uint32 a, TvmCell c) {
        err;
        ud;
        m;
        (bool fe, , bool fw, ) = libflags.flags_set(flags, "enwR");
        (bool fA, , , ) = libflags.flags_set(flags, "A");
        (s_disk d, disklabel l, part_table pt) = read_disk();
        if (fA)
            out.append(libpart.print_label(l));
        if (fe) {
            d = libpart.read_disk_label(l);
            out.append(libpart.print_disk(d));
            out.append(libpart.print_label(l));
            a = 0;
            c = abi.encode(d);
        }
        if (fw) {
            uint8 scheme = libpart.SCHEME_VTOC;
            d = libpart.create_disk(arg, scheme, 0);
            disklabel l1 = libpart.read_standard_label(d);
            out.append(libpart.print_label(l1));
            a = libpart.LABELOFFSET;
            c = abi.encode(l1);
        }
        if (arg.empty())
            out.append(libpart.print_part_table(pt));

    }
    function _gpart(string arg0, string arg1, string arg2, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out, string err, uint32 a, TvmCell c) {
        uint v1 = tou(arg1);
        arg2;
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
        ud;
        m;
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
            a = 2;
            c = abi.encode(pt0);
        } else if (arg0 == "delete") {
        } else if (arg0 == "modify") {
            out.append("modify type: " + stype);
            if (stype == "boot") {}
            else if (stype == "swap") {
                p.p_fstype = libpart.FS_SWAP;
                pt.d_partitions[i - 1] = p;
                out.append(libpart.print_part_table(pt));
                a = 2;
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

    function _newfs(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
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
                a = 2;
                c = abi.encode(pt);
            }
        }
    }

    function _io(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        (bool ff, , , ) = libflags.flags_set(flags, "f");
        ff;
        err;
        uufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, ud.d_fsb.cblkno, 20);
        uint v0 = tou(arg1);
        out.append(libvmem._conva(v0));
        uint val = tou(arg2);
        if (arg0 == "examine") {
            out.append(libvmem.faccess(m, v0) + "\n");
//            dinode di = libufs.getinode(ud, m, uint16(v0));
        //    out.append(libufs.checkinode(ud, uint16(v0)));
//            out.append(libsb.print_dino(di));
        } else if (arg0 == "read") {
//            out.append(libvmem.faccess(m, v0) + "\n");
//            out.append(libvmem.fread(m, v0) + "\n");
//            dinode di = ud.getinode(m, uint16(v0));
//            out.append(libsb.print_dino(di));
//            out.append(libvmem.fread(m, ud.d_dp) + "\n");
        } else if (arg0 == "fetch") {
            out.append(libvmem.faccess(m, v0) + "\n");
            out.append(libvmem.fread(m, v0) + "\n");
        } else if (arg0 == "store") {
            m.suword(uint8(v0), uint248(val));
            out.append(format("store {} {}\n", v0, val));
            out.append(libvmem.fread(m, v0 * 4) + "\n");
            a;
            c;
        }  else if (arg0 == "write") {
//            uint val = tou(arg1);
            m.suword(uint8(v0), uint248(val));
            out.append(libvmem.fread(m, v0 * 4) + "\n");
        }
        out.append(libvmem.dump_bin(m));
    }

    function _boot(string arg, mapping (uint8 => string) flags, uufsd ud) internal view returns (string out, string err, uint32 a, TvmCell c) {
//        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, 0, 4);
//        out.append(libvmem.dump_mem(m));
        uint res;
        ud;
//        (out, err, res) = _status();
        (out, err, res) = _status2(255, 0);
//        (string out2, string err2, uint res2) = _inspect(res);
//        out.append(out2);
//        err.append(err2);
        c;
        a;
        flags;
        if (arg == "?") {
	     //Give a short listing of the files in the root directory of	the default boot device, as a hint about available boot files.
        }
//        string filename = arg.empty() ? "/boot/kernel/kernel" : arg;
//        out.append(libufs.print_disk(ud));
//        out.append("> boot " + filename + "\n");
        out.append(">>	Tonix/TON BOOT\nDefault: 0:ad(0,a)/boot/loader\nboot:");
    }
    function complete(string b) external pure returns (string cmd) {
        for (cmd_info ci: CI)
            if (ci.hotkey == b)
                return "read -p \"" + ci.name + " \" input; run rpw s \"" + ci.name + " $input\"";
        for (action_info ai: CA)
            if (ai.hotkey == b)
                return ai.body;
        return "echo press '0' for menu";
    }

    function ck(uint32 a, TvmCell c) external view returns (string out) {
        out.append(format("0x{:X}:\n", a));
        out.append(libvmem.dump_slice(_ram[a].toSlice()) + " =>\n");
        out.append(libvmem.dump_slice(c.toSlice()));
        out.append("\n" + libvmem.dump_cell(_ram[a]));
        out.append(" => " + libvmem.dump_cell(c) + "\n");
    }
    function st(uint32 a, TvmCell c) external accept {
        _ram[a] = c;
    }
    function ld(uint32 a) external view returns (TvmCell c) {
        c = _ram[a];
    }

    function uc(TvmCell c) external accept {
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }

    function flash(TvmCell c) internal {
        _rom = c;
    }
    function onCodeUpgrade() internal {
        _version++;
    }

    modifier accept {
        tvm.accept();
        _;
    }

    function _errmsg(uint8 pec, string scmd) internal pure returns (string err) {
        if (pec == EX_NOTFOUND)
            err.append(scmd + ": command not found\n");
        else {
            err.append("gash: " + scmd + ": ");
            if (pec == EX_BADUSAGE)
                err.append("invalid option\n");
            else
                err.append(format("EC: {}\n", pec));
        }
    }
    function rpw(string s) external view returns (string cmd, string out, string err, uint32 a, TvmCell c) {
        (uint8 pec, uint8 ncmd, string scmd, string[] args, mapping (uint8 => string) flags) = _rl3(s, CI);
        if (pec == 0)
            (out, err, a, c) = exec(ncmd, args, flags);
        else
            err = _errmsg(pec, scmd);
        cmd = aug(out, err);
        TvmCell empty;
        if (c != empty)
            cmd.append("cp qr st.args;");
    }

    function exec(uint8 ncmd, string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        uint len = args.length;
        string arg0 = len > 0 ? args[0] : "";
        string arg1 = len > 1 ? args[1] : "";
        string arg2 = len > 2 ? args[2] : "";
        uufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, 0, 20);
        if (ncmd == CMD_HELP) (out, err) = _help(args, flags);
        else if (ncmd == CMD_IO) (out, err, a, c) = _io(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_DUMP) out = _dump(arg0, flags, ud, m);
        else if (ncmd == CMD_LABEL) (out, err, a, c) = _label(arg0, flags, ud, m);
        else if (ncmd == CMD_GPART) (out, err, a, c) = _gpart(arg0, arg1, arg2, flags, ud, m);
        else if (ncmd == CMD_NEWFS) (out, err, a, c) = _newfs(args, flags);
        else if (ncmd == CMD_BOOT) (out, err, a, c) = _boot(arg0, flags, ud);
        else if (ncmd == CMD_UFS) (out, err, a, c) = _ufs(args, flags, ud, m);
    }
    function aug(string out, string err) internal pure returns (string cmd) {
        if (!err.empty())
            cmd.append("printf \"`tput setaf 1` `jq -r .err qr` `tput sgr0`\n\";");
        if (!out.empty())
            cmd.append("jq -r .out qr;");
    }

    uint8 constant CMD_UNKNOWN  = 0;
    uint8 constant CMD_FIRST    = 1;
    uint8 constant CMD_HELP     = CMD_FIRST;
    uint8 constant CMD_DUMP     = CMD_FIRST + 1;
    uint8 constant CMD_LABEL    = CMD_FIRST + 2;
    uint8 constant CMD_GPART    = CMD_FIRST + 3;
    uint8 constant CMD_NEWFS    = CMD_FIRST + 4;
    uint8 constant CMD_IO       = CMD_FIRST + 5;
    uint8 constant CMD_BOOT     = CMD_FIRST + 6;
    uint8 constant CMD_UFS      = CMD_FIRST + 7;
    uint8 constant CMD_LAST     = CMD_UFS;

    struct cmd_info {
        string hotkey;
        string name;
        string synopsis;
        string optstring;
        string short_desc;
        string long_desc;
        string[] optlist;
    }

    cmd_info[CMD_LAST] constant CI = [
cmd_info("", "", "", "", "commands: help dump mount image newfs stat access examine read write fetch store boot", "", [""]),
cmd_info("h", "help",   "[-dms] [pattern ...]", "dms", "Display information about builtin commands",
    "Displays brief summaries of builtin commands.", [
        "d\toutput short description for each topic",
        "m\tdisplay usage in pseudo-manpage format",
        "s\toutput only a short usage synopsis for each topic matching PATTERN"]),
cmd_info("d", "dump", "<arg> [-r]", "r",
"Dump an internal structures specified by <arg>, or memory contents if none. Available types:",
"\n      ud\t\tUFS disk"
"\n      label\tdisk label"
"\n      disk\tdisk data"
"\n      part\tpartition table"
"\n      sb\t\tsuperblock"
"\n      cg\t\tcylinder groups"
"\n      inodes\tindex nodes", [
"r\traw memory format"]),
cmd_info("l", "label",  "[-weR] [-n] disk | -f file", "enwARf:", "read and write Tonix label",
    "installs, examines or modifies the Tonix label on a disk partition", [
        "A\tenables processing of the historical parts",
        "n\tdisplays the result instead of writing it",
        "f\toperate	on a file instead of a disk partition",
        " \texamine the label on a disk drive",
        "w\twrite a	standard label",
        "e\tedit an	existing disk label",
        "R\trestore	a disk label from a file"
        ]),
cmd_info("g", "gpart",  "<action> [ flags ]",
    "lprFNa:b:f:i:n:s:t:", "control utility for the disk partitioning",
"Partition disks. The first argument is the action to be taken:\n"
"\n      add\tAdd a new partition"
"\n      backup\tDump a partition table to standard output in a special format used by the restore action"
"\n      commit\tCommit any pending changes"
"\n      create\tCreate a new partitioning scheme"
"\n      delete\tDelete a partition identified by the -i <index> option"
"\n      modify\tModify a partition identified by the -i <index> option"
"\n      recover\tRecover a corrupt partition's scheme metadata"
"\n      resize\tResize a partition identified by the -i <index> option"
"\n      restore\tRestore the partition table from a backup previously created by the backup action"
"\n      set\tSet the named attribute on the partition entry"
"\n      show\tShow current partition information, or all if none are specified"
"\n      undo\tRevert any pending changes"
"\n      unset\tClear the named attribute on the partition entry", [
    "a attrib\tSpecifies the attribute to set or clear",
    "b start\tThe logical block address where the partition will begin",
    "f flags\tAdditional operational flags",
    "i index\tThe index in the partition table at which the new partition is to be placed",
    "n entries The number of entries in the partition table",
    "s size\tCreate a partition of size <size>",
    "t type\tCreate a partition of type <type>"
]),
cmd_info("n", "newfs",  "[-jnqvDFSV] device", "acjnqvDFSVb:C:i:I:J:G:N:d:m:o:g:L:M:O:p:r:E:t:T:U:e:z:", "Make a Tonix filesystem",
    "Initialize and clear file systems before first use. Builds a file system on the specified special file.", [
        "n\t\tdisplay what it would do if it were to create a filesystem",
        "p partition\tThe partition name to use (a..h)"]),
cmd_info("i", "io", "<command> <address> [arg]", "r", "Memory access",
"\n      examine <addr>\tExamine memory at address <addr>"
"\n      read <addr>\t\tRead memory at address <addr>"
"\n      write <addr> <val>\tWrite <val> to memory at address <addr>"
"\n      fetch <addr>\t\tFetch memory contents from address <addr>"
"\n      store <addr> <val>\tStore unsigned value <val> at address <addr>",
["r\traw memory access"]),
cmd_info("b", "boot",  "<filename>", "qv", "system bootstrapping procedures", "", [
    "q\tbe quiet, do not write anything to the console unless automatic boot fails or is disabled",
    "v\tbe verbose during device probing (and later)."]),
cmd_info("u", "ufs",  "<command> <arg>", "operate on UFS file systems from	userland",
"access a UFS file system at a low level from userland", "", [""])
    ];

    uint8 constant ACTION_LAST = 7;
    struct action_info {
        string hotkey;
        string name;
        string synopsis;
        string optstring;
        string short_desc;
        string long_desc;
        string body;
    }
    action_info[ACTION_LAST + 1] constant CA = [
action_info("0", "menu", "", "menu", "", "",
    "printf \"Quick commands:\n1) help\n2) compile\n3) update\n4) view\n5) apply\n6) discard\n7) quit\n\""),
action_info("1", "help", "", "help", "", "", "run rpw s help"),
action_info("2", "compile", "", "compile", "", "", "make cc"),
action_info("3", "update", "", "update", "", "", "make uc"),
action_info("4", "view", "", "view changes", "", "", "[ -s st.args ] && tonos-cli -c etc/xeen.conf runx -m ck st.args | jq -r .out"),
action_info("5", "apply", "", "apply changes", "", "", "[ -s st.args ] && tonos-cli -c etc/xeen.conf callx -m st st.args"),
action_info("6", "discard", "", "discard changes", "", "", "rm -f st.args;"),
action_info("7", "quit", "", "quit", "", "", "echo Bye! && exit 0")
    ];

    struct boot_info {
        uint8 index;
        uint32 loc;
        uint8 off;
        uint8 blen;
        uint16 nbits;
        uint8 nrefs;
        uint32 magic;
        string name;
        string short_desc;
        string long_desc;
    }
    uint8 constant BI_PROPS = 9;
    string[BI_PROPS + 1] constant BIPS = ["N/A", "index", "location", "offset", "block size", "bit size", "ref count", "magic", "unknown"];

    uint8 constant BI_STEPS = 8;
    uint16 constant CG_MAGIC    = 0x4347;
    uint16 constant CGFS_MAGIC  = 0x4346;
    uint16 constant BSD_MAGIC   = 0x8256; // The disk magic number

    boot_info[BI_STEPS + 1] constant BI = [
boot_info(0, 0,  0,  0, 0, 0, 0, "na", "n/a", ""),
boot_info(1, 0,  0,  1, 178, 4, 3, "disk", "disk info", ""),
boot_info(2, 1,  0,  1, 432, 0, BSD_MAGIC, "label", "disk label", ""),
boot_info(3, 2,  0,  1,  65, 1, 8, "part", "partition table", ""),
boot_info(4, 3,  0,  1, 248, 0, CGFS_MAGIC, "sb", "superblock", ""),
boot_info(5, 5,  0,  1,   1, 2, 1, "ufs", "UFS disk", ""),
boot_info(6, 6,  0, 12,   8, 0, CG_MAGIC, "cgs", "cylinder groups summary", ""),
boot_info(7, 19, 0,  8,   2, 0, 0, "inot", "inode table", ""),
boot_info(8, 21, 0,  8,   2, 0, 0, "data", "data blocks", "")
    ];

    function _status2(uint list, uint ) internal view returns (string, string err, uint res) {
        uint i;
        while (list > 0 && i <= BI_STEPS) {
            uint mask = uint(1) << i;
            if ((list & mask) == mask) {
                (uint8 ec, uint expected, uint actual) = _schk(i + 1);
                if (ec > 0)
                    err.append(format("{}) {}: error {}: {} mismatch; {} expected, {} actual\n",
                        i, BI[i].name, ec, BIPS[ec < BI_PROPS ? ec : BI_PROPS], expected, actual));
                else
                    res |= mask;
                list -= mask;
            }
            i++;
        }
    }
    function _schk(uint i) internal view returns (uint8 ec, uint expected, uint actual) {
        if (i > BI_STEPS || i == 0)
            return (1, BI_STEPS, i);
        (uint8 index, uint32 loc, uint8 nblk, uint8 off, uint16 nbits, uint8 nrefs, uint32 magic, , , ) = BI[i].unpack();
        if (i != index)
            return (1, index, i + 1);
        if (!_ram.exists(loc))
            return (2, loc, 0);
        for (uint32 j = 0; j < nblk; j++) {
            if (!_ram.exists(j + loc))
                return (3, nblk, j);
            TvmSlice s = _ram[loc + j].toSlice();
            (uint16 nb, uint8 nr) = s.size();
            if (nb < off)
                return (4, off, nb);
            nb -= off;
            if (off > 0)
                s.skip(off);
            if (nb != nbits)
                return (5, nbits, nb);
            if (nr != nrefs)
                return (6, nrefs, nr);
            uint32 val = _actual_magic(s, i);
            if (val != magic)
                return (7, magic, val);
        }
    }
    function _actual_magic(TvmSlice s, uint i) internal pure returns (uint32) {
        if (i == 1) return s.decode(s_disk).d_hba_vendor;
        else if (i == 2) return s.decode(disklabel).d_magic;
        else if (i == 3) return s.decode(part_table).d_npartitions;
//        else if (i == 4) return s.decode(stat).st_dev;
        else if (i == 4) return s.decode(fsb).magic;
        else if (i == 5) return s.decode(uufsd).d_ufs;
        else if (i == 6) return s.decode(cg).cg_magic;
    }

    uint8 constant EXECUTE_SUCCESS  = 0;
    uint8 constant EXECUTE_FAILURE  = 1;
    uint8 constant EX_BADUSAGE      = 2; // Usage messages by builtins result in a return status of 2
    uint8 constant EX_BINARY_FILE	= 126;
    uint8 constant EX_NOEXEC	    = 126;
    uint8 constant EX_NOINPUT	    = 126;
    uint8 constant EX_NOTFOUND	    = 127;
    uint8 constant EX_BADSYNTAX     = 1;    // shell syntax error
    uint8 constant EX_USAGE         = 2;    // syntax error in usage // Command line syntax errors (invalid keyword, unknown option)
    function _rl3(bytes bb, cmd_info[] cis) internal pure returns (uint8 ec, uint8 cmd, string scmd, string[] args, mapping (uint8 => string) flags) {
        uint q = libstr.strchr(bb, 0x20);
        scmd = q > 0 ? bb[ : q - 1] : bb;
        for (uint i = 1; i < cis.length; i++) {
            if (cis[i].name == scmd) {
                cmd = uint8(i);
                if (q > 0)
                    (ec, args, flags) = _rl2(bb[q : ], cis[i].optstring);
                break;
            }
        }
        if (cmd == CMD_UNKNOWN)
            ec = EX_NOTFOUND;
    }
    function rl2(string s, bytes optstring) external pure returns (uint8 ec, string[] args, mapping (uint8 => string) flags) {
        return _rl2(s, optstring);
    }
    function _rl2(bytes s, bytes optstring) internal pure returns (uint8 ec, string[] args, mapping (uint8 => string) flags) {
        uint8 opt_name;
        uint[] tp = libstr.strtok(s, 0x20);
        uint olen = optstring.length;
        uint pos;
        for (uint te: tp) {
            bytes w = pos > 0 ? s[pos + 1 : te] : s[ : te];
            pos = te;
            uint wl = w.length;
            if (wl == 0)
                continue;
            if (w[0] == '-' && wl > 1) {
                byte b = w[1];
                uint8 v = uint8(b);
                uint q = libstr.strchr(optstring, b);
                if (q == 0) {
                    ec = EX_BADUSAGE;
                    break;
                }
                if (q < olen && optstring[q] == ":")
                    opt_name = v;
                else
                    flags[v] = "";
            } else {
                if (opt_name > 0) {
                    flags[opt_name] = w;
                    opt_name = 0;
                } else
                    args.push(w);
            }
        }
    }
}