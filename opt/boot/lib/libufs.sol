pragma ton-solidity >= 0.67.0;
import "fs.h";
import "uio.h";
import "libsb.sol";
import "libgenio.sol";
import "libvmem.sol";

library libufs {
    using libufs for uufsd;
    uint8 constant FSBTODB = 8;
    uint8 constant DFLAG_SEEKABLE =	0x02;	// seekable / nonsequential
    uint8 constant FOF_OFFSET	= 0x01;	// Use the offset in uio argument
    uint16 constant IOSIZE_MAX = 64000;
//    uint8 constant UFS_NOHASHFAIL	= 0x01;	// Ignore check-hash failure
//    uint8 constant UFS_NOWARNFAIL	= 0x03;	// Ignore non-fatal inconsistencies
//    uint8 constant UFS_NOMSG	    = 0x04;	// Print no error message
//    uint8 constant UFS_NOCSUM	    = 0x08;	// Read just the superblock without csum
//    uint8 constant UFS_ALTSBLK	    = 0x10;	// Flag used internally
    uint16 constant CG_MAGIC    = 0x4347;
    uint16 constant CGFS_MAGIC  = 0x4346;
//    uint8 constant BLK_SIZE     = 127;
    uint8 constant FRAG_SIZE_OLD = 124;
    uint8 constant FRAG_SIZE    = 31;
    uint8 constant FS_MAXCONTIG	= 16;
    uint8 constant MAXFRAG 	    = 4;
    uint8 constant FRAG_SHIFT   = 2; // LOG2(MAXFRAG)
    uint8 constant MINFREE		= 8;
    uint8 constant SB           = 2;
    uint8 constant IPG          = 96;
    uint8 constant IPG_OLD      = 30;
    uint8 constant MINCYLGRPS	= 4;        // The minimal number of cylinder groups that should be created.
    uint8 constant AVFILESIZ	= 100;  	// expected average file size
//    uint8 constant AFPDIR		= 8;	    // expected number of files per directory
//    uint16 constant MAXBPG      = 1024;     // 256 * 4;
    uint16 constant MAXBPG_OLD  = 1024;     // 256 * 4;
    uint16 constant MAXBPG      = 250;     // 256 * 4;
//    uint8 constant DEFAULTOPT	= 0;//libfs.FS_OPTTIME;
//    uint8 constant MAXMNTLEN    = 32; // The path name on which the filesystem is mounted is maintained in fs_fsmnt
//    uint8 constant MAXVOLLEN    = 8; // The volume name for this filesystem is maintained in fs_volname
    uint8 constant MINE_NAME	= 0x01; // Internally, track the 'name' value, it's ours.
    uint8 constant MINE_WRITE   = 0x02; // Track if its fd points to a writable device
    uint16 constant O_RDONLY    = 0;
    uint16 constant O_WRONLY    = 1;
    uint16 constant O_RDWR      = 2;
    function checkinode(uufsd ud, uint16 inum) internal returns (string out) {
    	fsb f = ud.d_fsb;
    	if (inum >= f.ipg * f.ncg)
            return "inode number out of range";
    	uint8 inoblock = ud.d_inoblock;
    	if (inoblock == 0)
            return "unable to allocate inode block";
        if (ud.d_ufs != 1)
            return "unknown UFS filesystem type";
    	uint16 min = ud.d_inomin;
        uint16 max = ud.d_inomax;
        if (inum >= min && inum < max) {
               out = "Success!";
            return out;
        }
        return "Inode out of range";
    }
    function getinode(uufsd ud, mapping (uint32 => TvmCell) m, uint16 inum) internal returns (dinode di) {
//        TvmSlice s = libvmem.fuword(m, uint16(disk.d_fsb.iblkno * 4 + inum));
    	fsb f = ud.d_fsb;
        uint8 ec;
    	if (inum < f.ipg * f.ncg) {
    	    uint8 inoblock = ud.d_inoblock;
            if (inoblock > 0) {
                if (inum >= ud.d_inomin && inum < ud.d_inomax) {
                    uint16 dp = inum + ud.d_inoblock * 4;
                    TvmSlice s = libvmem.fuword(m, dp);
                    if (s.bits() >= 248) {
                        ud.d_dp = dp;
                        return s.decode(dinode);
                    }
                    else
                        ec = libgenio.EIO;
                } else
                    ec = libgenio.EINVAL;
            } else
                ec = libgenio.EINVAL;
        } else
            ec = libgenio.EFAULT;
        ud.d_error = ec;
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
    function close(uint8 fd) internal {
        fd;
    }
    function open(uufsd ud, string name, uint16 flags) internal returns (uint8) {
        flags;
        if (bytes8(name) == ud.d_name)
            return ud.d_fd;
    }
    function ufs_disk_close(uufsd ud) internal {
    	close(ud.d_fd);
    	ud.d_fd = 0;
        delete ud.d_inoblock;
    	if ((ud.d_mine & MINE_NAME) > 0)
    		delete ud.d_name;
    	if (ud.d_si > 0) {
//    		delete disk.d_si.si_csp;
    		delete ud.d_si;
    	}
    }
    function ufs_disk_write(uufsd ud) internal returns (bool) {
    	if ((ud.d_mine & MINE_WRITE) > 0)
    		return true;
    	uint8 fd = ud.open(bytes(ud.d_name), O_RDWR);
    	if (fd < 0) {
//    		ERROR(disk, "failed to open disk for writing");
    		return false;
    	}
    	close(ud.d_fd);
    	ud.d_fd = fd;
    	ud.d_mine |= MINE_WRITE;
    	return true;
    }
    function unpack_fs(TvmCell c) internal returns (uufsd ud, mapping (uint32 => TvmCell) m) {
        TvmSlice s00 = c.toSlice();
        fsb f = s00.decode(fsb);
        ud = abi.decode(s00.loadRef(), uufsd);
        TvmCell sbs = s00.loadRef();
        TvmCell cgs = s00.loadRef();
        TvmCell inots = s00.loadRef();
        uint8 ng = f.ncg;
        uint8 p = f.sblkno;
        TvmSlice s = sbs.toSlice();
        m[p++] = s.loadRef();
        m[p++] = s.loadRef();
        TvmSlice s0 = cgs.toSlice();
        TvmCell cgd = s0.loadRef();
        TvmCell cbbm = s0.loadRef();
        TvmCell cibm = s0.loadRef();
        p = f.cblkno;
        s = cgd.toSlice();
        repeat (ng)
            m[p++] = s.loadRef();
        s = cbbm.toSlice();
        repeat (ng)
            m[p++] = s.loadRef();
        s = cibm.toSlice();
        repeat (ng)
            m[p++] = s.loadRef();
        p = f.iblkno;
        s = inots.toSlice();
        uint16 n;
        repeat (ng) {
            TvmCell itbl = s.loadRef();
            cg g = libsb.fetch_cg(f, m, n);
            if (g.cg_magic == CG_MAGIC) {
                uint nitbls = math.divc(g.cg_initediblk, 4);
                uint16 i;
                TvmSlice si = itbl.toSlice();
                repeat (nitbls) {
                    m[g.cg_niblk + i] = si.loadRef();
                    i++;
                }
            }
            n++;
        }
    }
    function pack_fs(uufsd ud, mapping (uint32 => TvmCell) m) internal returns (TvmCell) {
        TvmBuilder b0;
        fsb f = ud.d_fsb;
        b0.store(f);
        b0.store(abi.encode(ud));
        b0.store(libsb.pack_sbs(f, m));
        b0.store(libsb.pack_cgs(f, m));
        b0.store(libsb.pack_inode_tables(f, m));
        return b0.toCell();
    }
    function fetch_sb(uufsd ud, mapping (uint32 => TvmCell) m) internal returns (fsb) {
        TvmSlice s = libvmem.fuword(m, uint16(ud.d_sblock * 4));
        if (s.bits() >= 248)
            return s.decode(fsb);
    }
    function alloc_blocks(uufsd ud, uint8 n) internal {
        cg g = ud.d_cg;
        if (g.cg_cs.cs_nbfree >= n) {
            g.cg_nextfreeoff += n;
            g.cg_cs.cs_nbfree -= n;
            ud.d_cg = g;
            ud.d_fss.cstotal.cs_nbfree -= n;
        }
    }
    function alloc_inodes(uufsd ud, uint8 n) internal {
        cg g = ud.d_cg;
        if (g.cg_cs.cs_nifree >= n) {
            g.cg_cs.cs_nifree -= n;
            g.cg_initediblk += math.divc(n, 4);
            ud.d_inomax += n;
            ud.d_cg = g;
            ud.d_fss.cstotal.cs_nifree -= n;
        }
    }
    function alloc_dirs(uufsd ud, uint8 n) internal {
        cg g = ud.d_cg;
        g.cg_cs.cs_ndir += n;
        ud.d_cg = g;
        ud.d_fss.cstotal.cs_ndir += n;
    }
    function uval(TvmSlice s) internal returns (uint248) {
        uint16 nb = s.bits();
        if (nb > 0)
            return s.loadUnsigned(nb < 248 ? uint16(nb) : 248);
    }
    function print_disk_header(uufsd ud) internal returns (string out) {
        (bytes8 d_name, uint8 d_ufs, uint8 d_fd, uint32 d_bsize, uint16 d_sblock, uint16 d_si, uint8 d_inoblock,
            uint8 d_inomin, uint8 d_inomax, uint16 d_dp, fsb d_fsb, fss d_fss, cg d_cg, uint8 d_ccg, uint8 d_lcg, uint8 d_error,
            uint16 d_sblockloc, uint8 d_lookupflags, uint8 d_mine) = ud.unpack();
        out.append(format("name {} ufs {} fd {} bsize {} sblock {} si {} inoblock {} inomin {} inomax {} dp {} ",
            bytes(d_name), d_ufs, d_fd, d_bsize, d_sblock, d_si, d_inoblock, d_inomin, d_inomax, d_dp));
        out.append(format("ccg {} lcg {} error {} sblockloc {} lookupflags {} mine {}\n",
            d_ccg, d_lcg, d_error, d_sblockloc, d_lookupflags, d_mine));
        out.append(libsb.print_sb(d_fsb));
        out.append(libsb.print_fss(d_fss));
        out.append(libsb.print_cg(d_fsb, d_cg));
    }
    function print_disk(uufsd ud) internal returns (string out) {
        (bytes8 d_name, , , , , , , uint8 d_inomin, , , fsb d_fsb, fss d_fss, cg d_cg, , , , uint16 d_sblockloc, , ) = ud.unpack();
        (uint16 magic, , , , uint8 dblkno, uint8 ncg, uint8 bsize, uint8 fsize, , , , , , , uint8 ipg, uint16 bpg,
        uint16 fpg, uint16 swuid, , , , uint8 cgsize, uint8 ino_size, , ) = d_fsb.unpack();
        (, uint8 clean, , , , , , csum_total cstotal, uint32 time, uint16 size, , ) = d_fss.unpack();
        out.append(print_disk_header(ud));
        out.append(libsb.print_sb(d_fsb));
        out.append(libsb.print_fss(d_fss));
        out.append(libsb.print_cg(d_fsb, d_cg));
        (, uint16 cs_nbfree, uint16 cs_nifree, , ) = cstotal.unpack();
        out.append(format("Filesystem volume name:\t\t{}\nLast mounted on:\t\t{}\nFilesystem UUID:\t\t{}\nFilesystem magic number:\t0x{:X}\nFilesystem state:\t\t{}\n",
          bytes(d_name), "n/a", swuid, magic, clean > 0 ? "clean" : "dirty"));
        out.append(format("Filesystem OS type:\t\t{}\nInode count:\t\t\t{}\nBlock count:\t\t\t{}\nReserved block count:\t\t{}\nFree blocks:\t\t\t{}\nFree inodes:\t\t\t{}\nFirst block:\t\t\t{}\nBlock size:\t\t\t{}\nFragment size:\t\t\t{}\n",
            "Tonix", ncg * ipg, size, dblkno, cs_nbfree, cs_nifree, d_sblockloc, bsize, fsize));
        out.append(format("Group descriptor size:\t\t{}\nReserved GDT blocks:\t\t{}\nBlocks per group:\t\t{}\nFragments per group:\t\t{}\n",
            cgsize, uint16(cgsize) * bsize, bpg, fpg));
        out.append(format("Inodes per group:\t\t{}\nInode blocks per group:\t\t{}\nLast write time:\t\t{}\nFirst inode:\t\t\t{}\nInode size:\t\t\t{}\n",
            ipg, ipg / 4 + 1, time, d_inomin, ino_size));
    }
    function _sizeof(TvmCell c) internal returns (uint) {
        ( , uint nb, ) = c.dataSize(200);
        return nb / 8;
    }
    function ERROR(uufsd u, uint8 str) internal {
        u.d_error = str;
    }
    function handle_disk_read(uufsd ud, fsb f, fss s, uint8 error) internal returns (bool) {
        ud.ERROR(0);
        if (error > 0) {
            ud.ERROR(error);
    		ud.d_ufs = 0;
    		return false;
    	}
    	ud.d_fsb = f;
        if (f.magic == CGFS_MAGIC)
            ud.d_ufs = 1;
        if (f.fsize > 0) {
    	    ud.d_bsize = uint16(f.fsize / libgenio.fsbtodb(f, 1));
    	    ud.d_sblock = s.sblockloc / ud.d_bsize;
    	    ud.d_si = s.si;
    	    return true;
        }
        return false;
    }
}