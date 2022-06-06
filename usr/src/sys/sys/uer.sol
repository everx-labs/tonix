pragma ton-solidity >= 0.59.0;

import "infini.sol";

library uer {
    uint8 constant ALLOC_SLAB_KEG_NO_DOMAIN = 2;
    uint8 constant PREALLOC_ZONE_KEG_NO_DOMAIN = 3;
    uint8 constant ZONE_ALLOC_LIMIT_EXCEEDED = 5;
    uint8 constant FETCH_BUCKET_ITEM_COUNT_UNDERFLOW = 7;
    uint8 constant FETCH_BUCKET_EMPTY_BUCKET_IN_CACHE = 8;
    uint8 constant CACHE_BUCKET_PUSH_NON_FREE_BUCKET_INDEX = 9;


    uint8 constant SLAB_ALLOC_FAILED = 11;
    uint8 constant SLAB_FETCH_FAILED = 12;
    uint8 constant ITEM_IN_SLAB_ALLOC_FAILED = 13;

    uint8 constant ACCESS_VIOLATION = 42;

    uint8 constant SPACE_NOT_INITIALZED = 36;
    uint8 constant SPACE_FULL = 37;
    uint8 constant NO_FREE_SLABS_IN_KEG = 38;

    uint8 constant INDEX_OUT_OF_RANGE = 50;

    uint8 constant ZERO_SIZED_ZONE = 60;

    uint8 constant ARG_SIZE_MISMATCH = 70;
    uint8 constant ARG_SIZE_TOO_SMALL = 71;

    uint8 constant ZONE_ALLOC = 110;
    uint8 constant ITEM_INIT = 120;

    uint8 constant ZERO_ADDRESS = 1;
    uint8 constant EMPTY_ITEM = 2;
    uint8 constant SIZE_MISMATCH = 3;
    uint8 constant SIZE_TOO_SMALL = 4;

    function error_code_to_string(uint8 n) internal returns (string s) {
        if (n > 100) {
            uint8 k = n % 10;
            n -= k;
            if (n == ZONE_ALLOC)
                s = "zone alloc failed: ";
            else if (n == ITEM_INIT)
                s = "item init failed: ";
            if (k == EMPTY_ITEM) s.append("empty item");
            if (k == ZERO_ADDRESS) s.append("zero address");
            if (k == SIZE_MISMATCH) s.append("argument size mismatch");
            if (k == SIZE_TOO_SMALL) s.append("argument size is too small");
            return s;
        }
        if (n == ALLOC_SLAB_KEG_NO_DOMAIN) return "allocating empty slab from keg not attached to a domain";
        if (n == PREALLOC_ZONE_KEG_NO_DOMAIN) return "prealloc keg no domain";
        if (n == ZONE_ALLOC_LIMIT_EXCEEDED) return "limit exceeded";
        if (n == FETCH_BUCKET_ITEM_COUNT_UNDERFLOW) return "item count underflow";
        if (n == FETCH_BUCKET_EMPTY_BUCKET_IN_CACHE) return "empty bucket in bucket cache";
        if (n == CACHE_BUCKET_PUSH_NON_FREE_BUCKET_INDEX) return "freeing to non free bucket index";
        if (n == SPACE_NOT_INITIALZED) return "space is not initialized";
        if (n == SPACE_FULL) return "space is full";
        if (n == ACCESS_VIOLATION) return "access violation";
        if (n == NO_FREE_SLABS_IN_KEG) return "no free slabs in the keg";
        if (n == INDEX_OUT_OF_RANGE) return "index is out of range";
        if (n == ZERO_SIZED_ZONE) return "zero sized zone";
        if (n == SLAB_ALLOC_FAILED) return "failed to allocate slab";
        if (n == SLAB_FETCH_FAILED) return "failed to fetch slab";
        if (n == ITEM_IN_SLAB_ALLOC_FAILED) return "failed to allocate item in slab";
        if (n == ARG_SIZE_MISMATCH) return "argument size mismatch";
        if (n == ARG_SIZE_TOO_SMALL) return "argument size is too small";
        return "Unknown error: " + infini.itoa(n);
    }

}