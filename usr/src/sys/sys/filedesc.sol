pragma ton-solidity >= 0.58.0;

import "ktypes.sol";

library filedesc {

    // Per-process open flags.
    uint8 constant UF_EXCLOSE = 0x01; // auto-close on exec

    // Operation types for kern_dup()
    enum {
        FDDUP_NORMAL,           // dup() behavior
        FDDUP_FCNTL,            // fcntl()-style errors
        FDDUP_FIXED,            // Force fixed allocation
        FDDUP_MUSTREPLACE,      // Target must exist
        FDDUP_LASTMODE
    }

    function falloc(s_lwp l, s_file resultfp, uint16 resultfd) internal returns (uint16 retval) {}
    function fd_getfile(s_filedesc fdp, uint16 fd) internal returns (s_file, uint16 retval) {}
    function dupfdopen(s_lwp l, uint16 indx, uint16 dfd, uint16 mode, uint16 error) internal returns (uint16 retval) {}
    function fdalloc(s_proc p, uint16 want) internal returns (uint16 result) {}
    function fdcheckstd(s_lwp l) internal returns (uint16 retval) {}
    function fdclear(s_lwp l) internal returns (uint16 retval) {}
    function fdclone(s_lwp l, s_file fp, uint16 fd, uint16 flag, bytes data)  internal returns (uint16 retval) {}
    function fdcloseexec(s_lwp l)  internal returns (uint16 retval) {}
    function fdcopy(s_proc p)  internal returns (s_filedesc) {}
    function fdexpand(s_proc p)  internal returns (uint16 retval) {}
    function fdfree(s_lwp l) internal {}
    function fdinit(s_proc p) internal returns (s_filedesc) {}
    function fdrelease(s_lwp l, uint16 fd) internal returns (uint16 retval) {}
    function fdremove(s_filedesc fdp, uint16 fd) internal returns (uint16 retval) {}
    function fdshare(s_proc p1, s_proc p2) internal returns (uint16 retval) {}
    function fdunshare(s_lwp l) internal returns (uint16 retval) {}

}