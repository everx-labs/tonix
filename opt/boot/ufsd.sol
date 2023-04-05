pragma ton-solidity >= 0.67.0;
import "label_loader.sol";
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
//	uint32 fs_ckhash;		// if CK_SUPERBLOCK, its check-hash
//	uint32 fs_metackhash;	// metadata check-hash, see CK_ below
	uint8 fs_flags;		    // see FS_ flags below
	uint32 fs_contigsumsize;// size of cluster summary array
	uint8 fs_maxsymlinklen; // max length of an internal symlink
	uint8 fs_old_inodefmt;	// format of on-disk inodes
	uint32 fs_maxfilesize;	// maximum representable file size
//	uint32 fs_qbmask;		// ~fs_bmask for use with 64-bit size
//	uint32 fs_qfmask;		// ~fs_fmask for use with 64-bit size
	uint32 fs_magic;		// magic number
}

contract ufsd is label_loader {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, TvmCell c) {
        return _ufsd(args, flags);
    }
    uint8 constant UUDISK_LOC = 5;
    function read_ufs_disk() internal view returns (uufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a))
            return abi.decode(_ram[a], uufsd);
    }

    function _ufsd(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, TvmCell c) {
        uufsd ud = read_ufs_disk();
        uufsd2 d;
        d.clone(ud);
        mapping (uint32 => TvmCell) m = _ram;
//        out.append(libvmem.dump_bin(m));
//        mapping (uint32 => TvmCell) m3 = libvmem.remap_pages(m, 0);
//        out.append(libvmem.dump_mem(m3));
////        d.map(m);
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
//        TvmSlice s;
//        cg g;
//        fsb f;
        uint32 a;
        dinode di;
//        uint8 ec;
//        out.append()
//    	(uint8 ec, uint16 cnt, TvmCell c) = d.pread(devfd, fs.fs_cgsize,
//            fsbtodb(fs, cgtod(fs, n)) * (fs.fs_fsize / fsbtodb(fs, 1)));
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
        else if (cmd == "getinode") {
            out.append(libufs2.print_ufs(d, libufs2.P_CG));
            di = d.getinode(n);

        } else if (cmd == "putinode") { 
            rv = d.putinode();
        }

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
    function tou(string s) internal pure returns (uint val) {
        optional (int) p = stoi(s);
        if (p.hasValue())
            return uint(p.get());
    }

}

    using libufs2 for uufsd2 global;
library libufs2 {

    uint32 constant CG_MAGIC = 0x090255;

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
    function fragnum(ufs f, uint32 fb) internal returns (uint32) {
        return fb & (f.fs_frag - 1);
    }
    function blknum(ufs f, uint32 fb) internal returns (uint32) {
        return fb &~ (f.fs_frag - 1);
    }

    function fs_cs(ufs fs, uint8 indx) internal returns (csum) {
        return fs.fs_si.si_csp[indx];
    }
    function strerror(uint8 ec) internal returns (string) {
        return format("{}", ec);
    }

    function clone(uufsd2 d, uufsd ud) internal {
        d.d_name = string(bytes(ud.d_name));
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
//        TvmSlice s = libvmem.fuword(d.d_m, uint16(d.d_fsb.cblkno + c) * 4);
//        if (s.bits() < 248) {
//            d.ERROR("short read from block device");
//            return -1;
//        }
//        cg g = s.decode(cg);
//        d.dlog.push(libsb.print_cg_header(g));
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
//        cg g = libsb.fetch_cg(d.d_fsb, d.d_m, n);
//        ec;
    	if (cnt == 0) {
    		d.d_error = "end of file from block device";
    		return EIO;
    	}
    	if (cnt != fs.fs_cgsize) {
    		d.d_error = "short read from block device";
    		return EIO;
    	}
        //TvmSlice s = libvmem.fuword(m, uint16(f.cblkno + n) * 4);
        TvmSlice s = c.toSlice();
//        if (s.bits() < 248)
//            return EDOOFUS;
        cg cgp = s.decode(cg);
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
            uint16 d_inoblock, uint16 d_inomin, uint16 d_inomax, uint16 d_dp, ufs d_fs, fsb d_fsb, TvmCell d_sb,
            fss d_fss, cg d_cg, TvmCell d_buf, uint8 d_ccg, uint8 d_lcg, uint8 errno, string d_error, uint16 d_sblockloc,
            uint8 d_lookupflags, uint8 d_mine, string[] dlog, mapping (uint32 => TvmCell) d_m) = ud.unpack();
        d_sb;
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
        fs.fs_mtime = block.timestamp;
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
