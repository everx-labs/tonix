pragma ton-solidity >= 0.59.0;

enum zfreeskip { SKIP_NONE, SKIP_CNT, SKIP_DTOR, SKIP_FINI }

struct uma_bucket {
    uint16 ub_link;    // Link into the zone
    uint16 ub_cnt;     // Count of items in bucket.
    uint16 ub_entries; // Max items.
    bytes[] ub_bucket; // actual allocation storage
}

struct uma_hash {
    uint16 uh_slab_hash; // Hash table for slabs
	uint16 uh_hashsize;	// Current size of the hash table
	uint32 uh_hashmask;	// Mask used during hashing
//	uma_hash_slab[] uh_slab_hash;	// Hash table for slabs
}

struct uma_hash_slab {
	uint32 uhs_hlink;  // Link for hash table
	bytes uhs_data;    // First item
	uma_slab uhs_slab; // Must be last.
}

struct uma_domain {
    uint16 ud_slab;
    uint16 ud_pages;       // Total page count
    uint16 ud_free_items;  // Count of items free in all slabs
    uint16 ud_free_slabs;  // Count of free slabs
    uma_slab[] slabs;
}

struct uma_keg {
    uint16 uk_zones;   // Keg's zones
    uint16 uk_align;   // Alignment mask
    uint16 uk_reserve; // Number of reserved items.
    uint16 uk_size;    // Requested size of each item
    uint16 uk_rsize;   // Real size of each item
    uint16 uk_init;    // Keg's init routine
    uint16 uk_fini;    // Keg's fini routine
    uint16 uk_allocf;  // Allocation function
    uint16 uk_freef;   // Free routine
    uint16 uk_offset;  // Next free offset from base KVA
    uint16 uk_kva;     // Zone base KVA
    uint16 uk_pgoff;   // Offset to uma_slab struct
    uint16 uk_ppera;   // pages per allocation from backend
    uint16 uk_ipers;   // Items per slab
    uint32 uk_flags;   // Internal flags
    bytes8 uk_name;    // Name of creating zone.
    uint16 uk_link;    // List of all kegs
    uma_hash uk_hash;
    uma_domain[] uk_domain; // Keg's slab lists.
}

struct uma_slab {
    uint16 us_link;      // slabs in zone
    uint16 us_freecount; // How many are free?
    uint8 us_flags;      // Page flags
    uint8 us_domain;     // Backing NUMA domain.
    uint16 us_free;      // Free bitmask, flexible.
    bytes us_data;
}

struct uma_cell_slab {
    uint16 ucs_link;      // slabs in zone
    uint16 ucs_freecount; // How many are free?
    uint8 ucs_flags;      // Page flags
    uint8 ucs_domain;     // Backing NUMA domain.
    uint16 ucs_free;      // Free bitmask, flexible.
    TvmCell ucs_data;
}

struct uma_zone_domain {
    uint16 uzd_nitems;        // total item count
    uma_bucket uzd_cross;     // Fills from cross buckets
    uma_bucket[] uzd_buckets; // full buckets
}

struct uma_zone {
    uint32 uz_flags;       // Flags inherited from kegs
    uint16 uz_size;        // Size inherited from kegs
    uint16 uz_ctor;        // Constructor for each allocation
    uint16 uz_dtor;        // Destructor
    uint16 uz_max_items;   // Maximum number of items to alloc
    uint16 uz_bucket_size; // Number of items in full bucket
    uint16 uz_bucket_size_max; // Maximum number of bucket items
    uint16 uz_init;        // Initializer for each item
    uint16 uz_fini;        // Finalizer for each item.
    uint16 uz_items;       // Total items count & sleepers
    uint16 uz_link;        // List of all zones in keg
    uint16 uz_allocs;      // Total number of allocations
    uint16 uz_frees;       // Total number of frees
    uint16 uz_fails;       // Total number of alloc failures
    bytes8 uz_name;        // Text name of the zone
    uint16 uz_bucket_size_min; // Min number of items in bucket
    uma_keg uz_keg;        // This zone's keg if !CACHE
    uma_cache uz_cpu;      // Per cpu caches
    uma_zone_domain uz_domain;
}

struct uma_bucket_zone {
	bytes8 ubz_name;
	uint16 ubz_entries;	// Number of items it can hold.
	uint16 ubz_maxsize;	// Maximum allocation size per-item.
	uma_zone ubz_zone;
}

struct uma_cache_bucket {
    uint16 ucb_cnt;
    uint16 ucb_entries;
    uma_bucket ucb_bucket;
}

struct uma_cache {
	uint32 uc_allocs;	// Count of allocations
	uint32 uc_frees;	// Count of frees
    uint32 uc_size;
    uint32 uc_flags;
	uma_bucket uc_freebucket;	 // Bucket we're freeing to
	uma_bucket uc_allocbucket; // Bucket to allocate from
	uma_bucket uc_crossbucket; // cross domain bucket
}

struct it {
    uint8 type_id;
    uint8 subtype;
    uint16 device_id;
    uint16 index;
    uint16 nitems;
    uint16 segment;
    uint16 offset;
    uint32 size;
}

library uma {

    uint8 constant vm_ndomains = 1;

    uint32 constant UMA_ZFLAG_OFFPAGE  = 0x00200000; // Force the slab structure allocation off of the real memory.
    uint32 constant UMA_ZFLAG_HASH     = 0x00400000; // Use a hash table instead of caching information in the vm_page.
    uint32 constant UMA_ZFLAG_VTOSLAB  = 0x00800000; // Zone uses vtoslab for lookup.
    uint32 constant UMA_ZFLAG_CTORDTOR = 0x01000000; // Zone has ctor/dtor set.
    uint32 constant UMA_ZFLAG_LIMIT    = 0x02000000; // Zone has limit set.
    uint32 constant UMA_ZFLAG_CACHE    = 0x04000000; // uma_zcache_create()d it
    uint32 constant UMA_ZFLAG_BUCKET   = 0x10000000; // Bucket zone.
    uint32 constant UMA_ZFLAG_INTERNAL = 0x20000000; // No offpage no PCPU.
    uint32 constant UMA_ZFLAG_TRASH    = 0x40000000; // Add trash ctor/dtor.
    uint32 constant UMA_ZFLAG_INHERIT = UMA_ZFLAG_OFFPAGE | UMA_ZFLAG_HASH | UMA_ZFLAG_VTOSLAB | UMA_ZFLAG_BUCKET | UMA_ZFLAG_INTERNAL;

    uint8 constant SLABZONE0_SIZE    = 8;
    uint8 constant SLABZONE0_SETSIZE = 32;
    uint8 constant SLABZONE1_SIZE    = 8;
    uint8 constant UMA_ALIGN_PTR     = 3;
    uint8 constant UMA_SUPER_ALIGN   = 64;

    uint8 constant UMA_INIT    = 1;
    uint8 constant ZONE_INIT   = 2;
    uint8 constant KEG_INIT    = 3;
    uint8 constant SLAB0_INIT  = 4;
    uint8 constant SLAB1_INIT  = 5;
    uint8 constant HASH_INIT   = 6;
    uint8 constant INODES_INIT = 7;
    uint8 constant ZERO_INIT   = 66;

    uint8 constant UMA_ANYDOMAIN = 0;
    uint8 constant UMA_RECLAIM_DRAIN     = 1; // release bucket cache
    uint8 constant UMA_RECLAIM_DRAIN_CPU = 2; // release bucket and per-CPU caches
    uint8 constant UMA_RECLAIM_TRIM      = 3; // trim bucket cache to WSS
    uint32 constant UMA_STREAM_VERSION = 0x00000001;
    uint8 constant UTH_MAX_NAME = 32;
    uint32 constant UTH_ZONE_SECONDARY = 0x00000001;

    uint8 constant BUCKET_MAX = 255;
    uint16 constant PAGE_SIZE = 4096;
    uint16 constant PAGE_SHIFT = 12;
    uint16 constant PAGE_MASK = PAGE_SIZE - 1;
    uint16 constant UMA_SLAB_SIZE = PAGE_SIZE;
    uint16 constant UMA_CELL_SLAB_SIZE = 127;
    uint16 constant UMA_SLAB_MASK = PAGE_SIZE - 1; // Mask to get back to the page
    uint16 constant UMA_SLAB_SHIFT = PAGE_SHIFT; // Number of bits PAGE_MASK
    uint16 constant UMA_HASH_SIZE_INIT = 32;

    uint8 constant UMA_SMALLEST_UNIT = 8;
//    uint8 constant SLAB_MAX_SETSIZE = 255;
    uint16 constant	UMA_CACHESPREAD_MAX_SIZE = 32 * 1024;
    uint8 constant UMA_MAX_WASTE = 10;
    uint8 constant UMA_MIN_EFF = 100 - UMA_MAX_WASTE;

    uint8 constant UMA_ZONE    = 1;
    uint8 constant ZONES_ZONE  = 2;
    uint8 constant KEGS_ZONE   = 3;
    uint8 constant SLAB0_ZONE  = 4;
    uint8 constant SLAB1_ZONE  = 5;
    uint8 constant HASH_ZONE   = 6;
    uint8 constant INODES_ZONE = 7;
}

library libmalloc {
    uint16 constant M_NOWAIT      = 0x0001; // do not block
    uint16 constant M_WAITOK      = 0x0002; // ok to block
    uint16 constant M_NORECLAIM   = 0x0080; // do not reclaim after failure
    uint16 constant M_ZERO        = 0x0100; // bzero the allocation
    uint16 constant M_NOVM        = 0x0200; // don't ask VM for pages
    uint16 constant M_USE_RESERVE = 0x0400; // can alloc out of reserve memory
    uint16 constant M_NODUMP      = 0x0800; // don't dump pages in this allocation
    uint16 constant M_FIRSTFIT    = 0x1000; // only for vmem, fast fit
    uint16 constant M_BESTFIT     = 0x2000; // only for vmem, low fragmentation
    uint16 constant M_EXEC        = 0x4000; // allocate executable space
    uint16 constant M_NEXTFIT     = 0x8000; // only for vmem, follow cursor
}