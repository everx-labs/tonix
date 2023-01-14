pragma ton-solidity >= 0.64.0;

struct s_malloc_type { // Public data structure describing a malloc type.
    uint8 mti_zone;
    uint8 ks_next;      // malloc_type Next in global chain
    uint8 ks_version;   // Detect programmer error
    string ks_shortdesc;// Printable type name
    string mth_name;    //[MALLOC_MAX_NAME];
//    s_malloc_type_internal ks_mti;  // s_malloc_type_internal
}

struct s_malloc_type_internal {
//    uint32[] mti_probes; //[DTMALLOC_PROBE_MAX]; DTrace probe ID array
    uint8 mti_zone;
    s_malloc_type_stats mti_stats;
}

struct s_malloc_type_stats {
    uint32 mts_memalloced;  // Bytes allocated on CPU
    uint32 mts_memfreed;    // Bytes freed on CPU
    uint32 mts_numallocs;   // Number of allocates on CPU
    uint32 mts_numfrees;    // number of frees on CPU
    uint32 mts_size;        // Bitmask of sizes allocated on CPU
}

struct malloc_type_header {
    string mth_name;    //[MALLOC_MAX_NAME];
}

struct vm_page {
    bytes12 name;
    uint8 len;
    uint32 size;
    string[] data;
}
struct alloc_type {
    bytes12 name;
    uint8 tag;
    uint8 len;
    uint8 next_free;
    uint32 size;
    uint32 set;
}