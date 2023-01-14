pragma ton-solidity >= 0.66.0;
import "sb.h";
struct uufsd {
	bytes8 d_name;	    // disk name
	uint8 d_ufs;        // decimal UFS version
	uint8 d_fd;		    // raw device file descriptor
	uint16 d_bsize;		// device bsize
	uint16 d_sblock;	// superblock location
	uint16 d_si;    	// Superblock summary info // fs_summary_info *
	uint8 d_inoblock;	// inode block
	uint8 d_inomin;		// low ino, not ino_t for ABI compat
	uint8 d_inomax;		// high ino, not ino_t for ABI compat
	uint16 d_dp;		// pointer to currently active inode // di_inode *
	fsb d_fsb;		    // filesystem information
	fss d_fss;		    // filesystem information
	cg d_cg;		    // cylinder group
	uint8 d_ccg;		// current cylinder group
	uint8 d_lcg;		// last cylinder group (in d_cg)
	uint8 d_error;		// human readable disk error
	uint16 d_sblockloc;	// where to look for the superblock
	uint8 d_lookupflags;// flags to superblock lookup
	uint8 d_mine;		// internal flags
}