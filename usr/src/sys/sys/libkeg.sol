pragma ton-solidity >= 0.59.0;

import "uma_int.sol";
import "libslab.sol";
import "libzone.sol";
import "uer.sol";

library libdomain {

    uint8 constant UMA_DOMAIN_HEADER_SIZEOF = 8;
    uint8 constant UMA_SLAB_HEADER_SIZEOF = 8;

    using libslab for uma_slab;
    using libdomain for uma_domain;

    function fini(uma_domain domain, uint16 size) internal returns (bytes res) {
        (uint16 ud_slab, uint16 ud_pages, uint16 ud_free_items, uint16 ud_free_slabs, uma_slab[] slabs) = domain.unpack();
        uint64 v = (uint64(ud_slab) << 48) + (uint64(ud_pages) << 32) + (uint64(ud_free_items) << 16) + ud_free_slabs;
        res = "" + bytes8(v);
        if (size > UMA_DOMAIN_HEADER_SIZEOF)
            for (uma_slab slab: slabs)
                res.append(slab.fini(UMA_SLAB_HEADER_SIZEOF));
    }

    function init(uma_domain domain, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_DOMAIN_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uint64 v = uint64(bytes8(arg));
        (uint16 ud_slab, uint16 ud_pages, uint16 ud_free_items, uint16 ud_free_slabs) = (uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint16(v >> 16 & 0xFFFF), uint16(v & 0xFFFF));
        domain = uma_domain(ud_slab, ud_pages, ud_free_items, ud_free_slabs, domain.slabs);
        if (size == to)
            return 0;

        from = to;
        uma_slab[] slabs;
        uma_slab slab;
        for (uint i = 0; i < domain.ud_pages; i++) {
            from = to;
            to += UMA_SLAB_HEADER_SIZEOF;
            ec = slab.init(arg[from : to], to - from);
            if (ec > 0)
                return ec;
            slabs.push();
        }
        domain.slabs = slabs;
    }
}
library libkeg {

    uint8 constant UMA_KEG_HEADER_SIZEOF = 40;
    uint8 constant UMA_DOMAIN_HEADER_SIZEOF = 8;
//    uint8 constant UMA_KEG_SIZEOF = 48; //UMA_KEG_HEADER_SIZEOF + vm_ndomains * UMA_DOMAIN_HEADER_SIZEOF;
    uint8 constant UMA_KEG_SIZEOF = 56; //UMA_KEG_HEADER_SIZEOF + UMA_HASH_SIZEOF + vm_ndomains * UMA_DOMAIN_HEADER_SIZEOF;

    using libkeg for uma_keg;
    using libslab for uma_slab;
    using libzone for uma_zone;
    using libdomain for uma_domain;
    using libzone for uma_zone;
    using libhash for uma_hash;

    function zero_init(bytes mem, uint16 size) internal returns (bytes) {
        bytes32 z32;
        delete mem;
        string ss;
        ss = ss + string(mem) + z32 + z32;
        if (size < ss.byteLength())
            return bytes(ss.substr(0, size));
    }

    function fetch_slab(uma_keg keg, uint8 domain) internal returns (uint16 idx, uma_slab slab) {
        if (domain < keg.uk_domain.length)
            idx = keg.uk_domain[domain].ud_pages > 0 ? 1 : keg.alloc_slab(domain);
        if (idx > 0)
            slab = keg.uk_domain[domain].slabs[idx - 1];
    }

    function alloc_slab(uma_keg keg, uint8 domain) internal returns (uint16 slab_id) {
        if (domain >= keg.uk_domain.length)
            return 0;
        bytes def;
        uma_domain dom = keg.uk_domain[domain];
        if (dom.ud_slab > 0 && dom.slabs[0].us_free > 0)
            def = dom.slabs[0].def_item(keg);

//        uma_slab slab = uma_slab(keg.uk_zones, keg.uk_ipers - 1, 0, domain, 1, def);
        (uint8 ec, uma_slab slab) = libslab.ctor(keg.uk_size, def, 0);
        if (ec > 0)
            return 0;
        slab.us_link = keg.uk_zones;
        slab_id = dom.ud_pages++;
        dom.ud_free_slabs++;
        dom.ud_free_items += keg.uk_ipers - 1;
        dom.slabs.push(slab);
        keg.uk_domain[domain] = dom;
    }

//        slab_id = keg.page_alloc(0, domain);
//        keg.uk_pgoff = slab_id;
//        keg.uk_domain[domain].ud_slab = slab_id;


    function fetch_free_slab(uma_keg keg, uint8 domain, uint32 flags) internal returns (uma_slab slab) {
    	uint16 reserve = (flags & libmalloc.M_USE_RESERVE) > 0 ? 0 : keg.uk_reserve;
    	if (keg.uk_domain[domain].ud_free_items > reserve)
            slab = keg.first_slab(domain);
    }

    function first_slab(uma_keg keg, uint8 domain) internal returns (uma_slab slab) {
        if (domain < keg.uk_domain.length) {
            uma_domain d = keg.uk_domain[domain];
            if (d.ud_pages > 0) {
                uint16 i;
                if (d.ud_slab > 0)
                    return d.slabs[d.ud_slab - 1];
                for (uma_slab sl: d.slabs) {
                    i++;
                    if (sl.us_freecount > 0 && sl.us_free > 0) {
                        keg.uk_pgoff = i;
                        keg.uk_domain[domain].ud_slab = i;
                        return sl;
                    }
                }
            }
        }
    }

    function _slab(uma_keg keg, uint16 id) internal returns (uma_slab) {
        uint8 domain = keg.uk_kva > 0 ? uint8(keg.uk_kva - 1) : 0;
        if (id > 0 && id <= keg.uk_domain[domain].ud_pages)
            return keg.uk_domain[domain].slabs[id - 1];
    }
    function page_alloc(uma_keg keg, uint16 nbytes, uint8 domain) internal returns (uint16) {
        if (domain >= keg.uk_domain.length)
            return 0;
        uma_domain d = keg.uk_domain[domain];
        uma_slab slab;
        slab.us_freecount = keg.uk_ipers;
        slab.us_free = 1;
        slab.us_link = keg.uk_zones;
        slab.us_domain = domain;
        uint16 pages = nbytes / uma.PAGE_SIZE + 1;
        d.ud_pages += pages;
//        d.ud_slab++;
        d.ud_free_slabs++;
        d.ud_free_items += pages * slab.us_freecount;
        repeat (pages)
            d.slabs.push(slab);
        keg.uk_domain[domain] = d;
        return d.ud_pages;
    }

    function item_init(uma_keg keg, bytes item, uint16 size) internal returns (bytes res) {
        uint16 ki = keg.uk_init;
        if (ki == uma.ZONE_INIT) {
            uma_zone z;
            z.init(item, size);
            res = z.fini(size);
        } else if (ki == uma.KEG_INIT) {
            uma_keg k;
            k.init(item, size);
            res = k.fini(size);
        } else if (ki == uma.ZERO_INIT)
            res = zero_init(item, uint16(item.length));
        else
            res = item;
    }

struct keg_layout_result {
	uint32 format;
	uint16 slabsize;
	uint16 ipers;
	uint16 eff;
}

    function layout_one(uma_keg keg, uint16 rsize, uint16 slabsize, uint32 fmt) internal returns (keg_layout_result kl) {
	    kl.format = fmt;
	    kl.slabsize = slabsize;

	    /* Handle INTERNAL as inline with an extra page. */
	    if ((fmt & uma.UMA_ZFLAG_INTERNAL) > 0) {
	    	kl.format &= ~uma.UMA_ZFLAG_INTERNAL;
	    	kl.slabsize += uma.PAGE_SIZE;
	    }
	    kl.ipers = libslab.ipers_hdr(keg.uk_size, rsize, kl.slabsize, (fmt & uma.UMA_ZFLAG_OFFPAGE) == 0);

	    /* Account for memory used by an offpage slab header. */
	    uint16 total = kl.slabsize;
	    if ((fmt & uma.UMA_ZFLAG_OFFPAGE) > 0)
	    	total += kl.ipers > uma.SLABZONE0_SETSIZE ? uma.SLABZONE1_SIZE : uma.SLABZONE0_SIZE;
    	kl.eff = kl.ipers * rsize / total;
    }

    function layout(uma_keg keg) internal {
        keg_layout_result kl;
        keg_layout_result kl_tmp;
	    uint32[2] fmts;
	    uint16 nfmt;
	    uint16 slabsize;

//	    KASSERT((keg.uk_flags & (UMA_ZFLAG_INTERNAL | UMA_ZONE_VM)) == 0 || (keg.uk_flags & (UMA_ZONE_NOTOUCH | UMA_ZONE_PCPU)) == 0, ("%s: incompatible flags 0x%b", __func__, keg.uk_flags, PRINT_UMA_ZFLAGS));
    	uint16 alignsize = keg.uk_align + 1;
	    uint16 rsize = math.max(keg.uk_size, uma.UMA_SMALLEST_UNIT);

	    if ((keg.uk_flags & libzone.UMA_ZONE_CACHESPREAD) > 0) {
	    	if ((rsize & alignsize) == 0)
	    		rsize += alignsize;
	    	slabsize = rsize * (uma.PAGE_SIZE / alignsize);
	    	slabsize = math.min(slabsize, rsize * libslab.SLAB_MAX_SETSIZE);
	    	slabsize = math.min(slabsize, uma.UMA_CACHESPREAD_MAX_SIZE);
	    } else
	    	slabsize = keg.uk_size;

	    if ((keg.uk_flags & (libzone.UMA_ZONE_NOTOUCH | libzone.UMA_ZONE_PCPU)) == 0)
	    	fmts[nfmt++] = 0;
	    if ((keg.uk_flags & (uma.UMA_ZFLAG_INTERNAL | libzone.UMA_ZONE_VM)) > 0)
	    	fmts[nfmt++] = uma.UMA_ZFLAG_INTERNAL;
	    else
	    	fmts[nfmt++] = uma.UMA_ZFLAG_OFFPAGE;

	    uint16 i = (slabsize + rsize - keg.uk_size) / math.max(uma.PAGE_SIZE, rsize);
//	    KASSERT(i >= 1, ("keg %s(%p) flags=0x%b slabsize=%u, rsize=%u, i=%u", keg.uk_name, keg, keg.uk_flags, PRINT_UMA_ZFLAGS, slabsize, rsize, i));
	    for ( ; ; i++) {
	    	slabsize = (rsize <= uma.PAGE_SIZE) ? i : (rsize * (i - 1) + keg.uk_size);

    		for (uint16 j = 0; j < nfmt; j++) {
    			if ((fmts[j] & uma.UMA_ZFLAG_INTERNAL) > 0 && kl.ipers > 0)
    				continue;
    			kl_tmp = keg.layout_one(rsize, slabsize, fmts[j]);
    			if (kl_tmp.eff <= kl.eff)
    				continue;
    			kl = kl_tmp;
    			if (kl.eff >= uma.UMA_MIN_EFF)
    				break;
    		}
    		if (kl.eff >= uma.UMA_MIN_EFF || slabsize >= libslab.SLAB_MAX_SETSIZE * rsize || (keg.uk_flags & (libzone.UMA_ZONE_PCPU | libzone.UMA_ZONE_CONTIG)) > 0)
    			break;
	    }

	    uint16 pages = kl.slabsize;
	    keg.uk_rsize = rsize;
	    keg.uk_ipers = kl.ipers;
	    keg.uk_ppera = pages;
	    keg.uk_flags |= kl.format;

	    if ((keg.uk_flags & uma.UMA_ZFLAG_OFFPAGE) > 0 || (keg.uk_ipers - 1) * rsize >= uma.PAGE_SIZE) {
	    	if ((keg.uk_flags & libzone.UMA_ZONE_NOTPAGE) > 0)
	    		keg.uk_flags |= uma.UMA_ZFLAG_HASH;
	    	else
	    		keg.uk_flags |= uma.UMA_ZFLAG_VTOSLAB;
	    }
//    	KASSERT(keg.uk_ipers > 0 && keg.uk_ipers <= SLAB_MAX_SETSIZE, ("%s: keg=%s, flags=0x%b, rsize=%u, ipers=%u, ppera=%u", __func__, keg.uk_name, keg.uk_flags, PRINT_UMA_ZFLAGS, rsize, keg.uk_ipers, pages));
    }

    function init(uma_keg keg, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_KEG_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;

        uint v = uint(bytes32(arg));
        keg = uma_keg(uint16(v >> 240 & 0xFFFF), uint16(v >> 224 & 0xFFFF), uint16(v >> 208 & 0xFFFF), uint16(v >> 192 & 0xFFFF), uint16(v >> 176 & 0xFFFF),
            uint16(v >> 160 & 0xFFFF), uint16(v >> 144 & 0xFFFF), uint16(v >> 128 & 0xFFFF), uint16(v >> 112 & 0xFFFF), uint16(v >> 96 & 0xFFFF), uint16(v >> 80 & 0xFFFF),
            uint16(v >> 64 & 0xFFFF), uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF), bytes8(arg[32 : to]), 0, keg.uk_hash, keg.uk_domain);

        if (size == to)
            return 0;
        from = to;
        to += libhash.UMA_HASH_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uma_hash uhash;
        ec = uhash.init(arg[from : to], to - from);
        if (ec > 0)
            return ec;
        keg.uk_hash = uhash;
        if (size == to)
            return 0;
        repeat (uma.vm_ndomains) {
            uma_domain domain;
            from = to;
            to += UMA_DOMAIN_HEADER_SIZEOF;
            ec = domain.init(arg[from : to], to - from);
            if (ec > 0)
                return ec;
            keg.uk_domain.push(domain);
        }
    }

    function fini(uma_keg keg, uint16 size) internal returns (bytes res) {
        (uint16 uk_zones, uint16 uk_align, uint16 uk_reserve, uint16 uk_size, uint16 uk_rsize, uint16 uk_init, uint16 uk_fini,
            uint16 uk_allocf, uint16 uk_freef, uint16 uk_offset, uint16 uk_kva, uint16 uk_pgoff, uint16 uk_ppera, uint16 uk_ipers,
            uint32 uk_flags, bytes8 uk_name, , uma_hash uhash, uma_domain[] uk_domain) = keg.unpack();
        uint v = (uint(uk_zones) << 240) + (uint(uk_align) << 224) + (uint(uk_reserve) << 208) + (uint(uk_size) << 192) + (uint(uk_rsize) << 176) +
                (uint(uk_init) << 160) + (uint(uk_fini) << 144) + (uint(uk_allocf) << 128) + (uint(uk_freef) << 112) + (uint(uk_offset) << 96) +
                (uint(uk_kva) << 80) + (uint(uk_pgoff) << 64) + (uint(uk_ppera) << 48) + (uint(uk_ipers) << 32) + uk_flags;
        res = "" + bytes32(v) + uk_name;
        if (size > UMA_KEG_HEADER_SIZEOF)
            res.append(uhash.fini(libhash.UMA_HASH_SIZEOF));
        if (size > UMA_KEG_HEADER_SIZEOF + libhash.UMA_HASH_SIZEOF)
            for (uma_domain dom: uk_domain)
                res.append(dom.fini(UMA_DOMAIN_HEADER_SIZEOF));
    }

    function dtor(uma_keg keg, bytes arg, uint16 size, bytes ) internal {
	    uint16 free;
        uint16 pages;

        keg.init(arg, size);
	    for (uint16 i = 0; i < 1; i++) {
	    	free += keg.uk_domain[i].ud_free_items;
	    	pages += keg.uk_domain[i].ud_pages;
	    }
    }

}