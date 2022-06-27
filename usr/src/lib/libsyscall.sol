pragma ton-solidity >= 0.61.2;

import "io.sol";
import "ucred.sol";
import "liberr.sol";
library libsyscall {

    using sucred for s_ucred;

    /*
    uint16 constant SYS_freebsd11_mknod     = 14;
    uint16 constant SYS_freebsd10_pipe      = 42;
    uint16 constant SYS_freebsd11_vadvise   = 72;
    uint16 constant SYS_freebsd11_stat      = 188;
    uint16 constant SYS_freebsd11_fstat     = 189;
    uint16 constant SYS_freebsd11_lstat     = 190;
    uint16 constant SYS_freebsd11_getdirentries = 196;
    uint16 constant SYS_freebsd7___semctl   = 220;
    uint16 constant SYS_freebsd7_msgctl     = 224;
    uint16 constant SYS_freebsd7_shmctl     = 229;
    uint16 constant SYS_freebsd11_getdents  = 272;
    uint16 constant SYS_freebsd11_nstat     = 278;
    uint16 constant SYS_freebsd11_nfstat    = 279;
    uint16 constant SYS_freebsd11_nlstat    = 280;
    uint16 constant SYS_freebsd11_fhstat    = 299;
    uint16 constant SYS_freebsd11_kevent    = 363;
    uint16 constant SYS_freebsd11_getfsstat = 395;
    uint16 constant SYS_freebsd11_statfs    = 396;
    uint16 constant SYS_freebsd11_fstatfs   = 397;
    uint16 constant SYS_freebsd11_fhstatfs  = 398;
    uint16 constant SYS_freebsd12_shm_open = 482;
    uint16 constant SYS_freebsd11_fstatat  = 493;
    uint16 constant SYS_freebsd11_mknodat  = 498;
    uint16 constant SYS_freebsd12_closefrom = 509;
    */

    function _syscall_name(uint16 number) internal returns (string) {
        mapping (uint16 => string) d;
        d[SYS_open] = "open";
        return d[number];
    }

    function _syscall_nargs(uint16 n) internal returns (uint8) {
        if (n == SYS_getuid || n == SYS_geteuid || n == SYS_getgid || n == SYS_getegid)// || n == SYS_getuid || n == SYS_getuid || )
            return 0;
        if (n == SYS_setuid || n == SYS_seteuid || n == SYS_setgid || n == SYS_setegid)// || n == SYS_getuid || n == SYS_getuid || )
            return 1;
    }

    function _syscall_group(uint16 n) internal returns (uint8) {
        if (n == SYS_getuid || n == SYS_geteuid || n == SYS_getgid || n == SYS_getegid)// || n == SYS_getuid || n == SYS_getuid || )
            return 1;
        if (n == SYS_setuid || n == SYS_seteuid || n == SYS_setgid || n == SYS_setegid)// || n == SYS_getuid || n == SYS_getuid || )
            return 2;
    }

    function _ucred_1(s_thread t, uint16 number) internal returns (uint16) {
        uint8 e;
        uint16 rv;
        s_ucred cr = t.td_ucred;
        if (number == SYS_getpid)
            e = 0;
//        else if (number == SYS_setuid)
//            e = cr.setuid()
        else if (number == SYS_getuid)
            rv = cr.getuid();
        else if (number == SYS_geteuid)
            rv = cr.geteuid();
        else if (number == SYS_getgid)
            rv = cr.getgid();
        else if (number == SYS_getegid)
            rv = cr.getegid();
//        else if (number == SYS_getgroups) {

//        }
        return rv;
//        t.td_errno = e;
//        t.tdu_retval[0] = rv;
    }

    function _ucred_2(s_thread t, uint16 number, uint16 id) internal returns (s_ucred) {
        uint8 e;
//        uint16 rv;
        s_ucred cr = t.td_ucred;
        if (number == SYS_setuid)
            e = cr.setuid(id);
        else if (number == SYS_seteuid)
            e = cr.seteuid(id);
        else if (number == SYS_setgid)
            e = cr.setgid(id);
        else if (number == SYS_setegid)
            e = cr.setegid(id);
//        t.tdu_retval[0] = rv;
        if (e == 0)
            return cr;
    }

/*    function _io_1(s_thread t, uint16 number, uint16 id) internal returns (s_uio) {
        uint8 e;
//        if (number == SYS_write)
//            e = io.write();
    }*/
            /*
    function getuid(s_ucred cr) internal returns (uint16) {
        return cr.cr_ruid;
    }
    function geteuid(s_ucred cr) internal returns (uint16) {
        return cr.cr_uid;
    }
    function getgid(s_ucred cr) internal returns (uint16) {
        return cr.cr_rgid;
    }
    function getegid(s_ucred cr) internal returns (uint16) {
        return cr.cr_groups[0];
    }
    function setuid(s_ucred cr, uint16 uid) internal returns (uint16) {

        else if (number == SYS_getpid)
        else if (number == SYS_getpid)
        else if (number == SYS_getpid)
        else if (number == SYS_getpid)
        else if (number == SYS_getpid)
        else */
    /*uint16 constant SYS_getpid              = 20;
    uint16 constant SYS_mount               = 21;
    uint16 constant SYS_unmount             = 22;
    uint16 constant SYS_setuid              = 23;
    uint16 constant SYS_getuid              = 24;
    uint16 constant SYS_geteuid             = 25;
    }*/

    function do_syscall(s_thread td, uint16 number, uint16[] args) internal returns (uint16) {
        uint8 e;
        uint16 rv;
        uint8 scg = _syscall_group(number);
        if (scg == 0)
            e = err.ENOSYS;
        else if (scg == 1) {
            e = 0;
            rv = _ucred_1(td, number);
        } else if (scg == 2) {
            s_ucred nc = _ucred_2(td, number, args[0]);
            td.td_ucred = nc;
        }

        td.td_errno = e;
        td.tdu_retval = rv;
    }

    function syscall(s_proc p, uint16 number) internal returns (uint8) {
        s_ucred td_realucred = p.p_ucred;   // Reference to credentials.
        s_ucred td_ucred = p.p_ucred;       // Used credentials, temporarily switchable.
        s_plimit td_limit = p.p_limit;      // Resource limits.
        string td_name = _syscall_name(number);         // Thread name.
//        s_xfile xfile;
        uint8 td_errno;        // Error from last syscall.
        td_states td_state;     // thread state
        uint32 tdu_retval;

        s_thread t = s_thread(p, 1, 0, 0, td_realucred, td_ucred, td_limit, td_name, td_errno, td_state, tdu_retval);
        if (!td_name.empty())
        return t.td_errno;
    }

    uint16 constant SYS_syscall             = 0;
    uint16 constant SYS_exit                = 1;
    uint16 constant SYS_fork                = 2;
    uint16 constant SYS_read                = 3;
    uint16 constant SYS_write               = 4;
    uint16 constant SYS_open                = 5;
    uint16 constant SYS_close               = 6;
    uint16 constant SYS_wait4               = 7;
    uint16 constant SYS_link                = 9;
    uint16 constant SYS_unlink              = 10;
    uint16 constant SYS_chdir               = 12;
    uint16 constant SYS_fchdir              = 13;
    uint16 constant SYS_chmod               = 15;
    uint16 constant SYS_chown               = 16;
    uint16 constant SYS_break               = 17;
    uint16 constant SYS_getpid              = 20;
    uint16 constant SYS_mount               = 21;
    uint16 constant SYS_unmount             = 22;
    uint16 constant SYS_setuid              = 23;
    uint16 constant SYS_getuid              = 24;
    uint16 constant SYS_geteuid             = 25;
    uint16 constant SYS_ptrace              = 26;
    uint16 constant SYS_recvmsg             = 27;
    uint16 constant SYS_sendmsg             = 28;
    uint16 constant SYS_recvfrom            = 29;
    uint16 constant SYS_accept              = 30;
    uint16 constant SYS_getpeername         = 31;
    uint16 constant SYS_getsockname         = 32;
    uint16 constant SYS_access              = 33;
    uint16 constant SYS_chflags             = 34;
    uint16 constant SYS_fchflags            = 35;
    uint16 constant SYS_sync                = 36;
    uint16 constant SYS_kill                = 37;
    uint16 constant SYS_getppid             = 39;
    uint16 constant SYS_dup                 = 41;
    uint16 constant SYS_getegid             = 43;
    uint16 constant SYS_profil              = 44;
    uint16 constant SYS_ktrace              = 45;
    uint16 constant SYS_getgid              = 47;
    uint16 constant SYS_getlogin            = 49;
    uint16 constant SYS_setlogin            = 50;
    uint16 constant SYS_acct                = 51;
    uint16 constant SYS_ioctl               = 54;
    uint16 constant SYS_reboot              = 55;
    uint16 constant SYS_revoke              = 56;
    uint16 constant SYS_symlink             = 57;
    uint16 constant SYS_readlink            = 58;
    uint16 constant SYS_execve              = 59;
    uint16 constant SYS_umask               = 60;
    uint16 constant SYS_chroot              = 61;
    uint16 constant SYS_msync               = 65;
    uint16 constant SYS_vfork               = 66;
    uint16 constant SYS_sbrk                = 69;
    uint16 constant SYS_sstk                = 70;
    uint16 constant SYS_munmap              = 73;
    uint16 constant SYS_mprotect            = 74;
    uint16 constant SYS_madvise             = 75;
    uint16 constant SYS_mincore             = 78;
    uint16 constant SYS_getgroups           = 79;
    uint16 constant SYS_setgroups           = 80;
    uint16 constant SYS_getpgrp             = 81;
    uint16 constant SYS_setpgid             = 82;
    uint16 constant SYS_setitimer           = 83;
    uint16 constant SYS_swapon              = 85;
    uint16 constant SYS_getitimer           = 86;
    uint16 constant SYS_getdtablesize       = 89;
    uint16 constant SYS_dup2                = 90;
    uint16 constant SYS_fcntl               = 92;
    uint16 constant SYS_select              = 93;
    uint16 constant SYS_fsync               = 95;
    uint16 constant SYS_setpriority         = 96;
    uint16 constant SYS_socket              = 97;
    uint16 constant SYS_connect             = 98;
    uint16 constant SYS_getpriority         = 100;
    uint16 constant SYS_bind                = 104;
    uint16 constant SYS_setsockopt          = 105;
    uint16 constant SYS_listen              = 106;
    uint16 constant SYS_gettimeofday        = 116;
    uint16 constant SYS_getrusage           = 117;
    uint16 constant SYS_getsockopt          = 118;
    uint16 constant SYS_readv               = 120;
    uint16 constant SYS_writev              = 121;
    uint16 constant SYS_settimeofday        = 122;
    uint16 constant SYS_fchown              = 123;
    uint16 constant SYS_fchmod              = 124;
    uint16 constant SYS_setreuid            = 126;
    uint16 constant SYS_setregid            = 127;
    uint16 constant SYS_rename              = 128;
    uint16 constant SYS_flock               = 131;
    uint16 constant SYS_mkfifo              = 132;
    uint16 constant SYS_sendto              = 133;
    uint16 constant SYS_shutdown            = 134;
    uint16 constant SYS_socketpair          = 135;
    uint16 constant SYS_mkdir               = 136;
    uint16 constant SYS_rmdir               = 137;
    uint16 constant SYS_utimes              = 138;
    uint16 constant SYS_adjtime             = 140;
    uint16 constant SYS_setsid              = 147;
    uint16 constant SYS_quotactl            = 148;
    uint16 constant SYS_nlm_syscall         = 154;
    uint16 constant SYS_nfssvc              = 155;
    uint16 constant SYS_sysarch             = 165;
    uint16 constant SYS_rtprio              = 166;
    uint16 constant SYS_semsys              = 169;
    uint16 constant SYS_msgsys              = 170;
    uint16 constant SYS_shmsys              = 171;
    uint16 constant SYS_setfib              = 175;
    uint16 constant SYS_ntp_adjtime         = 176;
    uint16 constant SYS_setgid              = 181;
    uint16 constant SYS_setegid             = 182;
    uint16 constant SYS_seteuid             = 183;
    uint16 constant SYS_pathconf            = 191;
    uint16 constant SYS_fpathconf           = 192;
    uint16 constant SYS_getrlimit           = 194;
    uint16 constant SYS_setrlimit           = 195;
    uint16 constant SYS_mlock               = 203;
    uint16 constant SYS_munlock             = 204;
    uint16 constant SYS_undelete            = 205;
    uint16 constant SYS_futimes             = 206;
    uint16 constant SYS_getpgid             = 207;
    uint16 constant SYS_poll                = 209;
    uint16 constant SYS_semget              = 221;
    uint16 constant SYS_semop               = 222;
    uint16 constant SYS_msgget              = 225;
    uint16 constant SYS_msgsnd              = 226;
    uint16 constant SYS_msgrcv              = 227;
    uint16 constant SYS_minherit            = 250;
    uint16 constant SYS_rfork               = 251;
    uint16 constant SYS_issetugid           = 253;
    uint16 constant SYS_lchown              = 254;
    uint16 constant SYS_lio_listio          = 257;
    uint16 constant SYS_lchmod              = 274;
    uint16 constant SYS_lutimes             = 276;
    uint16 constant SYS_preadv              = 289;
    uint16 constant SYS_pwritev             = 290;
    uint16 constant SYS_getsid              = 310;
    uint16 constant SYS_setresuid           = 311;
    uint16 constant SYS_setresgid           = 312;
    uint16 constant SYS_yield               = 321;
    uint16 constant SYS_mlockall            = 324;
    uint16 constant SYS_munlockall          = 325;
    uint16 constant SYS_utrace              = 335;
    uint16 constant SYS_nnpfs_syscall       = 339;
    uint16 constant SYS_getresuid           = 360;
    uint16 constant SYS_getresgid           = 361;
    uint16 constant SYS_kqueue              = 362;
    uint16 constant SYS_eaccess             = 376;
    uint16 constant SYS_afs3_syscall        = 377;
    uint16 constant SYS_nmount              = 378;

    uint16 constant SYS___syscall           = 198;
    uint16 constant SYS___sysctl            = 202;
    uint16 constant SYS___getcwd            = 326;
    uint16 constant SYS___setugid           = 374;
    uint16 constant SYS___semctl            = 510;
    uint16 constant SYS___cap_rights_get    = 515;
    uint16 constant SYS___sysctlbyname      = 570;
    uint16 constant SYS___realpathat        = 574;
    uint16 constant SYS___specialfd         = 577;

    uint16 constant SYS___acl_get_file      = 347;
    uint16 constant SYS___acl_set_file      = 348;
    uint16 constant SYS___acl_get_fd        = 349;
    uint16 constant SYS___acl_set_fd        = 350;
    uint16 constant SYS___acl_delete_file   = 351;
    uint16 constant SYS___acl_delete_fd     = 352;
    uint16 constant SYS___acl_aclcheck_file = 353;
    uint16 constant SYS___acl_aclcheck_fd   = 354;
    uint16 constant SYS___acl_get_link      = 425;
    uint16 constant SYS___acl_set_link      = 426;
    uint16 constant SYS___acl_delete_link   = 427;
    uint16 constant SYS___acl_aclcheck_link = 428;

    uint16 constant SYS___mac_get_proc      = 384;
    uint16 constant SYS___mac_set_proc      = 385;
    uint16 constant SYS___mac_get_fd        = 386;
    uint16 constant SYS___mac_get_file      = 387;
    uint16 constant SYS___mac_set_fd        = 388;
    uint16 constant SYS___mac_set_file      = 389;
    uint16 constant SYS___mac_get_pid       = 409;
    uint16 constant SYS___mac_get_link      = 410;
    uint16 constant SYS___mac_set_link      = 411;
    uint16 constant SYS___mac_execve        = 415;


    uint16 constant SYS_aio_read            = 255;
    uint16 constant SYS_aio_write           = 256;
    uint16 constant SYS_aio_return          = 314;
    uint16 constant SYS_aio_suspend         = 315;
    uint16 constant SYS_aio_cancel          = 316;
    uint16 constant SYS_aio_error           = 317;
    uint16 constant SYS_aio_waitcomplete    = 359;
    uint16 constant SYS_aio_fsync           = 465;
    uint16 constant SYS_aio_mlock          = 543;
    uint16 constant SYS_aio_writev         = 578;
    uint16 constant SYS_aio_readv          = 579;

    uint16 constant SYS_audit               = 445;
    uint16 constant SYS_auditon             = 446;
    uint16 constant SYS_getauid             = 447;
    uint16 constant SYS_setauid             = 448;
    uint16 constant SYS_getaudit            = 449;
    uint16 constant SYS_setaudit            = 450;
    uint16 constant SYS_getaudit_addr       = 451;
    uint16 constant SYS_setaudit_addr       = 452;
    uint16 constant SYS_auditctl            = 453;


    uint16 constant SYS_cap_enter          = 516;
    uint16 constant SYS_cap_getmode        = 517;
    uint16 constant SYS_cap_rights_limit   = 533;
    uint16 constant SYS_cap_ioctls_limit   = 534;
    uint16 constant SYS_cap_ioctls_get     = 535;
    uint16 constant SYS_cap_fcntls_limit   = 536;
    uint16 constant SYS_cap_fcntls_get     = 537;

    uint16 constant SYS_clock_gettime       = 232;
    uint16 constant SYS_clock_settime       = 233;
    uint16 constant SYS_clock_getres        = 234;
    uint16 constant SYS_ktimer_create       = 235;
    uint16 constant SYS_ktimer_delete       = 236;
    uint16 constant SYS_ktimer_settime      = 237;
    uint16 constant SYS_ktimer_gettime      = 238;
    uint16 constant SYS_ktimer_getoverrun   = 239;
    uint16 constant SYS_nanosleep           = 240;
    uint16 constant SYS_ffclock_getcounter  = 241;
    uint16 constant SYS_ffclock_setestimate = 242;
    uint16 constant SYS_ffclock_getestimate = 243;
    uint16 constant SYS_clock_nanosleep     = 244;
    uint16 constant SYS_clock_getcpuclockid2 = 247;
    uint16 constant SYS_ntp_gettime         = 248;

    uint16 constant SYS_cpuset             = 484;
    uint16 constant SYS_cpuset_setid       = 485;
    uint16 constant SYS_cpuset_getid       = 486;
    uint16 constant SYS_cpuset_getaffinity = 487;
    uint16 constant SYS_cpuset_setaffinity = 488;
    uint16 constant SYS_cpuset_getdomain   = 561;
    uint16 constant SYS_cpuset_setdomain   = 562;


    uint16 constant SYS_extattrctl          = 355;
    uint16 constant SYS_extattr_set_file    = 356;
    uint16 constant SYS_extattr_get_file    = 357;
    uint16 constant SYS_extattr_delete_file = 358;
    uint16 constant SYS_extattr_set_fd      = 371;
    uint16 constant SYS_extattr_get_fd      = 372;
    uint16 constant SYS_extattr_delete_fd   = 373;
    uint16 constant SYS_extattr_set_link    = 412;
    uint16 constant SYS_extattr_get_link    = 413;
    uint16 constant SYS_extattr_delete_link = 414;
    uint16 constant SYS_extattr_list_fd     = 437;
    uint16 constant SYS_extattr_list_file   = 438;
    uint16 constant SYS_extattr_list_link   = 439;

    uint16 constant SYS_lgetfh              = 160;
    uint16 constant SYS_getfh               = 161;
    uint16 constant SYS_fhopen              = 298;
    uint16 constant SYS_fhstat             = 553;
    uint16 constant SYS_fhstatfs           = 558;
    uint16 constant SYS_getfhat            = 564;
    uint16 constant SYS_fhlink             = 565;
    uint16 constant SYS_fhlinkat           = 566;
    uint16 constant SYS_fhreadlink         = 567;

    uint16 constant SYS_jail                = 338;
    uint16 constant SYS_jail_attach         = 436;
    uint16 constant SYS_jail_get           = 506;
    uint16 constant SYS_jail_set           = 507;
    uint16 constant SYS_jail_remove        = 508;


    uint16 constant SYS_kmq_open            = 457;
    uint16 constant SYS_kmq_setattr         = 458;
    uint16 constant SYS_kmq_timedreceive    = 459;
    uint16 constant SYS_kmq_timedsend       = 460;
    uint16 constant SYS_kmq_notify          = 461;
    uint16 constant SYS_kmq_unlink          = 462;


    uint16 constant SYS_ksem_close          = 400;
    uint16 constant SYS_ksem_post           = 401;
    uint16 constant SYS_ksem_wait           = 402;
    uint16 constant SYS_ksem_trywait        = 403;
    uint16 constant SYS_ksem_init           = 404;
    uint16 constant SYS_ksem_open           = 405;
    uint16 constant SYS_ksem_unlink         = 406;
    uint16 constant SYS_ksem_getvalue       = 407;
    uint16 constant SYS_ksem_destroy        = 408;
    uint16 constant SYS_ksem_timedwait      = 441;

    uint16 constant SYS_mac_syscall         = 394;

    uint16 constant SYS_modnext             = 300;
    uint16 constant SYS_modstat             = 301;
    uint16 constant SYS_modfnext            = 302;
    uint16 constant SYS_modfind             = 303;
    uint16 constant SYS_kldload             = 304;
    uint16 constant SYS_kldunload           = 305;
    uint16 constant SYS_kldfind             = 306;
    uint16 constant SYS_kldnext             = 307;
    uint16 constant SYS_kldstat             = 308;
    uint16 constant SYS_kldfirstmod         = 309;
    uint16 constant SYS_kldsym              = 337;

    uint16 constant SYS_posix_openpt       = 504;
    uint16 constant SYS_posix_fallocate    = 530;
    uint16 constant SYS_posix_fadvise      = 531;

    uint16 constant SYS_rctl_get_racct     = 525;
    uint16 constant SYS_rctl_get_rules     = 526;
    uint16 constant SYS_rctl_get_limits    = 527;
    uint16 constant SYS_rctl_add_rule      = 528;
    uint16 constant SYS_rctl_remove_rule   = 529;


    uint16 constant SYS_sched_setparam      = 327;
    uint16 constant SYS_sched_getparam      = 328;
    uint16 constant SYS_sched_setscheduler  = 329;
    uint16 constant SYS_sched_getscheduler  = 330;
    uint16 constant SYS_sched_yield         = 331;
    uint16 constant SYS_sched_get_priority_max = 332;
    uint16 constant SYS_sched_get_priority_min = 333;
    uint16 constant SYS_sched_rr_get_interval  = 334;


    uint16 constant SYS_sctp_peeloff        = 471;
    uint16 constant SYS_sctp_generic_sendmsg     = 472;
    uint16 constant SYS_sctp_generic_sendmsg_iov = 473;
    uint16 constant SYS_sctp_generic_recvmsg     = 474;

    uint16 constant SYS_shmat               = 228;
    uint16 constant SYS_shmdt               = 230;
    uint16 constant SYS_shmget              = 231;
    uint16 constant SYS_shm_unlink         = 483;
    uint16 constant SYS_shmctl             = 512;
    uint16 constant SYS_shm_open2          = 571;
    uint16 constant SYS_shm_rename         = 572;

    uint16 constant SYS_sigaltstack         = 53;
    uint16 constant SYS_sigprocmask         = 340;
    uint16 constant SYS_sigsuspend          = 341;
    uint16 constant SYS_sigpending          = 343;
    uint16 constant SYS_sigtimedwait        = 345;
    uint16 constant SYS_sigwaitinfo         = 346;
    uint16 constant SYS_sigaction           = 416;
    uint16 constant SYS_sigreturn           = 417;
    uint16 constant SYS_sigwait             = 429;
    uint16 constant SYS_sigqueue            = 456;
    uint16 constant SYS_sigfastblock       = 573;


    uint16 constant SYS_thr_create          = 430;
    uint16 constant SYS_thr_exit            = 431;
    uint16 constant SYS_thr_self            = 432;
    uint16 constant SYS_thr_kill            = 433;
    uint16 constant SYS_thr_suspend         = 442;
    uint16 constant SYS_thr_wake            = 443;
    uint16 constant SYS_thr_kill2          = 481;


    uint16 constant SYS_kenv                = 390;
    uint16 constant SYS_lchflags            = 391;
    uint16 constant SYS_uuidgen             = 392;
    uint16 constant SYS_sendfile            = 393;
    uint16 constant SYS_getcontext          = 421;
    uint16 constant SYS_setcontext          = 422;
    uint16 constant SYS_swapcontext         = 423;
    uint16 constant SYS_swapoff             = 424;
    uint16 constant SYS_kldunloadf          = 444;
    uint16 constant SYS__umtx_op            = 454;
    uint16 constant SYS_abort2              = 463;
    uint16 constant SYS_rtprio_thread       = 466;
    uint16 constant SYS_pread              = 475;
    uint16 constant SYS_pwrite             = 476;
    uint16 constant SYS_mmap               = 477;
    uint16 constant SYS_lseek              = 478;
    uint16 constant SYS_truncate           = 479;
    uint16 constant SYS_ftruncate          = 480;
    uint16 constant SYS_faccessat          = 489;
    uint16 constant SYS_fchmodat           = 490;
    uint16 constant SYS_fchownat           = 491;
    uint16 constant SYS_fexecve            = 492;
    uint16 constant SYS_futimesat          = 494;
    uint16 constant SYS_linkat             = 495;
    uint16 constant SYS_mkdirat            = 496;
    uint16 constant SYS_mkfifoat           = 497;
    uint16 constant SYS_openat             = 499;
    uint16 constant SYS_readlinkat         = 500;
    uint16 constant SYS_renameat           = 501;
    uint16 constant SYS_symlinkat          = 502;
    uint16 constant SYS_unlinkat           = 503;
    uint16 constant SYS_gssd_syscall       = 505;
    uint16 constant SYS_msgctl             = 511;
    uint16 constant SYS_lpathconf          = 513;
    uint16 constant SYS_pdfork             = 518;
    uint16 constant SYS_pdkill             = 519;
    uint16 constant SYS_pdgetpid           = 520;
    uint16 constant SYS_pselect            = 522;
    uint16 constant SYS_getloginclass      = 523;
    uint16 constant SYS_setloginclass      = 524;
    uint16 constant SYS_wait6              = 532;
    uint16 constant SYS_bindat             = 538;
    uint16 constant SYS_connectat          = 539;
    uint16 constant SYS_chflagsat          = 540;
    uint16 constant SYS_accept4            = 541;
    uint16 constant SYS_pipe2              = 542;
    uint16 constant SYS_procctl            = 544;
    uint16 constant SYS_ppoll              = 545;
    uint16 constant SYS_futimens           = 546;
    uint16 constant SYS_utimensat          = 547;
    uint16 constant SYS_fdatasync          = 550;
    uint16 constant SYS_fstat              = 551;
    uint16 constant SYS_fstatat            = 552;
    uint16 constant SYS_getdirentries      = 554;
    uint16 constant SYS_statfs             = 555;
    uint16 constant SYS_fstatfs            = 556;
    uint16 constant SYS_getfsstat          = 557;
    uint16 constant SYS_mknodat            = 559;
    uint16 constant SYS_kevent             = 560;
    uint16 constant SYS_getrandom          = 563;
    uint16 constant SYS_funlinkat          = 568;
    uint16 constant SYS_copy_file_range    = 569;
    uint16 constant SYS_close_range        = 575;
    uint16 constant SYS_rpctls_syscall     = 576;
    uint16 constant SYS_MAXSYSCALL         = 580;


    /*
    * 8 is old creat
    * 11 is obsolete execv
    * 18 is freebsd4 getfsstat
    * 19 is old lseek
    * 38 is old stat
    * 40 is old lstat
    * 46 is old sigaction
    * 48 is old sigprocmask
    * 52 is old sigpending
    * 62 is old fstat
    * 63 is old getkerninfo
    * 64 is old getpagesize
    * 67 is obsolete vread
    * 68 is obsolete vwrite
    * 71 is old mmap
    * 76 is obsolete vhangup
    * 77 is obsolete vlimit
    * 84 is old wait
    * 87 is old gethostname
    * 88 is old sethostname
    * 99 is old accept
    * 101 is old send
    * 102 is old recv
    * 103 is old sigreturn
    * 107 is obsolete vtimes
    * 108 is old sigvec
    * 109 is old sigblock
    * 110 is old sigsetmask
    * 111 is old sigsuspend
    * 112 is old sigstack
    * 113 is old recvmsg
    * 114 is old sendmsg
    * 115 is obsolete vtrace
    * 125 is old recvfrom
    * 129 is old truncate
    * 130 is old ftruncate
    * 139 is obsolete 4.2 sigreturn
    * 141 is old getpeername
    * 142 is old gethostid
    * 143 is old sethostid
    * 144 is old getrlimit
    * 145 is old setrlimit
    * 146 is old killpg
    * 149 is old quota
    * 150 is old getsockname
    * 156 is old getdirentries
    * 157 is freebsd4 statfs
    * 158 is freebsd4 fstatfs
    * 162 is freebsd4 getdomainname
    * 163 is freebsd4 setdomainname
    * 164 is freebsd4 uname
    * 173 is freebsd6 pread
    * 174 is freebsd6 pwrite
    * 184 is obsolete lfs_bmapv
    * 185 is obsolete lfs_markv
    * 186 is obsolete lfs_segclean
    * 187 is obsolete lfs_segwait
    * 197 is freebsd6 mmap
    * 199 is freebsd6 lseek
    * 200 is freebsd6 truncate
    * 201 is freebsd6 ftruncate
    * 223 is obsolete semconfig
    * 252 is obsolete openbsd_poll
    * 275 is obsolete netbsd_lchown
    * 277 is obsolete netbsd_msync
    * 297 is freebsd4 fhstatfs
    * 313 is obsolete signanosleep
    * 318 is freebsd6 aio_read
    * 319 is freebsd6 aio_write
    * 320 is freebsd6 lio_listio
    * 322 is obsolete thr_sleep
    * 323 is obsolete thr_wakeup
    * 336 is freebsd4 sendfile
    * 342 is freebsd4 sigaction
    * 344 is freebsd4 sigreturn
    * 364 is obsolete __cap_get_proc
    * 365 is obsolete __cap_set_proc
    * 366 is obsolete __cap_get_fd
    * 367 is obsolete __cap_get_file
    * 368 is obsolete __cap_set_fd
    * 369 is obsolete __cap_set_file
    * 375 is obsolete nfsclnt
    * 379 is obsolete kse_exit
    * 380 is obsolete kse_wakeup
    * 381 is obsolete kse_create
    * 382 is obsolete kse_thr_interrupt
    * 383 is obsolete kse_release
    * 440 is obsolete kse_switchin
    * 514 is obsolete cap_new
    * 548 is obsolete numa_getaffinity
    * 549 is obsolete numa_setaffinity
    */
}