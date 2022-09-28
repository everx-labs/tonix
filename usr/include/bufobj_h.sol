pragma ton-solidity >= 0.64.0;
import "ucred_h.sol";

struct s_buf {
    uint32 b_bufobj;   // s_bufobj
    uint32 b_bcount;   // originally requested buffer size, can serve as a bounds check against EOF.  For most, but not all uses, b_bcount == b_bufsize
    uint32 b_caller1;
    uint32 b_data;
    uint8 b_error;
    uint8 b_iocmd;    // BIO_* bio_cmd from bio.h
    uint16 b_ioflags;  // BIO_* bio_flags from bio.h
    uint32 b_iooffset;
    uint32 b_resid;    // Number of bytes remaining in I/O.  After an I/O operation completes, b_resid is usually 0 indicating 100% success
    uint64 b_ckhash;   // B_CKHASH requested check-hash
    uint32 b_blkno;    // Underlying physical block number
    uint32 b_offset;   // Offset into file
    uint8 b_vflags;   // BV_* flags
    uint32 b_flags;    // B_* flags.
    uint8 b_xflags;   // extra flags
    uint32 b_bufsize;  // Allocated buffer size
    uint32 b_kvasize;  // size of kva for buffer
    // Buffers support piecemeal, unaligned ranges of dirty data that need to be written to backing store
    // The range is typically clipped at b_bcount (not b_bufsize)
    uint32 b_dirtyoff; // Offset in buffer of dirty region
    uint32 b_dirtyend; // Offset of end of dirty region
    uint32 b_kvabase;  // base kva for buffer
    uint32 b_lblkno;   // Logical block number
    uint16 b_vp;       // Device vnode
    s_ucred b_rcred;   // Read credentials reference
    s_ucred b_wcred;   // Write credentials reference
    uint16 b_npages;
}
struct s_bufv {
    s_buf[] bv_hd; // Sorted blocklist
    uint8 bv_cnt; // Number of buffers
}
struct s_bufobj {
    s_buf_ops bo_ops;    // Buffer operations
    bytes bo_private;    // private pointer
    s_bufv bo_clean;    // Clean buffers
    s_bufv bo_dirty;    // Dirty buffers
    uint8 bo_numoutput; // Writes in progress
    uint16 bo_flag;      // Flags
    uint16 bo_bsize;     // Block size for i/o
}

struct s_buf_ops {
    string bop_name;
    uint32 bop_write;   // int b_write_t(s_buf)
    uint32 bop_strategy;// b_strategy_t(s_bufobj, s_buf)
    uint32 bop_sync;    // int b_sync_t (s_bufobj, int waitfor)
    uint32 bop_bdflush; // b_bdflush_t(s_bufobj, s_buf)
}

	//struct buf_ops	*bo_ops;	/* - Buffer operations */
	//struct vm_object *bo_object;	/* v Place to store VM object */
	//LIST_ENTRY(bufobj) bo_synclist;	/* S dirty vnode list */
	//void		*bo_private;	/* private pointer */
	//struct bufv	bo_clean;	/* i Clean buffers */
	//struct bufv	bo_dirty;	/* i Dirty buffers */
	//int		bo_numoutput;	/* i Writes in progress */
	//u_int		bo_flag;	/* i Flags */
	//int		bo_domain;	/* - Clean queue affinity */
	//int		bo_bsize;	/* - Block size for i/o */
