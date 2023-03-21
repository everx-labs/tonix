pragma ton-solidity >= 0.59.0;

import "uma_int.sol";
import "libslab.sol";
import "libkeg.sol";
import "libloadinfo.sol";
import "uer.sol";

library libcache {

    using libbucket for uma_bucket;

    uint8 constant UMA_CACHE_HEADER_SIZEOF = 34; // 3 * UMA_BUCKET_HEADER_SIZEOF + 16

    function init(uma_cache cache, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.ARG_SIZE_MISMATCH;
        if (size < UMA_CACHE_HEADER_SIZEOF)
            return uer.ARG_SIZE_TOO_SMALL;

        uint16 from = 0;
        uint16 to = 16;
        uint128 v = uint128(bytes16(arg[from : to]));
        cache.uc_allocs = uint32(v >> 96 & 0xFFFFFFFF);
        cache.uc_frees = uint32(v >> 64 & 0xFFFFFFFF);
        cache.uc_size = uint32(v >> 32 & 0xFFFFFFFF);
        cache.uc_flags = uint32(v & 0xFFFFFFFF);

        /*uma_bucket uc_freebucket;
        uma_bucket uc_allocbucket;
        uma_bucket uc_crossbucket;*/
        from = to;
        to += libbucket.UMA_BUCKET_HEADER_SIZEOF;
        ec = cache.uc_freebucket.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        from = to;
        to += libbucket.UMA_BUCKET_HEADER_SIZEOF;
        ec = cache.uc_allocbucket.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        from = to;
        to += libbucket.UMA_BUCKET_HEADER_SIZEOF;
        ec = cache.uc_crossbucket.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
    }

    function fini(uma_cache cache, uint16 size) internal returns (bytes res) {
	    (uint32 uc_allocs, uint32 uc_frees, uint32 uz_size, uint32 uz_flags, uma_bucket uc_freebucket, uma_bucket uc_allocbucket, uma_bucket uc_crossbucket) = cache.unpack();
        uint128 v = (uint128(uc_allocs) << 96) + (uint128(uc_frees) << 64) + (uint128(uz_size) << 32) + uz_flags;
        res.append("" + bytes16(v));
        res.append(uc_freebucket.fini(libbucket.UMA_BUCKET_HEADER_SIZEOF));
        res.append(uc_allocbucket.fini(libbucket.UMA_BUCKET_HEADER_SIZEOF));
        res.append(uc_crossbucket.fini(libbucket.UMA_BUCKET_HEADER_SIZEOF));
        if (size > UMA_CACHE_HEADER_SIZEOF) {
            // res.append(uc_crossbucket.ucb_bucket.fini(size - UMA_CACHE_HEADER_SIZEOF));
        }
    }
}

library libcachebucket {

    using libbucket for uma_bucket;
    uint8 constant UMA_CACHE_BUCKET_HEADER_SIZEOF = 10; // UMA_BUCKET_HEADER_SIZEOF + 4;

    function init(uma_cache_bucket bucket, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.ARG_SIZE_MISMATCH;
        if (size < UMA_CACHE_BUCKET_HEADER_SIZEOF)
            return uer.ARG_SIZE_TOO_SMALL;
        uma_bucket ucb_bucket;
        uint16 from;
        uint16 to = 4;
        uint32 v = uint32(bytes4(arg[from : to]));
        from = to;
        to = size - libbucket.UMA_BUCKET_HEADER_SIZEOF;
        ec = ucb_bucket.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        bucket = uma_cache_bucket(uint16(v >> 16 & 0xFFFF), uint16(v & 0xFFFF), ucb_bucket);
    }

    function fini(uma_cache_bucket bucket, uint16 size) internal returns (bytes res) {
        (uint16 ucb_cnt, uint16 ucb_entries, uma_bucket ucb_bucket) = bucket.unpack();
        uint32 v = (uint32(ucb_cnt) << 16) + ucb_entries;
        res = "" + bytes4(v);
        res.append(ucb_bucket.fini(size - 4));
    }

}

library libbucket {

    uint8 constant UMA_BUCKET_HEADER_SIZEOF = 6;

//    function uma_init(bytes mem, uint16 size, uint32 flags) internal virtual returns (uint8, bytes) {}
    function init(uma_bucket bucket, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.ARG_SIZE_MISMATCH;
        uint16 to = UMA_BUCKET_HEADER_SIZEOF;
        if (size < to)
            return uer.ARG_SIZE_TOO_SMALL;
        uint48 v = uint48(bytes6(arg));
        bytes data;
        if (size > to)
            data = arg[to : ];
        bucket = uma_bucket(uint16(v >> 32 & 0xFFFF), uint16(v >> 16 & 0xFFFF), uint16(v & 0xFFFF), [data]);
    }

//    function uma_fini(bytes mem, uint16 size) internal virtual {}
    function fini(uma_bucket bucket, uint16 size) internal returns (bytes res) {
        (uint16 ub_link, uint16 ub_cnt, uint16 ub_entries, bytes[] ub_bucket) = bucket.unpack();
        uint48 v = (uint48(ub_link) << 32) + (uint48(ub_cnt) << 16) + ub_entries;
        res = "" + bytes6(v);
        if (size > UMA_BUCKET_HEADER_SIZEOF)
            for (bytes b: ub_bucket)
                res.append(b);
    }

}

library libudomain {

    using libbucket for uma_bucket;
    uint8 constant UMA_ZONE_DOMAIN_HEADER_SIZEOF = 8; //2 + libbucket.UMA_BUCKET_HEADER_SIZEOF;

    function init(uma_zone_domain udomain, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.ARG_SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = 2;
        if (size < to)
            return uer.ARG_SIZE_TOO_SMALL;
        uint16 nitems = uint16(bytes2(arg));
        from = to;
        to += libbucket.UMA_BUCKET_HEADER_SIZEOF;
        if (size < to)
            return uer.ARG_SIZE_TOO_SMALL;
        udomain.uzd_nitems = nitems;
        uma_bucket uzd_cross;
        ec = uzd_cross.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        udomain.uzd_cross = uzd_cross;
        if (size == to)
            return 0;
        if (nitems <= uzd_cross.ub_cnt)
            return 0;
        uma_bucket[] uzd_buckets;
        uma_bucket bucket;
        for (uint i = 0; i < uzd_cross.ub_cnt - nitems; i++) {
            from = to;
            to += libbucket.UMA_BUCKET_HEADER_SIZEOF;
            bucket.init(arg[from : to], to - from);
            uzd_buckets.push(bucket);
        }
    }

    function fini(uma_zone_domain udomain, uint16 size) internal returns (bytes res) {
        (uint16 uzd_nitems, uma_bucket uzd_cross, uma_bucket[] uzd_buckets) = udomain.unpack();
        res = "" + bytes2(uzd_nitems);
        res.append(uzd_cross.fini(libbucket.UMA_BUCKET_HEADER_SIZEOF));
        if (size > UMA_ZONE_DOMAIN_HEADER_SIZEOF)
            for (uma_bucket bucket: uzd_buckets)
                res.append(bucket.fini(libbucket.UMA_BUCKET_HEADER_SIZEOF));
    }
}
library libzone {

    using libslab for uma_slab;
    using libkeg for uma_keg;
    using libzone for uma_zone;
    using libudomain for uma_zone_domain;
    using libcache for uma_cache;

    uint8 constant UMA_ZONE_HEADER_SIZEOF = 40;
    uint8 constant UMA_ZONE_ARG_CTOR_SIZEOF = 10;
//    uint8 constant UMA_ZONE_SIZEOF = 96;//UMA_ZONE_HEADER_SIZEOF + 40 + 8; //libkeg.UMA_KEG_SIZEOF + libudomain.UMA_ZONE_DOMAIN_HEADER_SIZEOF;
    uint8 constant UMA_ZONE_SIZEOF = 138;//UMA_ZONE_HEADER_SIZEOF + 56 + 34 + 8; //libkeg.UMA_KEG_SIZEOF + libcache.UMA_CACHE_HEADER_SIZEOF + libudomain.UMA_ZONE_DOMAIN_HEADER_SIZEOF;

    uint8 constant UMA_BUCKET_ZONE_HEADER_SIZEOF = 52; //UMA_ZONE_HEADER_SIZEOF + 12;

    uint32 constant UMA_ZONE_UNMANAGED   = 0x0001;  // Don't regulate the cache size, even under memory pressure.
    uint32 constant UMA_ZONE_ZINIT       = 0x0002;  // Initialize with zeros
    uint32 constant UMA_ZONE_CONTIG      = 0x0004;  // Physical memory underlying an object must be contiguous
    uint32 constant UMA_ZONE_NOTOUCH     = 0x0008;  // UMA may not access the memory
    uint32 constant UMA_ZONE_MALLOC      = 0x0010;  // For use by malloc(9) only!
    uint32 constant UMA_ZONE_NOFREE      = 0x0020;  // Do not free slabs of this type!
    uint32 constant UMA_ZONE_MTXCLASS    = 0x0040;  // Create a new lock class
    uint32 constant UMA_ZONE_VM          = 0x0080;  // Used for internal vm datastructures on
    uint32 constant UMA_ZONE_NOTPAGE     = 0x0100;  // allocf memory not vm pages
    uint32 constant UMA_ZONE_SECONDARY   = 0x0200;  // Zone is a Secondary Zone
    uint32 constant UMA_ZONE_NOBUCKET    = 0x0400;  // Do not use buckets.
    uint32 constant UMA_ZONE_MAXBUCKET   = 0x0800;  // Use largest buckets.
    uint32 constant UMA_ZONE_CACHESPREAD = 0x2000;  // Spread memory start locations across all possible cache lines.  May require many virtually contiguous backend pages and can fail early
    uint32 constant UMA_ZONE_NODUMP      = 0x4000;  // Zone's pages will not be included in mini-dump
    uint32 constant UMA_ZONE_PCPU        = 0x8000;  // Allocates mp_maxid + 1 slabs of PAGE_S
    uint32 constant UMA_ZONE_FIRSTTOUCH  = 0x10000; // First touch NUMA policy
    uint32 constant UMA_ZONE_ROUNDROBIN  = 0x20000; // Round-robin NUMA policy.
    uint32 constant UMA_ZONE_SMR         = 0x40000; // Safe memory reclamation defers frees until all read sections have exited.  This flag creates a unique SMR context for this * zone.  To share contexts see * uma_zone_set_smr() below. See sys/smr.h for more detai
    uint32 constant UMA_ZONE_NOKASAN     = 0x80000; // Disable KASAN verification.  This is implied by NOFREE.  Cache zones are not verified by defau
    uint32 constant UMA_ZONE_INHERIT = UMA_ZONE_NOTOUCH | UMA_ZONE_MALLOC | UMA_ZONE_NOFREE | UMA_ZONE_VM | UMA_ZONE_NOTPAGE | UMA_ZONE_PCPU | UMA_ZONE_FIRSTTOUCH | UMA_ZONE_ROUNDROBIN | UMA_ZONE_NOKASAN;

    uint8 constant UMA_ZONE     = 1;
    uint8 constant ZONES_ZONE   = 2;
    uint8 constant KEGS_ZONE    = 3;
    uint8 constant SLAB0_ZONE   = 4;
    uint8 constant SLAB1_ZONE   = 5;
    uint8 constant HASH_ZONE    = 6;
    uint8 constant INODES_ZONE  = 7;

//    function uma_import(uma_zone zone, bytes arg, uint16 count, uint8 domain, uint32 flags) internal virtual returns (bytes[], uint16) {
    function zone_import(uma_zone zone, bytes arg, uint16 max, uint8 domain, uint16 flags) internal returns (bytes[] bucket, uint16 i) {
        uma_keg keg = zone.uz_keg;
        uint8 ec;
//      bytes itm;
//      def = dom.slabs[0].def_item(keg);
        uint len = arg.length;
        uint16 n_items = uint16(len / keg.uk_size);
        if (n_items > max && flags >= 0)
            n_items = max;
        uint16 rsv = keg.uk_reserve;
//        uint16 from_reserve = n_items > rsv ? rsv : n_items;
//        uint16 over_reserve = n_items - from_reserve;
        uint16 from_reserve = math.min(n_items, rsv);
        uint16 over_reserve = n_items - from_reserve;
        (uint16 idx, uma_slab slab) = keg.fetch_slab(domain);
        if (idx > 0 && (rsv == 0 || keg.uk_domain[domain].ud_free_items >= rsv)) {
            if (slab.us_freecount >= n_items) {
                slab.us_data.append(arg);
                slab.us_freecount -= n_items;
                slab.us_free += over_reserve;
                keg.uk_domain[domain].slabs[idx - 1] = slab;
                keg.uk_domain[domain].ud_free_items -= n_items;
//              if (from_reserve > 0)
//                  keg.uk_reserve -= from_reserve;
                rsv -= from_reserve;
//              if (slab.us_free > keg.uk_reserve)
//                  keg.uk_offset = slab.us_free - keg.uk_reserve;
                if (slab.us_free > rsv)
                    keg.uk_offset = slab.us_free - rsv;
                keg.uk_reserve = rsv;
                zone.uz_keg = keg;
                zone.uz_allocs++;
                zone.uz_items += n_items;
                i = n_items;
            }
            /*for (i = 0; i < max; ) {
                (off, itm) = slab.alloc_item(keg);
                if (off == 0)
                    ec = uer.ITEM_IN_SLAB_ALLOC_FAILED;
                else
                    (ec, itm) = zone.item_ctor(zone.uz_flags, zone.uz_size, arg, flags, itm);
                if (ec == 0) {
                    bucket.push(itm);
                    i++;
    	            if (keg.uk_reserve > 0 && keg.uk_domain[domain].ud_free_items <= keg.uk_reserve)
                        break;
                } else
                    break;
            }*/
        } else
            ec = uer.SLAB_FETCH_FAILED;
        if (ec > 0) {
            i = 0;
            zone.uz_cpu.uc_freebucket.ub_bucket.push(arg);
            zone.uz_cpu.uc_freebucket.ub_cnt += ec;
        } else {
            bucket.push(arg);
        }
    }

    function _zaddr(uint16 zone_id, uint16 slab_id, uint16 offset) internal returns (uint32) {
        return (uint32(zone_id) << 24) + (uint32(slab_id) << 16) + offset;
    }

    function alloc_item(uma_zone zone, bytes udata, uint8 domain, uint32 flags) internal returns (uint32 addr, bytes item) {
        uint8 ec;
        uint16 off;
        if (zone.uz_max_items > 0 && zone.alloc_limit(1, flags) == 0)
            ec = uer.ZONE_ALLOC_LIMIT_EXCEEDED;
        uma_keg keg = zone.uz_keg;
        (uint16 slab_id, uma_slab slab) = keg.fetch_slab(domain);
        if (slab_id == 0)
            ec = uer.SLAB_FETCH_FAILED;
        else {
            (off, item) = slab.alloc_item(keg);
            if (off == 0)
                ec = uer.ITEM_IN_SLAB_ALLOC_FAILED;
        }
        if (ec == 0) {
            if ((zone.uz_flags & uma.UMA_ZFLAG_CTORDTOR) > 0 && zone.uz_ctor > 0)
                (ec, item) = zone.item_ctor(zone.uz_flags, zone.uz_size, udata, flags, item);
//            if (zone.uz_init > 0)
//                (ec, item) = zone.item_init()
        }
        if (ec == 0) {
            slab.us_data.append(item);
            keg.uk_domain[domain].ud_free_items--;
            keg.uk_domain[domain].slabs[slab_id - 1] = slab;
            keg.uk_pgoff = slab_id;
            if (keg.uk_reserve > 0) {
                keg.uk_reserve--;
                keg.uk_offset++;
            } else
                keg.uk_offset = slab.us_free;
            addr = _zaddr(0, keg.uk_offset, off);
            zone.uz_allocs++;
            zone.uz_items++;
        } else {
            zone.uz_fails++;
            if (zone.uz_max_items > 0)
                zone.free_limit(1);
        }
        zone.uz_keg = keg;
    }

    function def_item(uma_zone zone, uint8 item_type) internal returns (bytes item) {
        uma_bucket bu = zone.uz_domain.uzd_cross;
        item = bu.ub_bucket[item_type - 2];
    }

    function free_item(uma_zone zone, bytes item, bytes udata, zfreeskip skip) internal {
        zone.item_dtor(item, zone.uz_size, udata, skip);
        if (skip < zfreeskip.SKIP_FINI && zone.uz_fini > 0) {
//          zone.uz_fini(item, zone.uz_size);
        }
        if (skip == zfreeskip.SKIP_CNT)
            return;
        zone.uz_frees++;
        if (zone.uz_max_items > 0)
            zone.free_limit(1);
    }
    function alloc_limit(uma_zone zone, uint16 count, uint32 ) internal returns (uint16) {
        uint16 old;
        uint16 max;
        max = zone.uz_max_items;
        if (max == 0)
            return 0;
       	old = zone.uz_items + count;
        if (old + count <= max)
            return count;
        if (old < max) {
            zone.free_limit(old + count - max);
            return max - old;
        }
    }
    function free_limit(uma_zone zone, uint16 count) internal {
        uint16 old;
        old = zone.uz_items - count;
        if (old == 0 || old - count >= zone.uz_max_items)
            return;
    }

    function put_bucket(uma_zone zone, uint8 , uma_bucket bucket, bytes udata) internal {
        uma_zone_domain zdom = zone.uz_domain;
        if (bucket.ub_cnt == 0)
            return;
        zdom.uzd_nitems += bucket.ub_cnt;
        if (zdom.uzd_nitems < zone.uz_max_items) { // bucket max items
            if (zdom.uzd_buckets.empty())
                zdom.uzd_buckets.push(bucket);
            return;
        }
        zdom.uzd_nitems -= bucket.ub_cnt;
        zone.uz_domain = zdom;
        zone.bucket_free(bucket, udata);
    }

    function bucket_free(uma_zone zone, uma_bucket bucket, bytes udata) internal {
        if (bucket.ub_cnt != 0)
            zone.bucket_drain(bucket);
        if ((zone.uz_flags & uma.UMA_ZFLAG_BUCKET) == 0)
            udata = "" + bytes4(zone.uz_flags);
//        uint16 idx = bucket_zone_lookup(bucket.ub_entries);
//        if (idx > 0)
//            ubz = _bucket_zones[idx - 1];
//      this.uma_zfree_arg(zone_id, infini.bucket_header_fini(bucket), udata);
    }

    function fetch_bucket(uma_zone zone) internal returns (uma_bucket bucket) {
        uma_zone_domain zdom = zone.uz_domain;
        bool fdtor = false;
        if (zdom.uzd_buckets.empty())
            return zdom.uzd_cross;
        bucket = zdom.uzd_buckets[0];
//    	if (zdom.uzd_nitems < bucket.ub_cnt)
//            this.er("zone_fetch_bucket", zone_id, FETCH_BUCKET_ITEM_COUNT_UNDERFLOW);
//    	if (bucket.ub_cnt > 0)
//            this.er("zone_fetch_bucket", zone_id, FETCH_BUCKET_EMPTY_BUCKET_IN_CACHE);
        zdom.uzd_nitems -= bucket.ub_cnt;
        if (fdtor)
            for (uint16 i = 0; i < bucket.ub_cnt; i++)
                zone.item_dtor(bucket.ub_bucket[i], zone.uz_size, "", zfreeskip.SKIP_NONE);
        zone.uz_domain = zdom;
        return bucket;
    }

    function bucket_drain(uma_zone zone, uma_bucket bucket) internal {
	    uint16 i;
	    if (bucket.ub_cnt == 0)
		    return;
	    if (zone.uz_fini > 0)
		    for (i = 0; i < bucket.ub_cnt; i++) {
//			    zone.uz_fini(bucket.ub_bucket[i], zone.uz_size);
		    }
	    if (zone.uz_max_items > 0)
		    zone.free_limit(bucket.ub_cnt);
	    bucket.ub_cnt = 0;
    }

    uint8 constant ZONE_CTOR = 2;
    uint8 constant KEG_CTOR = 3;
    uint8 constant CHUNK_CTOR = 10;
    uint8 constant CHUNK_HASH_CTOR = 11;
    uint8 constant FILE_HEADER_CTOR = 12;
    uint8 constant ZONE_DTOR = 2;
    uint8 constant KEG_DTOR = 3;
    uint8 constant ZONE_INIT = 2;
    uint8 constant KEG_INIT = 3;
    uint8 constant ZERO_INIT = 10;
    uint8 constant PAGE_ALLOC = 1;
    uint8 constant CONTIG_ALLOC = 2;

    /*function uma_ctor(bytes mem, uint16 size, bytes arg, uint32 flags) internal virtual returns (uint8, bytes) {}
    function uma_dtor(bytes mem, uint16 size, bytes arg) internal virtual {}
    function uma_init(bytes mem, uint16 size, uint32 flags) internal virtual returns (uint8, bytes) {}
    function uma_fini(bytes mem, uint16 size) internal virtual {}
    function uma_import(bytes arg, uint16 count, uint8 domain, uint32 flags) internal virtual returns (bytes[], uint16) {}*/

    function item_ctor(uma_zone zone, uint32 uz_flags, uint16 size, bytes udata, uint32 flags, bytes item) internal returns (uint8 ec, bytes res) {
        res = item;
        if ((uz_flags & uma.UMA_ZFLAG_CTORDTOR) > 0 && zone.uz_ctor > 0) {
            uint16 zc = zone.uz_ctor;
            if (zc == ZONE_CTOR) {
//	            (ec, res) = zone.ctor(zone.def_item(ZONES_ZONE), size, udata, flags);
                uma_zone z;
                (ec, z) = zone_ctor(item, size, udata, flags);
                if (ec == 0)
                    res = z.fini(UMA_ZONE_SIZEOF);
            } else if (zc == CHUNK_CTOR)
                (ec, res) = libloadinfo.chunk_ctor(item, size, udata, flags);
            else if (zc == CHUNK_HASH_CTOR)
                (ec, res) = libloadinfo.chunk_hash_ctor(item, size, udata, flags);
            if (ec == 0)
                return (0, res);
//          else if (zc == KEG_CTOR)
//              (ec, res) = zone.uz_keg.ctor(def_item(KEGS_ZONE), size, udata, flags);
//          if (ec > 0)
//      	    zone.free_item(res, udata, zfreeskip.SKIP_DTOR);
	    }
//      res = item;
    }

    function zone_ctor_arg_fini(string name, uint16 size) internal returns (bytes) {
        return "" + bytes2(size) + name;
    }
    function zone_ctor_arg_init(bytes arg) internal returns (bytes8 name, uint16 size) {
        size = uint16(bytes2(arg[ : 2]));
        name = bytes8(arg[2 : ]);
    }

    function zone_ctor(bytes /*mem*/, uint16 size, bytes udata, uint32 flags) internal returns (uint8 ec, uma_zone zone) {
        if (size != UMA_ZONE_SIZEOF)
            ec = uer.SIZE_MISMATCH;
        else if (udata.length < 2)
            ec = uer.SIZE_TOO_SMALL;
        else {
            (bytes8 zname, uint16 zsize) = zone_ctor_arg_init(udata);
            if (zsize < uma.UMA_SMALLEST_UNIT)
                zsize = uma.UMA_SMALLEST_UNIT;
            zone.uz_name = zname;
            zone.uz_size = zsize;
            zone.uz_flags = flags;
            uma_keg keg;
            keg.uk_name = zname;
            keg.uk_size = zsize;
            keg.uk_rsize = zsize;
            keg.uk_ipers = uma.PAGE_SIZE / zsize;
            keg.uk_ppera = 1;
            keg.uk_flags = flags;
            zone.uz_keg = keg;
        }
    }

    function item_dtor(uma_zone zone, bytes item, uint16 size, bytes udata, zfreeskip skip) internal {
        if (skip < zfreeskip.SKIP_DTOR) {
            uint16 id = zone.uz_dtor;
            if (id == ZONE_DTOR)
        	    zone.dtor(item, size, udata);
            else if (id == KEG_DTOR)
                zone.uz_keg.dtor(item, size, udata);
        }
    }

    function dtor(uma_zone zone, bytes /*arg*/, uint16, bytes) internal {
        uma_keg keg;
        bytes empty;
//        uint16 zone_id = uint16(bytes2(arg));
//        uma_zone zone = _zone(zone_id);
//	    LIST_REMOVE(zone, uz_link);
        if ((zone.uz_flags & (UMA_ZONE_SECONDARY | uma.UMA_ZFLAG_CACHE)) == 0) {
            keg = zone.uz_keg;
            keg.uk_reserve = 0;
        }
//    	zone_reclaim(zone_id, UMA_ANYDOMAIN, M_WAITOK, true);
        if ((zone.uz_flags & (UMA_ZONE_SECONDARY | uma.UMA_ZFLAG_CACHE)) == 0) {
            keg = zone.uz_keg;
//          LIST_REMOVE(keg, uk_link);
            zone.free_item(keg.fini(libkeg.UMA_KEG_SIZEOF), empty, zfreeskip.SKIP_NONE);
        }
    }

    function init(uma_zone zone, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_ZONE_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;

        uint v = uint(bytes32(arg));
        zone = uma_zone(uint32(v >> 224 & 0xFFFFFFFF), uint16(v >> 208 & 0xFFFF), uint16(v >> 192 & 0xFFFF), uint16(v >> 176 & 0xFFFF),
            uint16(v >> 160 & 0xFFFF), uint16(v >> 144 & 0xFFFF), uint16(v >> 128 & 0xFFFF), uint16(v >> 112 & 0xFFFF), uint16(v >> 96 & 0xFFFF),
            uint16(v >> 80 & 0xFFFF), uint16(v >> 64 & 0xFFFF), uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint16(v >> 16 & 0xFFFF),
            bytes8(arg[32 : to]), uint16(v & 0xFFFF), zone.uz_keg, zone.uz_cpu, zone.uz_domain);

        if (size == to)
            return 0;
        uma_keg keg;
        from = to;
        to += libkeg.UMA_KEG_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;

        ec = keg.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        zone.uz_keg = keg;
        if (size == to)
            return 0;
        uma_cache cache;
        from = to;
        to += libcache.UMA_CACHE_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        ec = cache.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        zone.uz_cpu = cache;
        if (size == to)
            return 0;
        uma_zone_domain udomain;
        from = to;
        to += libudomain.UMA_ZONE_DOMAIN_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        ec = udomain.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        zone.uz_domain = udomain;
    }

    function fini(uma_zone zone, uint16 size) internal returns (bytes res) {
        (uint32 uz_flags, uint16 uz_size, uint16 uz_ctor, uint16 uz_dtor, uint16 uz_max_items, uint16 uz_bucket_size, uint16 uz_bucket_size_max,
            uint16 uz_init, uint16 uz_fini, uint16 uz_items, uint16 uz_link, uint16 uz_allocs, uint16 uz_frees, uint16 uz_fails,
            bytes8 uz_name, uint16 uz_bucket_size_min, uma_keg uz_keg, uma_cache uz_cpu, uma_zone_domain uz_domain) = zone.unpack();
        uint v = (uint(uz_flags) << 224) + (uint(uz_size) << 208) + (uint(uz_ctor) << 192) + (uint(uz_dtor) << 176) + (uint(uz_max_items) << 160) +
            (uint(uz_bucket_size) << 144) + (uint(uz_bucket_size_max) << 128) + (uint(uz_init) << 112) + (uint(uz_fini) << 96) + (uint(uz_items) << 80) +
            (uint(uz_link) << 64) + (uint(uz_allocs) << 48) + (uint(uz_frees) << 32) + (uint(uz_fails) << 16) + uz_bucket_size_min;
        res = "" + bytes32(v) + uz_name;
        if (size > UMA_ZONE_HEADER_SIZEOF)
            res.append(uz_keg.fini(libkeg.UMA_KEG_SIZEOF));
        if (size >= UMA_ZONE_SIZEOF)
            res.append(uz_cpu.fini(libcache.UMA_CACHE_HEADER_SIZEOF));
        if (size > UMA_ZONE_HEADER_SIZEOF + libkeg.UMA_KEG_SIZEOF)
            res.append(uz_domain.fini(libudomain.UMA_ZONE_DOMAIN_HEADER_SIZEOF));
    }
}
