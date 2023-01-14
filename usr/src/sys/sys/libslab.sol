pragma ton-solidity >= 0.59.0;

import "uma_int.sol";
import "uer.sol";

library libcellslab {
/*struct uma_cell_slab {
    uint16 ucs_link;      // slabs in zone
    uint16 ucs_freecount; // How many are free?
    uint8 ucs_flags;      // Page flags
    uint8 ucs_domain;     // Backing NUMA domain.
    uint16 ucs_free;      // Free bitmask, flexible.
    TvmCell ucs_data;
}*/


}
library libslab {

    uint8 constant UMA_SLAB_HEADER_SIZEOF = 8;

    uint8 constant SLAB_MAX_SETSIZE = 255;

    uint8 constant UMA_SLAB_BOOT   = 0x01; // Slab alloced from boot pages
    uint8 constant UMA_SLAB_KERNEL = 0x04; // Slab alloced from kmem
    uint8 constant UMA_SLAB_PRIV   = 0x08; // Slab alloced from priv allocator

    using libslab for uma_slab;

    function ctor(uint16 size, bytes udata, uint32 flags) internal returns (uint8 ec, uma_slab slab) {
//        TvmSlice s = udata.toSlice();
        uint16 ipers = uma.UMA_SLAB_SIZE / size;
//        (uint16 us_link, uint16 ipers, uint8 us_flags, uint8 us_domain, bytes us_data) = s.decode(uint16, uint16, uint8, uint8, bytes);
        slab = uma_slab(0, ipers - 1, uint8(flags & 0xFF), uma.UMA_ANYDOMAIN, 1, udata);
        ec = 0;
    }

    function data(uma_slab slab, uma_keg keg) internal returns (bytes[] bb) {
    	if ((keg.uk_flags & uma.UMA_ZFLAG_OFFPAGE) == 0) {
            bytes sdata = slab.us_data;
            uint16 size = keg.uk_size;
            uint pos = size;
//            while (pos + size < sdata.length) {
            while (pos + size <= sdata.length) {
                bb.push(sdata[pos : pos + size]);
                pos += size;
            }
        }
    }

    /*function data(uma_slab slab, uma_keg keg) internal returns (TvmBuilder[] bb) {
        bytes sdata = slab.us_data;
        uint16 size = keg.uk_size;
        uint pos = size;
        uint ipc = 127 / size;
        TvmBuilder b;
        for (uint i = 0; i < ipc; i++) {
            b.store(uintsdata[pos : pos + size])
        while (pos + size <= sdata.length) {
                bb.push();
                pos += size;
            }
    }*/

    function is_zeroed(uma_slab slab) internal returns (bool) {
        (uint16 us_link, uint16 us_freecount, uint8 us_flags, uint8 us_domain, uint16 us_free, ) = slab.unpack();
        return us_link + us_freecount + us_flags + us_domain + us_free == 0;
    }

    function item(uma_slab slab, uma_keg keg, uint16 index) internal returns (bytes) {
        uint16 sz = keg.uk_size;
        uint16 from = sz * index;
        uint16 to = from + sz;
        if (to <= slab.us_data.length)
            return slab.us_data[from : to];
    }

    function def_item(uma_slab slab, uma_keg keg) internal returns (bytes) {
        if (slab.us_data.length >= keg.uk_size)
            return slab.us_data[ : keg.uk_size];
    }

    function item_index(uma_slab slab, uma_keg keg, bytes itm) internal returns (uint16) {
    	bytes[] bb = slab.data(keg);
        for (uint i = 0; i < bb.length; i++)
            if (bb[i] == itm)
                return uint16(i + 1);
    }

    function alloc_item(uma_slab slab, uma_keg keg) internal returns (uint16 offset, bytes itm) {
        if (slab.us_free > 0 && slab.us_freecount > 0 && keg.uk_domain.length >= slab.us_domain) {
    	    slab.us_freecount--;
            offset = slab.us_free * keg.uk_size;
            if (keg.uk_reserve == 0)
                slab.us_free++;
            itm = slab.def_item(keg);
        }
    }

    function append(uma_slab slab, bytes bb) internal {
        slab.us_data.append(bb);
    }

    function size_of(uint16 nitems) internal returns (uint16) {
	    return UMA_SLAB_HEADER_SIZEOF + nitems / 8 + 1;
    }

    function tohashslab(uma_slab slab) internal returns (uma_hash_slab) {
//    	return (slab, uma_hash_slab, uhs_slab);
    }

    function build_sector(bytes sdata, uint ipc, uint size) internal returns (TvmBuilder b) {
        uint pos;
        for (uint j = 0; j < ipc; j++) {
            if (size == 14)
                b.storeUnsigned(uint112(bytes14(sdata[pos : pos + size])), uint16(size) * 8);
            pos += size;
        }
    }

    function build_region(bytes sdata, uint slab_sector_size, uint cells_required, uint ipc, uint size) internal returns (vector(TvmBuilder) bb) {
        uint rpos;
        TvmBuilder b;
        for (uint i = 0; i < cells_required; i++) {
            b = build_sector(sdata[rpos : rpos + slab_sector_size], ipc, size);
            bb.push(b);
            delete b;
            rpos += slab_sector_size;
        }
    }

    function build_slab_cell(bytes sdata, uint slab_sector_size, uint cells_required, uint ipc, uint size) internal returns (TvmCell cell) {
        vector(TvmBuilder) bb = build_region(sdata, slab_sector_size, cells_required, ipc, size);
        TvmBuilder b;
        TvmBuilder b0 = bb.pop();
        while(!bb.empty()) {
            b = bb.pop();
            b0.storeRef(b);
            delete b;
        }
        cell = b0.toCell();
    }
    function tocellslab(uma_slab slab, uma_keg keg) internal returns (uma_cell_slab cs) {
        (uint16 us_link, uint16 us_freecount, uint8 us_flags, uint8 us_domain, uint16 us_free, bytes us_data) = slab.unpack();
        uint16 size = keg.uk_size;
        uint pos = size;
        uint ipc = uma.UMA_CELL_SLAB_SIZE / size;
        uint n_items = keg.uk_ipers - us_freecount;
        uint cells_required = n_items / ipc;
//        uint slabs_required = cells_required / 5 + 1;
        vector(TvmBuilder) bb;
        TvmBuilder b;

        for (uint i = 0; i < cells_required; i++) {
            for (uint j = 0; j < ipc; j++) {
                b.store(us_data[pos : pos + size]);
                pos += size;
            }
            bb.push(b);
            delete b;
        }
        TvmBuilder b0;
        while (!bb.empty()) {
            b = bb.pop();
            b0.store(b);
        }
        TvmCell c = b0.toCell();
        cs = uma_cell_slab(us_link, us_freecount, us_flags, us_domain, us_free, c);
    }


    function ipers_hdr(uint16 size, uint16 rsize, uint16 slabsize, bool alloc_hdr) internal returns (uint16 ipers) {
	    uint16 padpi = rsize - size;
	    if (alloc_hdr) {
	    	for (ipers = math.min(SLAB_MAX_SETSIZE, (slabsize + padpi - size_of(1)) / rsize);
	    	    ipers > 0 && ipers * rsize - padpi + size_of(ipers) > slabsize; ipers--)
	    		continue;
	    } else
	    	ipers = math.min((slabsize + padpi) / rsize, SLAB_MAX_SETSIZE);
    }

    function init(uma_slab slab, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_SLAB_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uint64 v = uint64(bytes8(arg));
        slab = uma_slab(uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint8(v >> 24 & 0xFF), uint8(v >> 16 & 0xFF), uint16(v & 0xFFFF), slab.us_data);
        if (size == to)
            return 0;
        from = to;
        if (size > to)
            slab.us_data = arg[from : ];
    }

    function fini(uma_slab slab, uint16 size) internal returns (bytes res) {
        (uint16 us_link, uint16 us_freecount, uint8 us_flags, uint8 us_domain, uint16 us_free, ) = slab.unpack();
        uint64 v = (uint64(us_link) << 48) + (uint64(us_freecount) << 32) + (uint64(us_flags) << 24) + (uint64(us_domain) << 16) + us_free;
        res = "" + bytes8(v);
        if (size > UMA_SLAB_HEADER_SIZEOF)
            res.append(slab.us_data);
    }
}

library libhash {
    uint8 constant UMA_HASH_SIZEOF = 8;

    function init(uma_hash uhash, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
//        uint16 from = 0;
        uint16 to = UMA_HASH_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uint64 v = uint64(bytes8(arg));
        uhash = uma_hash(uint16(v >> 48 & 0xFFFF), uint16(v >> 32 & 0xFFFF), uint32(v & 0xFFFFFFFF));
        if (size == to)
            return 0;
        ///skip
//        from = to;
//        ec = hslab.uhs_slab.init(arg[from : ], libslab.UMA_SLAB_HEADER_SIZEOF);
    }

    function fini(uma_hash uhash, uint16 size) internal returns (bytes res) {
        (uint16 uh_slab_hash, uint16 uh_hashsize, uint32 uh_hashmask) = uhash.unpack();
        uint64 v = (uint64(uh_slab_hash) << 48) + (uint64(uh_hashsize) << 32) + uh_hashmask;
        res = "" + bytes8(v);
        if (size > UMA_HASH_SIZEOF) {
            // skip
        }
    }
}
library libhashslab {

    using libhashslab for uma_hash_slab;
    using libslab for uma_slab;

    uint8 constant UMA_HASH_SLAB_HEADER_SIZEOF = 8;

    function init(uma_hash_slab hslab, bytes arg, uint16 size) internal returns (uint8 ec) {
        if (size != arg.length)
            return uer.SIZE_MISMATCH;
        uint16 from = 0;
        uint16 to = UMA_HASH_SLAB_HEADER_SIZEOF;
        if (size < to)
            return uer.SIZE_TOO_SMALL;
        uint64 v = uint64(bytes8(arg));
        hslab = uma_hash_slab(uint32(v >> 32 & 0xFFFFFFFF), arg[4 : to], hslab.uhs_slab);
        if (size == to)
            return 0;
        from = to;
        ec = hslab.uhs_slab.init(arg[from : ], libslab.UMA_SLAB_HEADER_SIZEOF);
    }

    function fini(uma_hash_slab hslab, uint16 size) internal returns (bytes res) {
	    (uint32 uhs_hlink, bytes uhs_data, ) = hslab.unpack();
        uint64 v = (uint64(uhs_hlink) << 32) + uint32(bytes4(uhs_data));
        res = "" + bytes8(v);
        if (size > UMA_HASH_SLAB_HEADER_SIZEOF)
            res.append(hslab.uhs_slab.fini(size - UMA_HASH_SLAB_HEADER_SIZEOF));
    }
}