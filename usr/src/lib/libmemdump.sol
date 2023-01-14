pragma ton-solidity >= 0.64.0;

import "malloc_h.sol";
import "libtable.sol";
import "libkmem.sol";
library libmemdump {
    using libtable for s_table;

    function alloc_type_as_row(s_malloc_type t) internal returns (string[]) {
        (uint8 mti_zone, uint8 ks_next, uint8 ks_version, string ks_shortdesc, string mth_name) = t.unpack();
        return [str.toa(mti_zone), str.toa(ks_next), str.toa(ks_version), ks_shortdesc, mth_name];
    }

    function alloc_stats_as_row(s_malloc_type_stats t) internal returns (string[]) {
        (uint32 mts_memalloced, uint32 mts_memfreed, uint32 mts_numallocs, uint32 mts_numfrees, uint32 mts_size) = t.unpack();
        return [str.toa(mts_memalloced), str.toa(mts_memfreed), str.toa(mts_numallocs), str.toa(mts_numfrees), str.toa(mts_size)];
    }

    function print_alloc_types(s_malloc_type[] tt) internal returns (string out) {
        if (tt.empty())
            return "No allocation types";
        string[][] rows = [["zone", "next", "ver", "short", "description"]];
        for (s_malloc_type t: tt)
            rows.push(alloc_type_as_row(t));
        return libtable.table_view([uint(4), 4, 3, 16, 32], libtable.RIGHT, rows);
    }
    function print_alloc_stats(s_malloc_type_stats[] tt) internal returns (string out) {
        if (tt.empty())
            return "No allocation stats";
        string[][] rows = [["malloced", "mfreed", "allocs", "frees", "size"]];
        for (s_malloc_type_stats t: tt)
            rows.push(alloc_stats_as_row(t));
        return libtable.table_view([uint(8), 8, 5, 5, 9], libtable.CENTER, rows);
    }

    function print_alloc_table(alloc_type[] tt) internal returns (string out) {
        if (tt.empty())
            return "No allocation types";
        string[][] rows = [["name", "tag", "len", "next", "size", "set"]];
        for (alloc_type at: tt)
            rows.push(libkmem.alloc_as_row(at));
        return libtable.table_view([uint(12), 4, 4, 5, 7, 32], libtable.CENTER, rows);
    }

    function print_page_table(vm_page[] pp) internal returns (string out) {
        if (pp.empty())
            return "No VM pages";
        string[][] rows = [["name", "len", "size", "data"]];
        for (vm_page p: pp)
            rows.push(libkmem.page_as_row(p));
        return libtable.table_view([uint(12), 4, 5, 70], libtable.CENTER, rows);
    }
}