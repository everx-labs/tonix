pragma ton-solidity >= 0.67.0;

struct udirent { //2 + 5 = 7; 7 * 18 = 126
    uint8 ft;
    uint16 ino;
    uint8 id;
    uint8 seg;
    uint8 off;
    uint8 len;
}

struct udinode { // 4 + 3 + 5 x 2 + 3 = 20; 20 * 6 = 120
    uint16 mode;   // IFMT, permissions
    uint16 ino;	   // Inode no
    uint8 nlink;   // File link count
    uint24 size;   // File byte count
    uint32 mtime;  // Last modified time
    uint16 db1;
    uint16 db2;
    uint8 blocks;  // Blocks actually held
    uint16 uid;	   // File owner
    uint8 gid;	   // File group
}

struct uofile {
    uint8 fdtype;   // cwd/rtd/txt/mem/NOFD/
    uint8 ftype;    // REG/DIR/FIFO/CHR/a_inode/unix/unknown
    uint8 fd;
    uint16 mode;    // r/w/u u: a_inode/unix
    uint16 dev;
    uint16 ino;	    // NULL or applicable vnode
    uint24 szoff;   // DFLAG_SEEKABLE specific fields
    uint32 name;
}

struct ucsum { //3 x 2 = 6
    uint16 ndir;   // number of directories
    uint16 nbfree; // number of free blocks
    uint16 nifree; // number of free inodes
}

struct ucg { //12 x 2 + 6 = 30; 30 * 4 = 120
    uint16 cgx;         // we are the cgx'th cylinder group
    ucsum cs;           // cylinder summary information
    uint16 ndblk;       // number of data blocks this cg
    uint16 iusedoff;    // used inode map
    uint16 freeoff;     // free block map
    uint16 niblk;       // number of inode blocks this cg
    uint16 rotor;       // position of last used block
    uint16 irotor;      // position of last used inode
    uint16 nextfreeoff; // next available space
    uint16 initediblk;  // last initialized inode
    uint16 unrefs;      // number of unreferenced inodes
    uint16 space;       // space for cylinder group maps
    uint16 magic;       // magic number
}
struct ufsb {
    uint16 sblkno;      // offset of super-block in filesys
    uint16 cblkno;      // offset of cyl-block in filesys
    uint16 iblkno;      // offset of inode-blocks in filesys
    uint16 dblkno;      // offset of first data	after cg
    uint16 ncg;	        // number of cylinder groups
    uint16 bsize;       // size of basic blocks in fs
    uint16 maxcontig;   // max number of contiguous blks
    uint16 maxbpg;      // max number of blks per cyl group
    uint16 fsbtodb;     // fsbtodb and dbtofsb shift constant
    uint16 id;          // unique filesystem id
    uint16 sbsize;      // actual size of super	block
    uint16 cssize;      // size	of cyl grp summary area
    uint16 cgsize;      // cylinder group size
    uint16 inosize;	    // inode size
    uint16 desize;      // directory entry size
    uint16 inopb;       // value of INOPB
    uint16 ipg;         // inodes per group
    ucsum cs;           // cylinder summary information
    uint16 flags;       // fmod, clean, ronly, fs
    bytes12 fs_fsmnt;   // name mounted on
    bytes8 volname;	    // volume name
    uint32 time;        // last time written
    uint16 size;        // number of blocks in fs
    uint16 dsize;       // number of data blocks in fs
    uint16 magic;       // magic number
}
struct ufs_summary_info {
    uint8[]	contigdirs;	// # of contig. allocated dirs
    ucsum[] csp;        // cg summary info buffer
}
struct ug {
    ucg g;
    uint16 nino;
    uint16 nblk;
    uint248 inobmp;
    uint248 bbmp;
}
struct ufsd {
    string name;     // disk name
    uint8 ufs;       // decimal UFS version
    uint8 fd;        // raw device file descriptor
    uint32 bsize;    // device bsize
    uint16 sblock;   // superblock location
    uint16 si;       // Superblock summary info // struct fs_summary_info *
    uint16 inoblock; // inode block
    uint16 inomin;   // low ino, not ino_t for ABI compat
    uint16 inomax;   // high ino, not ino_t for ABI compat
    uint16 dp;       // pointer to currently active inode // dinodep
    ufsb fs;         // filesystem information
    ug cg;           // cylinder group
    uint16 ccg;	     // current cylinder group
    uint16 lcg;	     // last cylinder group (in d_cg)
    string error;    // human readable disk error
    uint16 sblockloc;// where to look for the superblock
    uint8 lookupflags;// flags to superblock lookup
    uint8 mine;	     // internal flags
}
using libufsd for ufsd global;
library libufsd {

    function getinode(ufsd ud, udinode dp, uint16 inum) internal {
    }

    function alloc_blocks(ufsd ud, uint8 n) internal {
        if (ud.cg.g.cs.nbfree >= n) {
            ud.cg.g.nextfreeoff += n;
            ud.cg.g.ndblk += n;
            ud.cg.g.cs.nbfree -= n;
            ud.fs.cs.nbfree -= n;
            uint248 v = ud.cg.nblk;
            ud.cg.nblk += n;
            ud.cg.g.rotor = ud.cg.nblk - 1;
            repeat (n) {
                ud.cg.bbmp |= uint248(1) << v;
                v++;
            }
        }
    }
    function alloc_inodes(ufsd ud, uint8 n) internal {
        ud.alloc_blocks(n);
        if (ud.cg.g.cs.nifree >= n) {
            ud.cg.g.cs.nifree -= n;
            ud.cg.g.initediblk += math.divc(n, ud.fs.inopb);
            ud.inomax += n;
            uint248 v = ud.cg.nino;
            ud.cg.nino += n;
            ud.cg.g.irotor = ud.cg.nino - 1;
            repeat (n) {
                ud.cg.inobmp |= uint248(1) << v;
                v++;
            }
            ud.fs.cs.nifree -= n;
        }
    }
    function alloc_dirs(ufsd ud, uint8 n) internal {
        ud.alloc_inodes(n);
        ud.cg.g.cs.ndir += n;
        ud.fs.cs.ndir += n;
    }
    function print_disk_header(ufsd ud) internal returns (string out) {
        (string name, uint8 ufsv, uint8 fd, uint32 bsize, uint16 sblock, uint16 si, uint16 inoblock, uint16 inomin, uint16 inomax,
            uint16 dp, ufsb fs, ug g, uint16 ccg, uint16 lcg, string error, uint16 sblockloc, uint8 lookupflags, uint8 mine) = ud.unpack();
        fs;g;
        out.append(format("name {} ufs {} fd {} bsize {} sblock {} si {} inoblock {} inomin {} inomax {} dp {} ",
            bytes(name), ufsv, fd, bsize, sblock, si, inoblock, inomin, inomax, dp));
        out.append(format("ccg {} lcg {} error {} sblockloc {} lookupflags {} mine {}\n",
            ccg, lcg, error, sblockloc, lookupflags, mine));
//        out.append(libsb.print_sb(d_fsb));
//        out.append(libsb.print_fss(d_fss));
//        out.append(libsb.print_cg(d_fsb, d_cg));
    }
    function print_ug(ug g) internal returns (string out) {
        (ucg gc, uint16 nino, uint16 nblk, uint248 inobmp, uint248 bbmp) = g.unpack();
        (uint16 cgx, ucsum cs, uint16 ndblk, uint16 iusedoff, uint16 freeoff, uint16 niblk, uint16 rotor, uint16 irotor, uint16 nextfreeoff, uint16 initediblk, uint16 unrefs, uint16 space, uint16 magic) = gc.unpack();
        out.append(format("cgx {} ndblk {} iusedoff {} freeoff {} niblk {} rotor {} irotor {} nextfreeoff {} initediblk {} unrefs {} space {} magic {}\n",
            cgx, ndblk, iusedoff, freeoff, niblk, rotor, irotor, nextfreeoff, initediblk, unrefs, space, magic));
        out.append(format("nino {} nblk {} inobmp {} bbmp {}  ", nino, nblk, inobmp, bbmp));
        out.append(print_cgsum(cs));
    }
    function print_sb(ufsb sb) internal returns (string out) {
        (uint16 sblkno, uint16 cblkno, uint16 iblkno, uint16 dblkno, uint16 ncg, uint16 bsize, , uint16 maxbpg, uint16 fsbtodb, uint16 id, uint16 sbsize, uint16 cssize, uint16 cgsize,
            uint16 inosize, uint16 desize, uint16 inopb, uint16 ipg, ucsum cs, uint16 flags, bytes12 fs_fsmnt, bytes8 volname, uint32 time, uint16 size, uint16 dsize, uint16 magic) = sb.unpack();
        out.append(format("S{} C{} I{} D{} N{} BSz{} B/G{} F2D{} #{} SZ [ sb{} cs{} cg{} ino{} de{} ] I/B{} I/G{} F{} mnt {} {} @ {} #blk{} #dblk{} {:x}\n",
            sblkno, cblkno, iblkno, dblkno, ncg, bsize, maxbpg, fsbtodb, id, sbsize, cssize, cgsize, inosize, desize, inopb, ipg, flags, bytes(fs_fsmnt), bytes(volname), time, size, dsize, magic));
        out.append(print_cgsum(cs));
    }
    function print_cgsum(ucsum cgs) internal returns (string out) {
        (uint16 cs_ndir, uint16 cs_nbfree, uint16 cs_nifree) = cgs.unpack();
        out.append(format("{} free blocks, {} free inodes, {} directories\n", cs_nbfree, cs_nifree, cs_ndir));
    }
    function print_udino(udinode di) internal returns (string out) {
        (uint16 mode, uint16 ino, uint8 nlink, uint24 size, uint32 mtime, uint16 db1, uint16 db2, uint8 blocks, uint16 uid, uint8 gid) = di.unpack();
        return format("M {} I {} N {} S {} M {} {} 2 {} B {} U {} G {}\n",
            mode, ino, nlink, size, mtime, db1, db2, blocks, uid, gid);
    }
    function print_de(udirent de) internal returns (string out) {
        (uint8 ft, uint16 ino, uint8 id, uint8 seg, uint8 off, uint8 len) = de.unpack();
        return format("ft {} ino {} id {} seg {} off {} len {}\n",
            ft, ino, id, seg, off, len);
    }
}
