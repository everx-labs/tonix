pragma ton-solidity >= 0.58.2;
import "proc_h.sol";
import "vmem.sol";
struct svm {
    s_proc cur_proc;
    uma_zone[] sz;
    s_vmem[] vmem;
}
import "uma_int.sol";
interface iumaz {
    function uma_ctor(bytes mem, uint16 size, bytes arg, uint16 flags) external returns (uint16);
    function uma_dtor(bytes mem, uint16 size, bytes arg) external;
    function uma_init(bytes mem, uint16 size, uint16 flags) external returns (uint16);
    function uma_fini(bytes mem, uint16 size) external;
}

interface ialloc {
    function uma_alloc(uma_zone zone, uint16 size, uint16 domain, bytes pflag, uint16 wait) external returns (bytes);
    function uma_free(bytes item, uint16 size, uint16 pflag) external;
}
library icore {
    function uma_zcreate(string name, uint16 size, uint16 ctor, uint16 dtor, uint16 uminit, uint16 fini, uint16 align, uint32 flags) internal returns (uma_zone) {}
    function uma_zsecond_create(string name, uint16 ctor, uint16 dtor, uint16 zinit, uint16 zfini, uma_zone primary) internal returns (uma_zone) {}
    function uma_zdestroy(uma_zone zone) internal {}
    function uma_zalloc_arg(uma_zone zone, bytes arg, uint16 flags) internal returns (bytes) {}
    function uma_zalloc_domain(uma_zone zone, bytes arg, uint16 domain, uint16 flags) internal returns (bytes) {}
    function uma_zalloc(uma_zone zone, uint16 flags) internal returns (bytes) {}
    function uma_zfree_arg(uma_zone zone, bytes item, bytes arg) internal {}
    function uma_zfree(uma_zone zone, bytes item) internal {}
    function uma_zwait(uma_zone zone) internal {}
    function uma_reclaim(uint16 req) internal {}
    function uma_reclaim_domain(uint16 req, uint16 domain) internal {}
    function uma_zone_reclaim(uma_zone, uint16 req) internal {}
    function uma_zone_reclaim_domain(uma_zone, uint16 req, uint16 domain) internal {}
    function uma_set_align(uint16 align) internal {}
    function uma_zone_reserve(uma_zone zone, uint16 nitems) internal {}
    function uma_zone_reserve_kva(uma_zone zone, uint16 nitems) internal returns (uint16) {}
    function uma_zone_set_max(uma_zone zone, uint16 nitems) internal returns (uint16) {}
    function uma_zone_get_max(uma_zone zone) internal returns (uint16) {}
    function uma_zone_get_cur(uma_zone zone) internal returns (uint16) {}

    function uma_zone_set_init(uma_zone zone, uint16 uminit) internal {
        zone.uz_keg.uk_init = uminit;
    }

    function uma_zone_set_fini(uma_zone zone, uint16 fini) internal {
        zone.uz_keg.uk_fini = fini;
    }
    function uma_zone_set_zinit(uma_zone zone, uint16 zinit) internal {
        zone.uz_init = zinit;
    }
    function uma_zone_set_zfini(uma_zone zone, uint16 zfini) internal {
        zone.uz_fini = zfini;
    }
    function uma_zone_set_allocf(uma_zone zone, uint16 allocf) internal {
        zone.uz_keg.uk_allocf = allocf;
    }
    function uma_zone_set_freef(uma_zone zone, uint16 freef) internal {
        zone.uz_keg.uk_freef = freef;
    }
    function uma_prealloc(uma_zone zone, uint16 itemcnt) internal {}
    function uma_zone_exhausted(uma_zone zone) internal returns (bool) {}
    function uma_zone_memory(uma_zone zone) internal returns (uint16) {}
    function uma_reclaim_wakeup() internal {}
    function uma_reclaim_worker(bytes ) internal {}
    function uma_limit() internal returns (uint32) {}
    function uma_size() internal returns (uint32) {}
    function uma_avail() internal returns (uint32) {}
}
/*struct uma_zone {
    uint16 uz_flags;
    uint16 uz_size;
    uint16 uz_ctor;
    uint16 uz_dtor;
    uint16 uz_max_items;
    uint16 uz_bucket_size;
    uint16 uz_bucket_size_max;
    uma_keg uz_keg;
    uint16 uz_init;
    uint16 uz_fini;
    uint16 uz_items;
    uint16 uz_link;
    uint16 uz_allocs;
    uint16 uz_frees;
    uint16 uz_fails;
    string uz_name;
    uint16 uz_bucket_size_min;
}*/

struct uma_type_header {
    /* Static per-zone data, some extracted from the supporting keg. */
	bytes10 uth_name;   //[UTH_MAX_NAME];
	uint16 uth_align;	/* Keg: alignment. */
	uint16 uth_size;	/* Keg: requested size of item. */
	uint16 uth_rsize;	/* Keg: real size of item. */
	uint16 uth_maxpages;/* Keg: maximum number of pages. */
	uint16 uth_limit;	/* Keg: max items to allocate. */
	/* Current dynamic zone/keg-derived statistics. */
	uint16 uth_pages;	/* Keg: pages allocated. */
	uint16 uth_keg_free;	/* Keg: items free. */
	uint16 uth_zone_free;	/* Zone: items free. */
	uint16 uth_bucketsize;	/* Zone: desired bucket size. */
	uint16 uth_zone_flags;	/* Zone: flags. */
	uint16 uth_allocs;	/* Zone: number of allocations. */
	uint16 uth_frees;	/* Zone: number of frees. */
	uint16 uth_fails;	/* Zone: number of alloc failures. */
	uint16 uth_sleeps;	/* Zone: number of alloc sleeps. */
	uint16 uth_xdomain;	/* Zone: Number of cross domain frees. */
	uint16 _uth_reserved1;	/* Reserved. */
}
