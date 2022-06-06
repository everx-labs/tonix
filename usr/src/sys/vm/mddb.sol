pragma ton-solidity >= 0.58.2;

import "Utility.sol";
import "uma/uma.sol";
import "uma/uma_int.sol";
import "uma/uma_core.sol";

contract mddb is Utility {
    using uma_core for core;

    function main(svm sv_in) external pure returns (svm sv, core c) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();
        string op;
        if (params.empty()) {
//            p.puts("1: Print all\n2: Print all core\n3: reserve items in zone\n4: create new zone\n6: print kegs\n7: print domains");
        } else {
            op = params[0];
        }
//        p.puts("startup 01");
        c.uma_startup1(0);

        if (op == "1") {
//            p.puts("Printing all def");
//            uma_bucket bu = c.zone_fetch_bucket(uma_core.UMA_ZONE);
            uma_bucket bu = c.zones[0].uz_domain.uzd_cross;
            bytes[] b = bu.ub_bucket;
            if (b.length > 4) {
                uma_zone z = uma_core.zone_init(b[0]);
                p.puts(uma_core.zones_print([z]));
                uma_keg k = uma_core.keg_init(b[1]);
                p.puts(uma_core.kegs_print([k]));
                uma_slab s = uma_core.slab_init(b[2]);
                p.puts(uma_core.slabs_print([s]));
                uma_domain d = uma_core.domain_init(b[3]);
                p.puts(uma_core.domains_print([d]));
                uma_bucket bb = uma_core.bucket_init(b[4]);
                p.puts(uma_core.buckets_print([bb]));
            }
//            p.puts(c.print_all());
        } else if (op == "2") {

        } else if (op == "0") {
            //p.puts("1: Print all def\n2: Print all core\n3: reserve items in zone\n4: create new zone\n5: prealloc\n6: kva reserve\n7: print domains");
        } else if (op == "3") {
            c.uma_zone_reserve(uma_core.ZONES_ZONE, 5);
        } else if (op == "5") {
//            p.puts("prealloc");
            c.uma_prealloc(uma_core.ZONES_ZONE, 4);
        } else if (op == "6") {
//            c.zones[uma_core.ZONES_ZONE].uma_zone_reserve_kva(c, 3);
        } else if (op == "7") {
//            p.puts("UMA zone domain");
            uma_bucket b = c.zones[0].uz_domain.uzd_cross;
            p.puts(uma_core.print_bucket_contents(b));
//            c.zones[uma_core.ZONES_ZONE].uma_zone_reserve_kva(c, 3);
        }
        p.puts(c.print_all_core());
//        p.puts(c.print_logs());
//        p.puts("Error log: " + c.err);
//        sv.sz = c.u_export();
        sv.cur_proc = p;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mddb",
"OPTION...",
"uniform memory allocation debugger",
"helps debugging UMA zones",
"",
"",
"Written by Boris",
"",
"",
"0.02");
    }
}