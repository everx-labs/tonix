pragma ton-solidity >= 0.60.0;

import "../../include/Utility.sol";
//import "sys/vn.sol";
import "../sys/uma.sol";

contract umm is Utility {

//    using uma_slab for s_uma_slab;
//    using libsvm for svm;

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        uma_zone[] uz = sv.sz;
        string[] params = p.params();
        string op;
        uint len = params.length;
        uint vlen = uz.length;
        uma_zone zz;
        if (params.empty()) {
            p.puts("1: initialize zones\n2: allocate argument in the zone\n3: reserve items in zone\n4: create new zone\n6: print kegs\n7: print domains");
        } else {
            op = params[0];
        }
        if (vlen > 0)
            zz = uz[0];
        uma_zone z;
        string name = len > 1 ? params[1] : "";
        uint16 size;
//        bytes bb = bytes(name);
        uint16 nitems = 3;

        if (op == "1") {
            p.puts("Initializing zones zone");
            uma_zone[] uz2;
//            uz2.uma_startup1();
            uint vlen2 = uz2.length;
            for (uint i = 0; i < vlen2; i++) {
                p.puts("<<<");
                //p.puts(uz[i].uma_zone_print());
//                p.puts(uz[i].uz_keg.keg_print());
                p.puts(">>>");
//                p.puts(uz2[i].uma_zone_print());
//                p.puts(uz2[i].uz_keg.keg_print());
            }
        } else if (op == "01") {
            p.puts("startup 01");
//            sv.svm_startup0();
//            p.puts(sv.print_zones());
//            p.puts(sv.print_all());
        } else if (op == "02") {
            p.puts("startup 02");
//            sv.svm_startup1();
        } else if (op == "03") {
            p.puts("startup 03");
//            sv.svm_startup2();
        } else if (op == "2") {
            p.puts("Allocating argument in zone");
//             z.uma_zalloc_arg(bb);
        } else if (op == "3") {
            p.puts("Reserving items in zone");
//            zz.uma_zone_reserve(nitems);
            uz[0] = zz;
        } else if (op == "4") {
            p.puts("Creating new zone");
            size = len > 2 ? str.toi(params[2]) : nitems;
//            z = sv.uma_zcreate(name, size, 1, 1, 1);
        } else if (op == "5") {
            p.puts("Updating initial allocationa");
//            for (s_uma_zone vz: uz)
//                zz.zone_alloc_zone(vz);
//            uz[0] = zz;
        } else if (op == "6") {
            p.puts("Kegs: ");
            for (uma_zone vz: uz) {
                uma_keg k = vz.uz_keg;
//                p.puts(k.keg_print());
            }
            p.puts("======");
            uma_zone zk = uz[1];
            uma_keg kk = zk.uz_keg;
            uma_slab slab;// = kk.uk_slab[0];
            bytes[] data;// = slab.data(kk.uk_size);
            for (bytes b: data)
                p.puts(string(b) + "\n");
            p.puts("======");
//            p.puts(sv.print_kegs());
//            p.puts(zk.uma_zone_print());
        } else if (op == "7") {
            p.puts("Domains: ");
            /*for (s_uma_zone vz: uz) {
                s_uma_domain[] dd = vz.uz_keg.uk_domain;
                for (s_uma_domain d: dd)
                    p.puts(uma_keg.uma_domain_print(d));
            }*/
        } else if (op == "8") {
            p.puts("Zones: ");
//            for (s_uma_zone vz: uz) {
//                p.puts(vz.uma_zone_print());
//            }
            p.puts("======");
//            nitems = zz.uma_zone_get_cur();
//            s_uma_keg k = zz.uz_keg;
  //          uint16 koff = k.uk_offset;
//            uint16 rs = k.uk_rsize;
//            uint32 bbas = uint32(koff) << 16;
//            bytes b0 = k.at(bbas);
//              p.puts(string(b0));
            /*for (s_uma_zone vz: uz) {
                s_uma_domain[] dd = vz.uz_keg.uk_domain;
                for (s_uma_domain d: dd)
                    p.puts(uma_keg.uma_domain_print(d));
            }*/
        }/* else if (op == "9") {
            p.puts("Updating initial kegs allocation");
            s_uma_zone zk = uz[1];
            for (s_uma_zone vz: uz)
                zk.zone_alloc_keg(vz);
            uz[1] = zk;
        }*/
//        p.puts(format("Done op: {} ec: {} ind: {}", op, e, ii));
        uz.push(z);
        if (op != "01" && op != "02" && op != "03") {
            sv.sz = uz;
        }
        sv.cur_proc = p;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"umm",
"OPTION...",
"unified memory manager",
"uma zones",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}