pragma ton-solidity >= 0.66.0;
struct csum {
	uint8 cs_ndir;	 // number of directories
	uint16 cs_nbfree; // number of free blocks
	uint8 cs_nifree; // number of free inodes
	uint8 cs_nffree; // number of free frags
}
struct csum_total { // 5 x 2 = 10
	uint16 cs_ndir;		// number of directories
	uint16 cs_nbfree;	// number of free blocks
	uint16 cs_nifree;	// number of free inodes
	uint16 cs_nffree;	// number of free frags
	uint16 cs_numclusters;	// number of free clusters
}
struct cg { // 1 x 2 + 15 x 1 + 5 = 22
    uint16 cg_magic;      // magic number
    uint8 cg_cgx;         // we are the cgx'th cylinder group
    csum cg_cs;           // cylinder summary information
    uint8 cg_ndblk;       // number of data blocks this cg
    uint8 cg_iusedoff;    // used inode map
    uint8 cg_freeoff;     // free block map
    uint8 cg_clusteroff;  // free cluster map
    uint8 cg_nclusterblks;// number of clusters this cg
    uint8 cg_niblk;       // number of inode blocks this cg
    uint8 cg_rotor;       // position of last used block
    uint8 cg_frotor;      // position of last used frag
    uint8 cg_irotor;      // position of last used inode
    uint8 cg_nextfreeoff; // next available space
    uint8 cg_initediblk;  // last initialized inode
    uint8 cg_unrefs;      // number of unreferenced inodes
    uint8 cg_ckhash;      // check-hash of this cg
    uint8 cg_space;       // space for cylinder group maps
    uint72 padding;       // padding to 31
}
struct fsb { // 1 x 4 + 12 x 2 + 18 x 1 + 10 = 56
    uint16 magic;		// magic number
    uint8 sblkno;	    // offset of super-block in filesys
    uint8 cblkno;	    // offset of cyl-block in filesys
    uint8 iblkno;	    // offset of inode-blocks in filesys
    uint8 dblkno;	    // offset of first data	after cg
    uint8 ncg;		    // number of cylinder groups
	uint8 bsize;		// size of basic blocks in fs
	uint8 fsize;		// size of frag blocks in fs
	uint8 frag;		    // number of frags in a block in fs
	uint8 minfree;      // minimum percentage of free blocks
	uint8 maxcontig;	// max number of contiguous blks
	uint16 maxbpg;		// max number of blks per cyl group
    uint16 id;          // unique filesystem id
    uint8 fsbtodb;      // fsbtodb and dbtofsb shift constant
    uint8 ipg;          // inodes per group
    uint16 bpg;         // blocks per group
    uint16 fpg;		    // blocks per group * fs_frag
    uint16 swuid;	    // system-wide uid
    uint8 sbsize;	    // actual size of super	block
    uint8 csaddr;	    // blk addr of cyl grp summary area
    uint8 cssize;	    // size	of cyl grp summary area
    uint8 cgsize;	    // cylinder group size
    uint8 inosize;	    // inode size
    uint8 desize;	    // directory entry size
    uint8 padding;	    // padding to 31
}
struct fss {
    uint8 fmod;		    // super block modified	flag
    uint8 clean;    	// filesystem is clean flag
    uint8 cgrotor;	    // last	cg searched
    uint16 si;          // In-core pointer to summary info // fs_summary_info
    uint16 metaspace;	// byte offset of this superblock
	uint16 sblockactualloc;	// byte offset of this superblock
	uint16 sblockloc;		// byte offset of standard superblock
    csum_total cstotal;
    uint32 time;	    // last	time written
    uint16 size;		// number of blocks in fs
    uint16 dsize;	    // number of data blocks in fs
    uint24 padding;	    // padding to 31
}
struct fs_summary_info {
	uint8[]	si_contigdirs;	// # of contig. allocated dirs
	csum[] si_csp;		    // cg summary info buffer
	uint32[] si_maxcluster;	// max cluster in each cyl group
	uint16 si_active;		// used by snapshots to track fs
}
struct fsrecovery { // 2 x 2 + 3 x 1 = 7
	uint16 fsr_magic;  // magic number
	uint8 fsr_fsbtodb; // fsbtodb and dbtofsb shift constant
	uint8 fsr_sblkno;	// offset of super-block in filesys
	uint16 fsr_fpg;	    // blocks per group * fs_frag
	uint8 fsr_ncg;	    // number of cylinder groups
}