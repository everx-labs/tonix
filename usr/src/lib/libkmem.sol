pragma ton-solidity >= 0.64.0;

import "malloc_h.sol";
import "libbitset.sol";
import "libstring.sol";

library libkmem {
    using libbitset for uint32;
    function palloc(alloc_type t, uint32 size) internal returns (uint8) {
        uint8 idx = t.next_free;
        if (t.set.BIT_ISSET(idx))
            return 2;
        t.set.BIT_SET(idx);
        t.len++;
        t.size += size;
        t.next_free++;
    }
//    function pfree(alloc_type t, uint32 addr) internal {
//        uint8 idx = uint8(addr & 0xFF);
    function pfree(alloc_type t, uint8 idx) internal {
        if (t.set.BIT_ISSET(idx)) {
            t.set.BIT_CLR(idx);
            t.len--;
//            t.size -= size; ???
        }
    }
    function alloc_as_row(alloc_type t) internal returns (string[]) {
        (bytes12 name, uint8 tag, uint8 len, uint8 next_free, uint32 size, uint32 set) = t.unpack();
        return [libstring.null_term(bytes(name)), str.toa(tag), str.toa(len), str.toa(next_free), str.toa(size), libbitset.toa(set)];
    }
    function page_as_row(vm_page p) internal returns (string[]) {
        (bytes12 name, uint8 len, uint32 size, string[] data) = p.unpack();
        return [libstring.null_term(bytes(name)), str.toa(len), str.toa(size), libstring.join_fields(data, ", ")];
    }
}