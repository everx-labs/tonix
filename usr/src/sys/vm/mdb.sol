pragma ton-solidity >= 0.58.2;

import "../../include/Utility.sol";
import "uma/uma.sol";
import "uma/uma_int.sol";
import "uma/uma_core.sol";

contract mdb is Utility {
//contract mdb  {
//    using uma for
    using uma_core for core;
//    function main(svm sv_in) external pure returns (svm sv, core c) {
   function main(svm sv_in) external pure returns (svm sv) {
        core  c;
//        core c;
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();
        string op;
        if (params.empty()) {
//            p.puts("1: Print all\n2: Print all core\n3: reserve items in zone\n4: create new zone\n6: print kegs\n7: print domains");
        } else {
            op = params[0];
        }
        p.puts("startup 01");
        c.uma_startup1(0);

        if (op == "1") {
            p.puts("Printing all");
//            p.puts(c.print_all());
        } else if (op == "2") {
            p.puts("Printing core");
            p.puts(c.print_all_core());
        } else if (op == "0") {
            p.puts("1: Print all\n2: Print all core\n3: reserve items in zone\n4: create new zone\n5: prealloc\n6: kva reserve\n7: print domains");
        } else if (op == "3") {
            p.puts("reserve items in zone");
//            c.zones.uma_zone_reserve(5);
            p.puts(c.print_all_core());
        } else if (op == "5") {
            p.puts("prealloc");
//            c.zones.uma_prealloc(c, 4);
            p.puts(c.print_all_core());
        } else if (op == "6") {
            p.puts("kva reserve");
//            c.zones.uma_zone_reserve_kva(c, 3);
            p.puts(c.print_all_core());
        }
//        p.puts(c.print_logs());
        p.puts("Error log: " + c.err);
        sv.sz = c.u_export();
        sv.cur_proc = p;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mdb",
"OPTION...",
"uniform memory allocation debugger",
"helps debugging UMA zones",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}