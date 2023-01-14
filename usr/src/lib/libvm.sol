pragma ton-solidity >= 0.64.0;

struct s_vmp {
    string[] pages;
}
library libvm {

    function PHYS_TO_VM_PAGE(string[] pages, uint32 pa) internal returns (string) {
        uint pn = pa >> 16;
        if (pn < pages.length)
            return pages[pn];
    }
}