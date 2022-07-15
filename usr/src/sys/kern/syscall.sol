pragma ton-solidity >= 0.62.0;

struct syscall_args {
	uint16 code;
	uint16 original_code;
	s_sysent callp;
	uint16[8] args;
}

/*struct s_sysent {			// system call table
//	sy_call_t *sy_call;	/ implementing function
	uint8 sy_narg;	// number of arguments
	uint8 sy_flags;	// General flags for system calls.
}*/

import "libshellenv.sol";
import "libkernprot.sol";

contract syscall {

    uint16 constant SYS_getpid      = 20;
    uint16 constant SYS_setuid      = 23;
    uint16 constant SYS_getuid      = 24;
    uint16 constant SYS_geteuid     = 25;
    uint16 constant SYS_getppid     = 39;
    uint16 constant SYS_getegid     = 43;
    uint16 constant SYS_getgid      = 47;

    uint16 constant SYS_getgroups   = 79;
    uint16 constant SYS_setgroups   = 80;
    uint16 constant SYS_getpgrp     = 81;
    uint16 constant SYS_setpgid     = 82;
    uint16 constant SYS_setreuid    = 126;
    uint16 constant SYS_setregid    = 127;
    uint16 constant SYS_setsid      = 147;
    uint16 constant SYS_setgid      = 181;
    uint16 constant SYS_setegid     = 182;
    uint16 constant SYS_seteuid     = 183;

    uint16 constant SYS_setresuid   = 311;
    uint16 constant SYS_setresgid   = 312;
    uint16 constant SYS_getresuid   = 360;
    uint16 constant SYS_getresgid   = 361;

    using libkernprot for s_thread;

    function main(shell_env e_in, s_proc p_in) external pure returns (shell_env e, s_proc p) {
        e = e_in;
        p = p_in;
    }

    function do_syscall_0(s_thread td, uint16 id) internal pure {
        uint8 ec;
        if (id == SYS_getpid) {
            ec = td.sys_getpid();
        } else if (id == SYS_getuid) {
            ec = td.sys_getuid();
        } else if (id == SYS_geteuid) {
            ec = td.sys_geteuid();
        } else if (id == SYS_getppid) {
            ec = td.sys_getppid();
        } else if (id == SYS_getegid) {
            ec = td.sys_getegid();
        } else if (id == SYS_getgid) {
            ec = td.sys_getgid();
        } else if (id == SYS_getpgrp) {
            ec = td.sys_getpgrp();
        } else if (id == SYS_setsid) {
            ec = td.sys_setsid();
        }
    }

    function do_syscall_1(s_thread td, uint16 id, uint16 arg) internal pure {
        uint8 ec;
        if (id == SYS_setuid) {
            ec = td.sys_setuid(arg);
        } else if (id == SYS_setgid) {
            ec = td.sys_setgid(arg);
        } else if (id == SYS_setegid) {
            ec = td.sys_setegid(arg);
        } else if (id == SYS_seteuid) {
            ec = td.sys_seteuid(arg);
        }
    }

    function do_syscall_2(s_thread td, uint16 id, uint16 arg1, uint16 arg2) internal pure {
        uint8 ec;
        if (id == SYS_setpgid) {
            ec = td.sys_setpgid(arg1, arg2);
        } else if (id == SYS_setreuid) {
            ec = td.sys_setreuid(arg1, arg2);
        } else if (id == SYS_setregid) {
            ec = td.sys_setregid(arg1, arg2);
        }
    }
}