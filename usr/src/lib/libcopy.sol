pragma ton-solidity >= 0.64.0;

library libcopy {
    function copyin(bytes uaddr, bytes kaddr, uint32 len) internal returns (uint8) {

    }
    function copyin_nofault(bytes uaddr, bytes kaddr, uint32 len) internal returns (uint8) {}
    function copyout(bytes kaddr, bytes uaddr, uint32 len) internal returns (uint8) {}
    function copyout_nofault(bytes kaddr, bytes uaddr, uint32 len) internal returns (uint8) {}
    function copystr(bytes kfaddr, bytes kdaddr, uint32 len) internal returns (uint8, uint16 done) {}
    function copyinstr(bytes uaddr, bytes kaddr, uint32 len) internal returns (uint8, uint16 done) {}
    function bcopy(bytes src, uint32 len) internal returns (bytes dst) {
        uint slen = src.length;
        dst = slen > len ? src[0 : len] : src;
    }

}