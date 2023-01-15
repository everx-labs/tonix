pragma ton-solidity >= 0.66.0;
struct buf {
	uint16 b_bufobj;    // bufobj
	uint32 b_bcount;
	uint32 b_data;
	uint8 b_error;
	uint8 b_iocmd;	    // BIO_* bio_cmd
	uint8 b_ioflags;	// BIO_* bio_flags
	uint32 b_iooffset;
	uint32 b_resid;
	uint32 b_blkno;		// Underlying physical block number
	uint32 b_offset;	// Offset into file
	uint16 b_bobufs;	// Buffer's associated vnode
	uint32 b_vflags;	// BV_* flag
	uint32 b_flags;	    // B_* flags
	uint32 b_kvabase;	// base kva for buffe
	uint32 b_lblkno;	// Logical block number
	uint16 b_vp;		// Device vnode // vnode
	uint16 b_rcred;		// Read credentials reference // ucred
	uint16 b_wcred;		// Write credentials reference // ucred
	uint8 b_npages;
	uint16[] b_pages; // vm_page
}
struct bufv {
	buf[] bv_hd;    // Sorted blocklist
	uint32 bv_root;	// Buf trie
	uint8 bv_cnt;	// Number of buffers
}
struct buf_ops {
	string bop_name;
	uint32 bop_write;   // b_write_t
	uint32 bop_strategy;// b_strategy_t
	uint32 bop_sync;    // b_sync_t
	uint32 bop_bdflush; // b_bdflush_t
}
struct bufobj {
	uint16 bo_ops;      // Buffer operations // buf_ops
	uint16 bo_object;	// Place to store VM object // vm_object
	uint16 bo_synclist;	// dirty vnode list // bufobj
	uint32 bo_private;	// private pointer
	bufv bo_clean;	    // Clean buffers
	bufv bo_dirty;	    // Dirty buffers
	uint8 bo_numoutput;	// Writes in progress
	uint16 bo_flag;	    // Flags
	uint16 bo_bsize;	// Block size for i/o
}