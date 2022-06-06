pragma ton-solidity >= 0.59.0;

import "uma_int.sol";
import "libzone.sol";


library infini {

    function itoa(uint n) internal returns (string) {
        TvmBuilder b;
        uint d;
        uint r = 10000;

        while (r > 1) {
            if (n >= r) {
                (d, n) = math.divmod(n, r);
                b.storeUnsigned(0x30 + d, 8);
            }
            r /= 10;
        }
        b.storeUnsigned(0x30 + n, 8);
        TvmBuilder b2;
        b2.storeRef(b);
        return b2.toSlice().decode(bytes);
    }

   /************************************************
    * public printers
    ***********************************************/
   function print_core(uma_zone[] zones, uma_keg[] kegs, uma_bucket[] buckets, uma_domain[] domains, uma_cache cache) internal returns (string o) {
        o.append(zones_print(zones));
        if (!kegs.empty())
            o.append(kegs_print(kegs));
        uma_keg[] k2;
        for (uma_zone z: zones)
            k2.push(z.uz_keg);
        o.append(kegs_print(k2));
        o.append(buckets_print(buckets));
        o.append(domains_print(domains));
        o.append(caches_print([cache]));
    }

    function print_zone_info(uma_zone zone, uma_cache cache) internal returns (string o) {
        o = zones_print([zone]);
        o.append(kegs_print([zone.uz_keg]));
        o.append(domains_print(zone.uz_keg.uk_domain));
        o.append(caches_print([cache]));
    }

   /************************************************
    * helper printers
    ***********************************************/

    function flagstoa(uint32[] flags) internal returns (string o) {
        mapping (uint32 => string[4]) fn;
        fn[uma.UMA_ZFLAG_INTERNAL]  = ["INTER", "IN", "I"];
        fn[uma.UMA_ZFLAG_BUCKET]    = ["BUCKT", "BU", "B"];
        fn[uma.UMA_ZFLAG_CACHE]     = ["CACHE", "CS", "C"];
        fn[uma.UMA_ZFLAG_LIMIT]     = ["LIMIT", "LM", "L"];
        fn[uma.UMA_ZFLAG_CTORDTOR]  = ["CDTOR", "CD", "D"];
        fn[libzone.UMA_ZONE_FIRSTTOUCH] = ["F1TCH", "FT", "F"];

        uint nf = flags.length;
        if (nf == 0)
            return "  -  ";
//        uint field_width = 5;
//        uint flags_width = field_width / nf;
        if (nf == 1)
            return fn[flags[0]][0];
        if (nf == 2)
            return fn[flags[0]][1] + " " + fn[flags[1]][1];
        if (nf == 3)
            return fn[flags[0]][2] + " " + fn[flags[1]][2] + " " + fn[flags[2]][2];
        for (uint i = 0; i < nf; i++) {
            o.append(fn[flags[i]][2]);
        }
    }
    function print_flags(uint32 flags) internal returns (string o) {
        uint32[] ff;
        if ((flags & uma.UMA_ZFLAG_INTERNAL) > 0) {
            flags -= uma.UMA_ZFLAG_INTERNAL;
            ff.push(uma.UMA_ZFLAG_INTERNAL);
        }
        if ((flags & uma.UMA_ZFLAG_BUCKET) > 0) {
            flags -= uma.UMA_ZFLAG_BUCKET;
            ff.push(uma.UMA_ZFLAG_BUCKET);
        }
        if ((flags & uma.UMA_ZFLAG_CACHE) > 0) {
            flags -= uma.UMA_ZFLAG_CACHE;
            ff.push(uma.UMA_ZFLAG_CACHE);
        }
        if ((flags & uma.UMA_ZFLAG_LIMIT) > 0) {
            flags -= uma.UMA_ZFLAG_LIMIT;
            ff.push(uma.UMA_ZFLAG_LIMIT);
        }
        if ((flags & uma.UMA_ZFLAG_CTORDTOR) > 0) {
            flags -= uma.UMA_ZFLAG_CTORDTOR;
            ff.push(uma.UMA_ZFLAG_CTORDTOR);
        }
        if ((flags & libzone.UMA_ZONE_FIRSTTOUCH) > 0) {
            flags -= libzone.UMA_ZONE_FIRSTTOUCH;
            ff.push(libzone.UMA_ZONE_FIRSTTOUCH);
        }
        return flagstoa(ff);
    }
    function print_name(bytes8 name) internal returns (string o) {
        TvmBuilder b;
        b.store(name);
        TvmBuilder b2;
        b2.storeRef(b);
        o = string(b2.toSlice().decode(bytes));
    }

    string constant ZONE_HEADING    = "Zone    Size  C D Lim Bsz Bmax  Keg   In Fi Itms Lnk Alc Fre Fail Bmin Flags";
    string constant KEG_HEADING     = "Keg    Zone Alg Res  Sz RSz In Fi AF FF Off KVA POf PpA IpS Flags";
    string constant DOMAIN_HEADING  = "Dom Slb Pgs NSl FrIt FrSl Slabs";
    string constant SLAB_HEADING    = "Lnk FrC Flg Dom NFr Len";
    string constant BUCKET_HEADING  = "Lnk Cur Max Items";
    string constant ZONE_DOMAIN_HEADING = "Zn Fn " + BUCKET_HEADING;
    string constant CACHE_HEADING = "Allc Frs Sz Flags | " + BUCKET_HEADING + " | " + BUCKET_HEADING + " | " + BUCKET_HEADING;

    function zones_print_ext(uma_zone[] zones) internal returns (string o) {
        uma_keg[] kegs;
        uma_domain[] doms;
        uma_bucket[] udombu;
        uma_cache[] caches;
        uma_slab[] slabs;
        for (uma_zone zone: zones) {
            kegs.push(zone.uz_keg);
            for (uma_domain d: zone.uz_keg.uk_domain) {
                doms.push(d);
                for (uma_slab s: d.slabs)
                    slabs.push(s);
            }
            udombu.push(zone.uz_domain.uzd_cross);
            caches.push(zone.uz_cpu);
        }
        o = zones_print(zones) + "\n";
        o.append(kegs_print(kegs) + "\n");
        o.append(domains_print(doms) + "\n");
        o.append(slabs_print(slabs) + "\n");
        o.append(buckets_print(udombu) + "\n");
        o.append(caches_print(caches) + "\n");
    }

    function print_zone(uma_zone zone) internal returns (string o) {
        (uint32 uz_flags, uint16 uz_size, uint16 uz_ctor, uint16 uz_dtor, uint16 uz_max_items, uint16 uz_bucket_size, uint16 uz_bucket_size_max,
        uint16 uz_init, uint16 uz_fini, uint16 uz_items, uint16 uz_link, uint16 uz_allocs, uint16 uz_frees, uint16 uz_fails, bytes8 uz_name,
        uint16 uz_bucket_size_min, uma_keg uz_keg, /*uma_cache uz_cpu*/, uma_zone_domain uz_domain) = zone.unpack();
        o = format("{} {:3} {:2} {}  {}  {:3} {:3} {} {}  {} {:3}   {}  {:3}  {}    {}    {}  ",
            print_name(uz_name), uz_size, uz_ctor, uz_dtor, uz_max_items, uz_bucket_size, uz_bucket_size_max, "" + uz_keg.uk_name,
                uz_init, uz_fini, uz_items, uz_link, uz_allocs, uz_frees, uz_fails, uz_bucket_size_min);
        o.append(print_flags(uz_flags) + "  " + print_zone_domain(uz_domain));
    }

    function print_keg(uma_keg keg) internal returns (string o) {
        (uint16 uk_zones, uint16 uk_align, uint16 uk_reserve, uint16 uk_size, uint16 uk_rsize, uint16 uk_init, uint16 uk_fini, uint16 uk_allocf,
            uint16 uk_freef, uint16 uk_offset, uint16 uk_kva, uint16 uk_pgoff, uint16 uk_ppera, uint16 uk_ipers, uint32 uk_flags, bytes8 uk_name, , , uma_domain[] uk_domain) = keg.unpack();
        o = format("{} {:2}  {}  {:3} {:3} {:3}  {}  {}  {}  {} {:3}   {}  {}   {}  ",
            "" + uk_name, uk_zones, uk_align, uk_reserve, uk_size, uk_rsize, uk_init, uk_fini, uk_allocf, uk_freef, uk_offset, uk_kva, uk_pgoff, uk_ppera);
        o.append(format("{:3} {}  {}    ", uk_ipers, print_flags(uk_flags), uk_domain.length));
        o.append((uk_domain.empty() ? "" : print_domain(uk_domain[0])));
    }

    function print_domain(uma_domain dom) internal returns (string o) {
        (uint16 ud_slab, uint16 ud_pages, uint16 ud_free_items, uint16 ud_free_slabs, uma_slab[] slabs) = dom.unpack();
        string ss;
        for (uma_slab sb: slabs)
            ss.append(" " + itoa(sb.us_data.length));
        o = itoa(ud_slab) + "   " + itoa(ud_pages) + "   " + itoa(slabs.length) + " ";
        o.append(format("{:4}", ud_free_items));
        o.append("   " + itoa(ud_free_slabs) + "   [" + ss + " ]");
    }

    function print_slab(uma_slab slab) internal returns (string) {
        (uint16 us_link, uint16 us_freecount, uint8 us_flags, uint8 us_domain, uint16 us_free, bytes us_data) = slab.unpack();
        return format(" {}  {:3}  {}   {} {:3} {:4}", us_link, us_freecount, us_flags, us_domain, us_free, us_data.length);
    }

    function print_cell_slab(uma_cell_slab slab) internal returns (string) {
        (uint16 ucs_link, uint16 ucs_freecount, uint8 ucs_flags, uint8 ucs_domain, uint16 ucs_free, TvmCell ucs_data) = slab.unpack();
        (uint cells, uint bits, uint refs) = ucs_data.dataSize(2000);
        return format(" {}  {:3}  {}   {} {:3} {:4} {:6} {:4}", ucs_link, ucs_freecount, ucs_flags, ucs_domain, ucs_free, cells, bits, refs);
    }

    function print_bucket(uma_bucket bucket) internal returns (string) {
        (uint16 ub_link, uint16 ub_cnt, uint16 ub_entries, bytes[] ub_bucket) = bucket.unpack();
        string ss;
        for (bytes b: ub_bucket)
            ss.append(" " + itoa(b.length));
        return format("{}   {}  {:2}  [{} ]", ub_link, ub_cnt, ub_entries, ss);
    }

    function print_cache_bucket(uma_cache_bucket ucb) internal returns (string) {
        (uint16 ucb_cnt, uint16 ucb_entries, uma_bucket ucb_bucket) = ucb.unpack();
        return itoa(ucb_cnt) + "    " + itoa(ucb_entries) + "   " + print_bucket(ucb_bucket);
    }

    function print_zone_domain(uma_zone_domain udom) internal returns (string) {
        (uint16 uzd_nitems, uma_bucket uzd_cross, uma_bucket[] uzd_buckets) = udom.unpack();
        return format("{}  {}  {}", uzd_nitems, uzd_buckets.length, print_bucket(uzd_cross));
    }

    function print_bucket_contents(uma_bucket bucket) internal returns (string o) {
        for (uint i = 0; i < bucket.ub_cnt; i++)
            o.append(" [" + string(bucket.ub_bucket[i]) + "] ");
    }

    function bucket_zones_print(uma_bucket_zone[] ubzs) internal returns (string o) {
        o = "BZone    Ents MaxSz "+ ZONE_HEADING + "\n";
        for (uma_bucket_zone ubz: ubzs) {
            (bytes8 ubz_name, uint16 ubz_entries, uint16 ubz_maxsize, uma_zone ubz_zone) = ubz.unpack();
            o.append(format("{} {:3}  {:4} ", "" + ubz_name, ubz_entries, ubz_maxsize) + print_zone(ubz_zone));
        }
    }

    function print_cache(uma_cache cache) internal returns (string o) {
	    (uint32 uc_allocs, uint32 uc_frees, uint32 uz_size, uint32 uz_flags, uma_bucket uc_freebucket, uma_bucket uc_allocbucket, uma_bucket uc_crossbucket) = cache.unpack();
        o = "  " + itoa(uc_allocs) + "   " + itoa(uc_frees) + format(" {:3} ", uz_size) + print_flags(uz_flags) + " |  ";
        o.append(print_bucket(uc_freebucket) + "   |  "  + print_bucket(uc_allocbucket) + "   |  " + print_bucket(uc_crossbucket));
    }

    function zones_print(uma_zone[] zones) internal returns (string o) {
        o = ZONE_HEADING + " " + ZONE_DOMAIN_HEADING + "\n";
        for (uma_zone zone: zones)
            o.append(print_zone(zone) + "\n");
    }

    function kegs_print(uma_keg[] kegs) internal returns (string o) {
        o = KEG_HEADING + " " + DOMAIN_HEADING + "\n";
        for (uma_keg keg: kegs)
            o.append(print_keg(keg) + "\n");
    }

    function domains_print(uma_domain[] doms) internal returns (string o) {
        o = DOMAIN_HEADING + "\n";
        uint i = 1;
        for (uma_domain dom: doms)
            o.append(" " + itoa(i++) + ")  " + print_domain(dom) + "\n");
    }

    function slabs_print(uma_slab[] slabs) internal returns (string o) {
        o = "Slab " + SLAB_HEADING + "\n";
        uint i = 1;
        for (uma_slab slab: slabs)
            o.append("  " + itoa(i++) + ") " + print_slab(slab) + "\n");
    }

    function buckets_print(uma_bucket[] buckets) internal returns (string o) {
        o = "Buck " + BUCKET_HEADING + "\n";
        uint i = 1;
        for (uma_bucket bucket: buckets)
            o.append("  " + itoa(i++) + ")  " + print_bucket(bucket) + "\n");
    }

    function caches_print(uma_cache[] caches) internal returns (string o) {
        o = CACHE_HEADING + "\n";
        for (uma_cache cache: caches)
            o.append(print_cache(cache) + "\n");
    }

}