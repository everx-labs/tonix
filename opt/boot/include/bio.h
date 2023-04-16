pragma ton-solidity >= 0.66.0;
struct bio {
    uint8 bio_cmd;      // I/O operation
    uint8 bio_flags;    // General flags
    uint32 bio_dev;     // Device to do I/O on // cdev
    uint32 bio_disk;    // Valid below geom_disk.c only
    uint32 bio_offset;  // Offset into file
    uint32 bio_bcount;  // Valid bytes in buffer
    uint32 bio_data;    // Memory, superblocks, indirect etc
    TvmCell[] bio_ma;   // Or unmapped // struct vm_page
    uint8 bio_ma_n;     // Number of pages in bio_ma
    uint8 bio_error;    // Errno for BIO_ERROR
    uint32 bio_resid;   // Remaining I/O in bytes
    uint32 bio_length;  // Like bio_bcount
    uint32 bio_completed; // Inverse of bio_resid
    uint32 bio_t0;      // Time request started
    uint32 bio_pblkno;  // physical block number
}
struct bio_queue {
    bio[] queue;
    uint32 last_offset;
    uint32 insert_point;
    uint8 total;
    uint8 batched;
}
