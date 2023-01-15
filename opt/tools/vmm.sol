pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "uma.sol";
import "vmem.sol";
contract vmm is Utility {
    using vmem for s_vmem;
    uint16 constant PAGE_SHIFT = 12;              // LOG2(PAGE_SIZE)
    uint16 constant PAGE_SIZE = uint16(1) << PAGE_SHIFT;

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        s_vmem[] vmms = sv.vmem;
        string[] params = p.params();
        uint8 e;
        string op;
        string ind;
        uint16 ii;
        uint len = params.length;
        uint vlen = vmms.length;
        s_vmem v;
        if (params.empty()) {
            p.puts("1: initialize primary vmem\n2: allocate argument in vmem\n3: free item in vmem\n4: create new vmem\n6: print kegs\n7: print domains");
//            for (s_vmem vz: vmms) {
//                p.puts(vz.vm_name);

//            }
        } else {
            op = params[0];
            ind = vlen > 1 ? params[1] : "0";
            ii = ind.toi();
            if (ii < vlen)
                v = vmms[ii];
        }
        string name = len > 1 ? params[1] : "";
        uint16 size;
        uint16 flags;
        bytes bb = bytes(name);
        uint16 nitems = 3;
        uint32 addr;
        size = len > 2 ? str.toi(params[2]) : nitems;

        if (op == "1") {
            p.puts("Initializing primary vmem");
            v = vmem.vmem_create("V0", 0, size, PAGE_SIZE, 0, flags);
        } else if (op == "2") {
            p.puts("Allocating argument in vmem");
            (e, addr) = v.vmem_alloc(size, flags);
            p.puts(format("address: {}", addr));
        } else if (op == "3") {
            p.puts("freeing item in vmem");
            v.vmem_free(addr, size);
        } else if (op == "4") {
            p.puts("Creating new vmem");
            v = vmem.vmem_create(name, 0, size, PAGE_SIZE, 0, flags);
        } else if (op == "5") {
            p.puts("Updating initial allocation");
        } else if (op == "6") {
            p.puts("Pages: ");
            for (s_vmem vz: vmms) {
                bytes[] pp = vz.vm_pages;
                for (bytes b: pp)
                    p.puts(string(b));
            }
        }

        p.puts(format("Done op: {} ec: {} ind: {}", op, e, ii));
        vmms.push(v);
        sv.cur_proc = p;
        sv.vmem = vmms;
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