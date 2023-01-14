pragma ton-solidity >= 0.58.0;

import "ktypes.sol";

struct s_lwp {
}

library sys_generic {

    function dofileread(s_lwp l, uint16 fd, s_file fp, uint16 nbyte, uint16 offset, uint16 flags) internal returns (bytes buf, uint16 retval) {    }
    function dofilewrite(s_lwp l, uint16 fd, s_file fp, bytes buf, uint16 nbyte, uint16 offset, uint16 flags) internal returns (uint16 retval) {}

    function closef(s_file fp, s_lwp l) internal returns (uint16 retval) {}
    function ffree(s_file fp) internal returns (uint16 retval) {}
    function FILE_IS_USABLE(s_file fp) internal returns (uint16 retval) {}
    function FILE_USE(s_file fp) internal returns (uint16 retval) {}
    function FILE_UNUSE(s_file fp, s_lwp l) internal returns (uint16 retval) {}
    function FILE_SET_MATURE(s_file fp) internal returns (uint16 retval) {}
}