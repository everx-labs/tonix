pragma ton-solidity >= 0.62.0;

import "proc_h.sol";
import "ucred_h.sol";
library priv {

    // The remaining privileges typically correspond to one or a small number of specific privilege checks,
    // and have (relatively) precise meanings. They are loosely sorted into a set of base system privileges,
    // such as the ability to reboot, and then loosely by subsystem, indicated by a subsystem name.
    uint16 constant _PRIV_LOWEST            = 1;
    uint16 constant _PRIV_ROOT              = 1;   // Removed.
    uint16 constant PRIV_ACCT               = 2;   // Manage process accounting.
    uint16 constant PRIV_MAXFILES           = 3;   // Exceed system open files limit.
    uint16 constant PRIV_MAXPROC            = 4;   // Exceed system processes limit.
    uint16 constant PRIV_KTRACE             = 5;   // Set/clear KTRFAC_ROOT on ktrace.
    uint16 constant PRIV_SETDUMPER          = 6;   // Configure dump device.
    uint16 constant PRIV_REBOOT             = 8;   // Can reboot system.
    uint16 constant PRIV_SWAPON             = 9;   // Can swapon().
    uint16 constant PRIV_SWAPOFF            = 10;  // Can swapoff().
    uint16 constant PRIV_MSGBUF             = 11;  // Can read kernel message buffer.
    uint16 constant PRIV_IO                 = 12;  // Can perform low-level I/O.
    uint16 constant PRIV_KEYBOARD           = 13;  // Reprogram keyboard.
    uint16 constant PRIV_DRIVER             = 14;  // Low-level driver privilege.
    uint16 constant PRIV_ADJTIME            = 15;  // Set time adjustment.
    uint16 constant PRIV_NTP_ADJTIME        = 16;  // Set NTP time adjustment.
    uint16 constant PRIV_CLOCK_SETTIME      = 17;  // Can call clock_settime.
    uint16 constant PRIV_SETTIMEOFDAY       = 18;  // Can call settimeofday.
    uint16 constant _PRIV_SETHOSTID         = 19;  // Removed.
    uint16 constant _PRIV_SETDOMAINNAME     = 20;  // Removed.
    uint16 constant PRIV_AUDIT_CONTROL      = 40;  // Can configure audit.
    uint16 constant PRIV_AUDIT_FAILSTOP     = 41;  // Can run during audit fail stop.
    uint16 constant PRIV_AUDIT_GETAUDIT     = 42;  // Can get proc audit properties.
    uint16 constant PRIV_AUDIT_SETAUDIT     = 43;  // Can set proc audit properties.
    uint16 constant PRIV_AUDIT_SUBMIT       = 44;  // Can submit an audit record.
    uint16 constant PRIV_CRED_SETUID        = 50;  // setuid.
    uint16 constant PRIV_CRED_SETEUID       = 51;  // seteuid to !ruid and !svuid.
    uint16 constant PRIV_CRED_SETGID        = 52;  // setgid.
    uint16 constant PRIV_CRED_SETEGID       = 53;  // setgid to !rgid and !svgid.
    uint16 constant PRIV_CRED_SETGROUPS     = 54;  // Set process additional groups.
    uint16 constant PRIV_CRED_SETREUID      = 55;  // setreuid.
    uint16 constant PRIV_CRED_SETREGID      = 56;  // setregid.
    uint16 constant PRIV_CRED_SETRESUID     = 57;  // setresuid.
    uint16 constant PRIV_CRED_SETRESGID     = 58;  // setresgid.
    uint16 constant PRIV_SEEOTHERGIDS       = 59;  // Exempt bsd.seeothergids.
    uint16 constant PRIV_SEEOTHERUIDS       = 60;  // Exempt bsd.seeotheruids.
    uint16 constant PRIV_DEBUG_DIFFCRED     = 80;  // Exempt debugging other users.
    uint16 constant PRIV_DEBUG_SUGID        = 81;  // Exempt debugging setuid proc.
    uint16 constant PRIV_DEBUG_UNPRIV       = 82;  // Exempt unprivileged debug limit.
    uint16 constant PRIV_DEBUG_DENIED       = 83;  // Exempt P2_NOTRACE.
    uint16 constant PRIV_DTRACE_KERNEL      = 90;  // Allow use of DTrace on the kernel.
    uint16 constant PRIV_DTRACE_PROC        = 91;  // Allow attaching DTrace to process.
    uint16 constant PRIV_DTRACE_USER        = 92;  // Process may submit DTrace events.
    uint16 constant PRIV_FIRMWARE_LOAD      = 100; // Can load firmware.
    uint16 constant PRIV_JAIL_ATTACH        = 110; // Attach to a jail.
    uint16 constant PRIV_JAIL_SET           = 111; // Set jail parameters.
    uint16 constant PRIV_JAIL_REMOVE        = 112; // Remove a jail.
    uint16 constant PRIV_KENV_SET           = 120; // Set kernel env. variables.
    uint16 constant PRIV_KENV_UNSET         = 121; // Unset kernel env. variables.
    uint16 constant PRIV_KLD_LOAD           = 130; // Load a kernel module.
    uint16 constant PRIV_KLD_UNLOAD         = 131; // Unload a kernel module.
    uint16 constant PRIV_MAC_PARTITION      = 140; // Privilege in mac_partition policy.
    uint16 constant PRIV_MAC_PRIVS          = 141; // Privilege in the mac_privs policy.
    uint16 constant PRIV_PROC_LIMIT         = 160; // Exceed user process limit.
    uint16 constant PRIV_PROC_SETLOGIN      = 161; // Can call setlogin.
    uint16 constant PRIV_PROC_SETRLIMIT     = 162; // Can raise resources limits.
    uint16 constant PRIV_PROC_SETLOGINCLASS = 163; // Can call setloginclass(2).
    uint16 constant PRIV_IPC_READ           = 170; // Can override IPC read perm.
    uint16 constant PRIV_IPC_WRITE          = 171; // Can override IPC write perm.
    uint16 constant PRIV_IPC_ADMIN          = 172; // Can override IPC owner-only perm.
    uint16 constant PRIV_IPC_MSGSIZE        = 173; // Exempt IPC message queue limit.
    uint16 constant PRIV_MQ_ADMIN           = 180; // Can override msgq owner-only perm.
    uint16 constant PRIV_PMC_MANAGE         = 190; // Can administer PMC.
    uint16 constant PRIV_PMC_SYSTEM         = 191; // Can allocate a system-wide PMC.
    uint16 constant PRIV_SCHED_DIFFCRED     = 200; // Exempt scheduling other users.
    uint16 constant PRIV_SCHED_SETPRIORITY  = 201; // Can set lower nice value for proc.
    uint16 constant PRIV_SCHED_RTPRIO       = 202; // Can set real time scheduling.
    uint16 constant PRIV_SCHED_SETPOLICY    = 203; // Can set scheduler policy.
    uint16 constant PRIV_SCHED_SET          = 204; // Can set thread scheduler.
    uint16 constant PRIV_SCHED_SETPARAM     = 205; // Can set thread scheduler params.
    uint16 constant PRIV_SCHED_CPUSET       = 206; // Can manipulate cpusets.
    uint16 constant PRIV_SCHED_CPUSET_INTR  = 207; // Can adjust IRQ to CPU binding.
    uint16 constant PRIV_SEM_WRITE          = 220; // Can override sem write perm.
    uint16 constant PRIV_SIGNAL_DIFFCRED    = 230; // Exempt signalling other users.
    uint16 constant PRIV_SIGNAL_SUGID       = 231; // Non-conserv signal setuid proc.
    uint16 constant PRIV_SYSCTL_DEBUG       = 240; // Can invoke sysctl.debug.
    uint16 constant PRIV_SYSCTL_WRITE       = 241; // Can write sysctls.
    uint16 constant PRIV_SYSCTL_WRITEJAIL   = 242; // Can write sysctls, jail permitted.
    uint16 constant PRIV_TTY_CONSOLE        = 250; // Set console to tty.
    uint16 constant PRIV_TTY_DRAINWAIT      = 251; // Set tty drain wait time.
    uint16 constant PRIV_TTY_DTRWAIT        = 252; // Set DTR wait on tty.
    uint16 constant PRIV_TTY_EXCLUSIVE      = 253; // Override tty exclusive flag.
    uint16 constant _PRIV_TTY_PRISON        = 254; // Removed.
    uint16 constant PRIV_TTY_STI            = 255; // Simulate input on another tty.
    uint16 constant PRIV_TTY_SETA           = 256; // Set tty termios structure.
    uint16 constant PRIV_UFS_EXTATTRCTL     = 270; // Can configure EAs on UFS1.
    uint16 constant PRIV_UFS_QUOTAOFF       = 271; // quotaoff().
    uint16 constant PRIV_UFS_QUOTAON        = 272; // quotaon().
    uint16 constant PRIV_UFS_SETUSE         = 273; // setuse().
    uint16 constant PRIV_ZFS_POOL_CONFIG    = 280; // Can configure ZFS pools.
    uint16 constant PRIV_ZFS_INJECT         = 281; // Can inject faults in the ZFS fault injection framework.
    uint16 constant PRIV_ZFS_JAIL           = 282; // Can attach/detach ZFS file systems to/from jails.
    uint16 constant PRIV_NFS_DAEMON         = 290; // Can become the NFS daemon.
    uint16 constant PRIV_NFS_LOCKD          = 291; // Can become NFS lock daemon.
    uint16 constant PRIV_VFS_READ           = 310; // Override vnode DAC read perm.
    uint16 constant PRIV_VFS_WRITE          = 311; // Override vnode DAC write perm.
    uint16 constant PRIV_VFS_ADMIN          = 312; // Override vnode DAC admin perm.
    uint16 constant PRIV_VFS_EXEC           = 313; // Override vnode DAC exec perm.
    uint16 constant PRIV_VFS_LOOKUP         = 314; // Override vnode DAC lookup perm.
    uint16 constant PRIV_VFS_BLOCKRESERVE   = 315; // Can use free block reserve.
    uint16 constant PRIV_VFS_CHFLAGS_DEV    = 316; // Can chflags() a device node.
    uint16 constant PRIV_VFS_CHOWN          = 317; // Can set user; group to non-member.
    uint16 constant PRIV_VFS_CHROOT         = 318; // chroot().
    uint16 constant PRIV_VFS_RETAINSUGID    = 319; // Can retain sugid bits on change.
    uint16 constant PRIV_VFS_EXCEEDQUOTA    = 320; // Exempt from quota restrictions.
    uint16 constant PRIV_VFS_EXTATTR_SYSTEM = 321; // Operate on system EA namespace.
    uint16 constant PRIV_VFS_FCHROOT        = 322; // fchroot().
    uint16 constant PRIV_VFS_FHOPEN         = 323; // Can fhopen().
    uint16 constant PRIV_VFS_FHSTAT         = 324; // Can fhstat().
    uint16 constant PRIV_VFS_FHSTATFS       = 325; // Can fhstatfs().
    uint16 constant PRIV_VFS_GENERATION     = 326; // stat() returns generation number.
    uint16 constant PRIV_VFS_GETFH          = 327; // Can retrieve file handles.
    uint16 constant PRIV_VFS_GETQUOTA       = 328; // getquota().
    uint16 constant PRIV_VFS_LINK           = 329; // bsd.hardlink_check_uid
    uint16 constant PRIV_VFS_MKNOD_BAD      = 330; // Was: mknod() can mark bad inodes.
    uint16 constant PRIV_VFS_MKNOD_DEV      = 331; // Can mknod() to create dev nodes.
    uint16 constant PRIV_VFS_MKNOD_WHT      = 332; // Can mknod() to create whiteout.
    uint16 constant PRIV_VFS_MOUNT          = 333; // Can mount().
    uint16 constant PRIV_VFS_MOUNT_OWNER    = 334; // Can manage other users' file systems.
    uint16 constant PRIV_VFS_MOUNT_EXPORTED = 335; // Can set MNT_EXPORTED on mount.
    uint16 constant PRIV_VFS_MOUNT_PERM     = 336; // Override dev node perms at mount.
    uint16 constant PRIV_VFS_MOUNT_SUIDDIR  = 337; // Can set MNT_SUIDDIR on mount.
    uint16 constant PRIV_VFS_MOUNT_NONUSER  = 338; // Can perform a non-user mount.
    uint16 constant PRIV_VFS_SETGID         = 339; // Can setgid if not in group.
    uint16 constant PRIV_VFS_SETQUOTA       = 340; // setquota().
    uint16 constant PRIV_VFS_STICKYFILE     = 341; // Can set sticky bit on file.
    uint16 constant PRIV_VFS_SYSFLAGS       = 342; // Can modify system flags.
    uint16 constant PRIV_VFS_UNMOUNT        = 343; // Can unmount().
    uint16 constant PRIV_VFS_STAT           = 344; // Override vnode MAC stat perm.
    uint16 constant PRIV_VFS_READ_DIR       = 345; // Can read(2) a dirfd, needs sysctl.
    uint16 constant PRIV_VM_MADV_PROTECT    = 360; // Can set MADV_PROTECT.
    uint16 constant PRIV_VM_MLOCK           = 361; // Can mlock(), mlockall().
    uint16 constant PRIV_VM_MUNLOCK         = 362; // Can munlock(), munlockall().
    uint16 constant PRIV_VM_SWAP_NOQUOTA    = 363; // Can override the global swap reservation limits.
    uint16 constant PRIV_VM_SWAP_NORLIMIT   = 364; // * Can override the per-uid * swap reservation limits.
    uint16 constant PRIV_DEVFS_RULE         = 370; // Can manage devfs rules.
    uint16 constant PRIV_DEVFS_SYMLINK      = 371; // Can create symlinks in devfs.
    uint16 constant PRIV_RANDOM_RESEED      = 380; // Closing /dev/random reseeds.
    uint16 constant PRIV_NET_BRIDGE         = 390; // Administer bridge.
    uint16 constant PRIV_NET_GRE            = 391; // Administer GRE.
    uint16 constant _PRIV_NET_PPP           = 392; // Removed.
    uint16 constant _PRIV_NET_SLIP          = 393; // Removed.
    uint16 constant PRIV_NET_BPF            = 394; // Monitor BPF.
    uint16 constant PRIV_NET_RAW            = 395; // Open raw socket.
    uint16 constant PRIV_NET_ROUTE          = 396; // Administer routing.
    uint16 constant PRIV_NET_TAP            = 397; // Can open tap device.
    uint16 constant PRIV_NET_SETIFMTU       = 398; // Set interface MTU.
    uint16 constant PRIV_NET_SETIFFLAGS     = 399; // Set interface flags.
    uint16 constant PRIV_NET_SETIFCAP       = 400; // Set interface capabilities.
    uint16 constant PRIV_NET_SETIFNAME      = 401; // Set interface name.
    uint16 constant PRIV_NET_SETIFMETRIC    = 402; // Set interface metrics.
    uint16 constant PRIV_NET_SETIFPHYS      = 403; // Set interface physical layer prop.
    uint16 constant PRIV_NET_SETIFMAC       = 404; // Set interface MAC label.
    uint16 constant PRIV_NET_ADDMULTI       = 405; // Add multicast addr. to ifnet.
    uint16 constant PRIV_NET_DELMULTI       = 406; // Delete multicast addr. from ifnet.
    uint16 constant PRIV_NET_HWIOCTL        = 407; // Issue hardware ioctl on ifnet.
    uint16 constant PRIV_NET_SETLLADDR      = 408; // Set interface link-level address.
    uint16 constant PRIV_NET_ADDIFGROUP     = 409; // Add new interface group.
    uint16 constant PRIV_NET_DELIFGROUP     = 410; // Delete interface group.
    uint16 constant PRIV_NET_IFCREATE       = 411; // Create cloned interface.
    uint16 constant PRIV_NET_IFDESTROY      = 412; // Destroy cloned interface.
    uint16 constant PRIV_NET_ADDIFADDR      = 413; // Add protocol addr to interface.
    uint16 constant PRIV_NET_DELIFADDR      = 414; // Delete protocol addr on interface.
    uint16 constant PRIV_NET_LAGG           = 415; // Administer lagg interface.
    uint16 constant PRIV_NET_GIF            = 416; // Administer gif interface.
    uint16 constant PRIV_NET_SETIFVNET      = 417; // Move interface to vnet.
    uint16 constant PRIV_NET_SETIFDESCR     = 418; // Set interface description.
    uint16 constant PRIV_NET_SETIFFIB       = 419; // Set interface fib.
    uint16 constant PRIV_NET_VXLAN          = 420; // Administer vxlan.
    uint16 constant PRIV_NET_SETLANPCP      = 421; // Set LAN priority.
    uint16 constant PRIV_NET_SETVLANPCP     = PRIV_NET_SETLANPCP; // Alias Set VLAN priority
    uint16 constant PRIV_NET80211_VAP_GETKEY = 440; // Query VAP 802.11 keys.
    uint16 constant PRIV_NET80211_VAP_MANAGE = 441; // Administer 802.11 VAP
    uint16 constant PRIV_NET80211_VAP_SETMAC = 442; // Set VAP MAC address
    uint16 constant PRIV_NET80211_CREATE_VAP = 443; // Create a new VAP
    uint16 constant _PRIV_NETATALK_RESERVEDPORT = 450; // Bind low port number.
    uint16 constant PRIV_NETATM_CFG         = 460;
    uint16 constant PRIV_NETATM_ADD         = 461;
    uint16 constant PRIV_NETATM_DEL         = 462;
    uint16 constant PRIV_NETATM_SET         = 463;
    uint16 constant PRIV_NETBLUETOOTH_RAW   = 470; // Open raw bluetooth socket.
    uint16 constant PRIV_NETGRAPH_CONTROL   = 480; // Open netgraph control socket.
    uint16 constant PRIV_NETGRAPH_TTY       = 481; // Configure tty for netgraph.
    uint16 constant PRIV_NETINET_RESERVEDPORT = 490; // Bind low port number.
    uint16 constant PRIV_NETINET_IPFW       = 491; // Administer IPFW firewall.
    uint16 constant PRIV_NETINET_DIVERT     = 492; // Open IP divert socket.
    uint16 constant PRIV_NETINET_PF         = 493; // Administer pf firewall.
    uint16 constant PRIV_NETINET_DUMMYNET   = 494; // Administer DUMMYNET.
    uint16 constant PRIV_NETINET_CARP       = 495; // Administer CARP.
    uint16 constant PRIV_NETINET_MROUTE     = 496; // Administer multicast routing.
    uint16 constant PRIV_NETINET_RAW        = 497; // Open netinet raw socket.
    uint16 constant PRIV_NETINET_GETCRED    = 498; // Query netinet pcb credentials.
    uint16 constant PRIV_NETINET_ADDRCTRL6  = 499; // Administer IPv6 address scopes.
    uint16 constant PRIV_NETINET_ND6        = 500; // Administer IPv6 neighbor disc.
    uint16 constant PRIV_NETINET_SCOPE6     = 501; // Administer IPv6 address scopes.
    uint16 constant PRIV_NETINET_ALIFETIME6 = 502; // Administer IPv6 address lifetimes.
    uint16 constant PRIV_NETINET_IPSEC      = 503; // Administer IPSEC.
    uint16 constant PRIV_NETINET_REUSEPORT  = 504; // Allow [rapid] port/address reuse.
    uint16 constant PRIV_NETINET_SETHDROPTS = 505; // Set certain IPv4/6 header options.
    uint16 constant PRIV_NETINET_BINDANY    = 506; // Allow bind to any address.
    uint16 constant PRIV_NETINET_HASHKEY    = 507; // Get and set hash keys for IPv4/6.
    uint16 constant _PRIV_NETIPX_RESERVEDPORT = 520; // Bind low port number.
    uint16 constant _PRIV_NETIPX_RAW        = 521; // Open netipx raw socket.
    uint16 constant PRIV_NETNCP             = 530; // Use another user's connection.
    uint16 constant PRIV_NETSMB             = 540; // Use another user's connection.
    uint16 constant PRIV_VM86_INTCALL       = 550; // Allow invoking vm86 int handlers.
    uint16 constant _PRIV_RESERVED0         = 560;
    uint16 constant _PRIV_RESERVED1         = 561;
    uint16 constant _PRIV_RESERVED2         = 562;
    uint16 constant _PRIV_RESERVED3         = 563;
    uint16 constant _PRIV_RESERVED4         = 564;
    uint16 constant _PRIV_RESERVED5         = 565;
    uint16 constant _PRIV_RESERVED6         = 566;
    uint16 constant _PRIV_RESERVED7         = 567;
    uint16 constant _PRIV_RESERVED8         = 568;
    uint16 constant _PRIV_RESERVED9         = 569;
    uint16 constant _PRIV_RESERVED10        = 570;
    uint16 constant _PRIV_RESERVED11        = 571;
    uint16 constant _PRIV_RESERVED12        = 572;
    uint16 constant _PRIV_RESERVED13        = 573;
    uint16 constant _PRIV_RESERVED14        = 574;
    uint16 constant _PRIV_RESERVED15        = 575;
    uint16 constant PRIV_MODULE0            = 600;
    uint16 constant PRIV_MODULE1            = 601;
    uint16 constant PRIV_MODULE2            = 602;
    uint16 constant PRIV_MODULE3            = 603;
    uint16 constant PRIV_MODULE4            = 604;
    uint16 constant PRIV_MODULE5            = 605;
    uint16 constant PRIV_MODULE6            = 606;
    uint16 constant PRIV_MODULE7            = 607;
    uint16 constant PRIV_MODULE8            = 608;
    uint16 constant PRIV_MODULE9            = 609;
    uint16 constant PRIV_MODULE10           = 610;
    uint16 constant PRIV_MODULE11           = 611;
    uint16 constant PRIV_MODULE12           = 612;
    uint16 constant PRIV_MODULE13           = 613;
    uint16 constant PRIV_MODULE14           = 614;
    uint16 constant PRIV_MODULE15           = 615;
    uint16 constant PRIV_DDB_CAPTURE        = 620; // Allow reading of DDB capture log.
    uint16 constant PRIV_NNPFS_DEBUG        = 630; // Perforn ARLA_VIOC_NNPFSDEBUG.
    uint16 constant PRIV_CPUCTL_WRMSR       = 640; // Write model-specific register.
    uint16 constant PRIV_CPUCTL_UPDATE      = 641; // Update cpu microcode.
    uint16 constant PRIV_C4B_RESET_CTLR     = 650; // Load firmware, reset controller.
    uint16 constant PRIV_C4B_TRACE          = 651; // Unrestricted CAPI message tracing.
    uint16 constant PRIV_AFS_ADMIN          = 660; // Can change AFS client settings.
    uint16 constant PRIV_AFS_DAEMON         = 661; // Can become the AFS daemon.
    uint16 constant PRIV_RCTL_GET_RACCT     = 670;
    uint16 constant PRIV_RCTL_GET_RULES     = 671;
    uint16 constant PRIV_RCTL_GET_LIMITS    = 672;
    uint16 constant PRIV_RCTL_ADD_RULE      = 673;
    uint16 constant PRIV_RCTL_REMOVE_RULE   = 674;
    uint16 constant PRIV_KMEM_READ          = 680; // Open mem/kmem for reading.
    uint16 constant PRIV_KMEM_WRITE         = 681; // Open mem/kmem for writing.
    uint16 constant _PRIV_HIGHEST           = 682;

    // Validate that a named privilege is known by the privilege system.  Invalid
    // privileges presented to the privilege system by a priv_check interface
    // will result in a panic.  This is only approximate due to sparse allocation
    // of the privilege space.
    //#define PRIV_VALID(x)   ((x) > _PRIV_LOWEST && (x) < _PRIV_HIGHEST)

    function PRIV_VALID(uint16 x) internal returns (bool) {
        return x > _PRIV_LOWEST && x < _PRIV_HIGHEST;
    }

    function priv_check(s_thread td, uint16 ppriv) internal returns (uint8) {
//	    KASSERT(td == curthread, ("priv_check: td != curthread"));
	    return priv_check_cred(td.td_ucred, ppriv);
    }

    function priv_check_cred(s_ucred cred, uint16 ppriv) internal returns (uint8 error) {
        // Privilege check interfaces, modeled after historic suser() interfaces, but
        // with the addition of a specific privilege name.  No flags are currently
        // defined for the API.  Historically, flags specified using the real uid
        // instead of the effective uid, and whether or not the check should be
        // allowed in jail.
	    // KASSERT(PRIV_VALID(priv), ("priv_check_cred: invalid privilege %d", priv));

	    if (ppriv == PRIV_VFS_LOOKUP)
	    	return priv_check_cred_vfs_lookup(cred);
	    else if (ppriv == PRIV_VFS_GENERATION)
	    	return priv_check_cred_vfs_generation(cred);
//	    error = priv_check_cred_pre(cred, ppriv);
//	    error = prison_priv_check(cred, ppriv);
        /*if (unprivileged_mlock && (ppriv == PRIV_VM_MLOCK || ppriv == PRIV_VM_MUNLOCK))
			error = 0;
	    if (unprivileged_read_msgbuf && ppriv == PRIV_MSGBUF)
	    	error = 0;

	    if (suser_enabled(cred)) {*/
	    	if (ppriv == PRIV_MAXFILES || ppriv == PRIV_MAXPROC || ppriv == PRIV_PROC_LIMIT)
	    		if (cred.cr_ruid == 0)
	    			error = 0;
	    	else {
                if (cred.cr_uid == 0)
	    			error = 0;
	    	}
//	    }

	    if (ppriv == PRIV_KMEM_READ)
	    	error = 0;

//	    if (ppriv == PRIV_DEBUG_UNPRIV)
//	    	if (prison_allow(cred, PR_ALLOW_UNPRIV_DEBUG))
//	    		error = 0;

//	return priv_check_cred_post(cred, ppriv, error, false);
//	return (priv_check_cred_post(cred, ppriv, error, true));
    }

    function priv_check_cred_vfs_lookup(s_ucred cred) internal returns (uint8) {}
    function priv_check_cred_vfs_lookup_nomac(s_ucred cred) internal returns (uint8) {}
    function priv_check_cred_vfs_generation(s_ucred cred) internal returns (uint8) {}

}