pragma ton-solidity >= 0.64.0;

library libboot {
    uint32 constant RB_AUTOBOOT	    = 0;    	 // flags for system auto-booting itself
    uint32 constant RB_ASKNAME	    = 0x001;   	 // force prompt of device of root filesystem
    uint32 constant RB_SINGLE	    = 0x002;   	 // reboot to single user only
    uint32 constant RB_NOSYNC	    = 0x004;   	 // dont sync before reboot
    uint32 constant RB_HALT	        = 0x008;  	 // don't reboot, just halt
    uint32 constant RB_INITNAME	    = 0x010;   	 // Unused placeholder to specify init path
    uint32 constant RB_DFLTROOT	    = 0x020;   	 // use compiled-in rootdev
    uint32 constant RB_KDB	        = 0x040;  	 // give control to kernel debugger
    uint32 constant RB_RDONLY	    = 0x080;   	 // mount root fs read-only
    uint32 constant RB_DUMP	        = 0x100;  	 // dump kernel memory before reboot
    uint32 constant RB_MINIROOT	    = 0x200;     // Unused placeholder
    uint32 constant RB_VERBOSE	    = 0x800;     // print all potentially useful info
    uint32 constant RB_SERIAL	    = 0x1000;    // use serial port as console
    uint32 constant RB_CDROM	    = 0x2000;    // use cdrom as root
    uint32 constant RB_POWEROFF	    = 0x4000;    // turn the power off if possible
    uint32 constant RB_GDB	        = 0x8000; 	 // use GDB remote debugger instead of DDB
    uint32 constant RB_MUTE	        = 0x10000;   // start up with the console muted
    uint32 constant RB_SELFTEST	    = 0x20000;   // unused placeholder
    uint32 constant RB_RESERVED1	= 0x40000;   // reserved for internal use of boot blocks
    uint32 constant RB_RESERVED2	= 0x80000;   // reserved for internal use of boot blocks
    uint32 constant RB_PAUSE	    = 0x100000;  // pause after each output line during probe
    uint32 constant RB_REROOT	    = 0x200000;  // unmount the rootfs and mount it again
    uint32 constant RB_POWERCYCLE	= 0x400000;  // Power cycle if possible
    uint32 constant RB_PROBE	    = 0x10000000;// Probe multiple consoles
    uint32 constant RB_MULTIPLE	    = 0x20000000;// use multiple consoles
    uint32 constant RB_BOOTINFO	    = 0x80000000;// have `struct bootinfo *' arg
}