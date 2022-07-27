pragma ton-solidity >= 0.62.0;

import "filedesc_h.sol";
import "proc_h.sol";
library libio {

    uint16 constant SYS_read    = 3;
    uint16 constant SYS_write   = 4;
    uint16 constant SYS_readv   = 120;
    uint16 constant SYS_writev  = 121;
    uint16 constant SYS_preadv  = 289;
    uint16 constant SYS_pwritev = 290;
    uint16 constant SYS_pread   = 475;
    uint16 constant SYS_pwrite  = 476;
    uint16 constant SYS_copy_file_range = 569;

    using libio for s_thread;
    function syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS_read || n == SYS_readv || n == SYS_write || n == SYS_writev) return 3;
        if (n == SYS_pread || n == SYS_preadv || n == SYS_pwrite || n == SYS_pwritev) return 4;
        if (n == SYS_copy_file_range) return 6;
    }

    function syscall_ids() internal returns (uint16[]) {
        return [SYS_read, SYS_write, SYS_readv, SYS_writev, SYS_preadv, SYS_pwritev, SYS_pread, SYS_pwrite, SYS_copy_file_range];
    }

    function syscall_name(uint16 number) internal returns (string) {
        mapping (uint16 => string) d;
        d[SYS_read] = "read";
        d[SYS_write] = "write";
        d[SYS_readv] = "readv";
        d[SYS_writev] = "writev";
        d[SYS_preadv] = "preadv";
        d[SYS_pwritev] = "pwritev";
        d[SYS_pread] = "pread";
        d[SYS_pwrite] = "pwrite";
        d[SYS_copy_file_range] = "copy_file_range";
        return d[number];
    }
    function do_syscall(s_thread td, uint16 number, string[] args) internal returns (uint8 ec) {
        uint16 rv;
//        s_of[] fdt;
//        s_dirent[] dirents;
        s_of[] fdt_in = td.td_proc.p_fd.fdt_ofiles;
//        uint len = fdt.length;
        uint n_args = args.length;
        string sarg1 = n_args > 0 ? args[0] : "";
//        string sarg2 = n_args > 1 ? args[1] : "";
        uint16 arg1 = n_args > 0 ? str.toi(sarg1) : 0;
//        uint16 arg2 = n_args > 1 ? str.toi(sarg2) : 0;
        s_of f;
        (ec, f) = libfdt.fdopen(fdt_in, arg1);
//        s_sbuf b = f.buf;
        if (number == SYS_read) {


        } else if (number == SYS_write) {

        } else
            ec = err.ENOSYS;
        td.td_errno = ec;
        td.td_retval = rv;
    }
}

