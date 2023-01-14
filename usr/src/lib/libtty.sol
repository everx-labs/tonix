pragma ton-solidity >= 0.62.0;
import "uio_h.sol";
import "tty_h.sol";

library libtty {

    uint32 constant TF_NOPREFIX    = 0x00001; // Don't prepend "tty" to device name.
    uint32 constant TF_INITLOCK    = 0x00002; // Create init/lock state devices.
    uint32 constant TF_CALLOUT     = 0x00004; // Create "cua" devices.
    uint32 constant TF_OPENED_IN   = 0x00008; // "tty" node is in use.
    uint32 constant TF_OPENED_OUT  = 0x00010; // "cua" node is in use.
    uint32 constant TF_OPENED_CONS = 0x00020; // Device in use as console.
    uint32 constant TF_OPENED      = TF_OPENED_IN | TF_OPENED_OUT | TF_OPENED_CONS;
    uint32 constant TF_GONE        = 0x00040; // Device node is gone.
    uint32 constant TF_OPENCLOSE   = 0x00080; // Device is in open()/close().
    uint32 constant TF_ASYNC       = 0x00100; // Asynchronous I/O enabled.
    uint32 constant TF_LITERAL     = 0x00200; // Accept the next character literally.
    uint32 constant TF_HIWAT_IN    = 0x00400; // We've reached the input watermark.
    uint32 constant TF_HIWAT_OUT   = 0x00800; // We've reached the output watermark.
    uint32 constant TF_HIWAT        = TF_HIWAT_IN | TF_HIWAT_OUT;
    uint32 constant TF_STOPPED      = 0x01000; // Output flow control - stopped.
    uint32 constant TF_EXCLUDE      = 0x02000; // Exclusive access.
    uint32 constant TF_BYPASS       = 0x04000; // Optimized input path.
    uint32 constant TF_ZOMBIE       = 0x08000; // Modem disconnect received.
    uint32 constant TF_HOOK         = 0x10000; // TTY has hook attached.
    uint32 constant TF_BUSY_IN      = 0x20000; // Process busy in read() -- not supported.
    uint32 constant TF_BUSY_OUT     = 0x40000; // Process busy in write().
    uint32 constant TF_BUSY         = TF_BUSY_IN | TF_BUSY_OUT;

    uint8 constant TTYUNIT_INIT	    = 0x1;
    uint8 constant TTYUNIT_LOCK	    = 0x2;
    uint8 constant TTYUNIT_CALLOUT  = 0x4;
    uint8 constant TTYMK_CLONING    = 0x1;
//    function tty_alloc(s_ttydevsw tsw, bytes softc) internal returns (s_tty) {}
/*
struct s_tty {
    uint32 t_flags;	     // Terminal option flags
    uint8 t_revokecnt;	 // revoke() count
    s_ttyinq t_inq;		 // Input queue
    uint8 t_inlow;	     // Input low watermark
    s_ttyoutq t_outq;	 // Output queue
    uint8 t_outlow;	     // Output low watermark
    s_cv t_inwait;	     // Input wait queue
    s_cv t_outwait;	     // Output wait queue
    s_cv t_outserwait;	 // Serial output wait queue
    s_cv t_bgwait;	     // Background wait queue
    s_cv t_dcdwait;	     // Carrier Detect wait queue
    s_selinfo t_inpoll;	 // Input poll queue
    s_selinfo t_outpoll; // Output poll queue
    s_sigio	t_sigio;	 // Asynchronous I/O
    s_winsize t_winsize; // Window size
    uint8 t_column;	     // Current cursor position
    uint8 t_writepos;	 // Where input was interrupted
    uint32 t_compatflags; // COMPAT_43TTY flags
    s_pgrp t_pgrp;	     // Foreground process group
    s_session t_session; // Associated session
    uint8 t_sessioncnt;	 // Backpointing sessions
    uint8 t_prbufsz;	 // SIGINFO buffer size
    string t_prbuf;	     // SIGINFO buffer
}*/

    function tty_rel_pgrp(s_tty tp, s_pgrp pgrp) internal {
        if (pgrp.pg_id == tp.t_pgrp.pg_id) {
            delete tp.t_pgrp;
        }
    }
    function tty_rel_sess(s_tty tp, s_session sess) internal {
        if (tp.t_sessioncnt > 0 && sess.s_sid == tp.t_session.s_sid) {
            delete tp.t_session;
            tp.t_sessioncnt--;
        }
    }
    function tty_rel_gone(s_tty tp) internal {
        delete tp.t_pgrp;
        delete tp.t_session;
    }
    function tty_makedevf(s_tty tp, s_ucred cred, uint32 flags, string fmt) internal returns (uint8) {}
    function tty_signal_sessleader(s_tty tp, uint8 signal) internal {}
    function tty_signal_pgrp(s_tty tp, uint8 signal) internal {}
    function tty_wait(s_tty tp, s_cv cv) internal returns (uint8) {}
    function tty_wait_background(s_tty tp, s_thread td, uint8 sig) internal returns (uint8) {}
    function tty_timedwait(s_tty tp, s_cv cv, uint8 timo) internal returns (uint8) {}
    function tty_wakeup(s_tty tp, uint32 flags) internal {}
    function tty_checkoutq(s_tty tp) internal returns (uint8) {}
    function tty_putchar(s_tty tp, byte c) internal returns (uint8) {}
    function tty_putstrn(s_tty tp, string p, uint8 n) internal returns (uint8) {}
    function tty_ioctl(s_tty tp, uint32 cmd, bytes data, uint32 fflag, s_thread td) internal returns (uint8) {}
    function tty_ioctl_compat(s_tty tp, uint32 cmd, uint32 data, uint32 fflag, s_thread td) internal returns (uint8) {}
    function tty_set_winsize(s_tty tp, s_winsize wsz) internal {
        tp.t_winsize = wsz;
    }
    function tty_init_console(s_tty tp, uint32 speed) internal {}
    function tty_flush(s_tty tp, uint32 flags) internal {}
    function tty_hiwat_in_block(s_tty tp) internal {}
    function tty_hiwat_in_unblock(s_tty tp) internal {}
    function tty_udev(s_tty tp) internal returns (uint16) {}
    function tty_info(s_tty tp) internal {}
    function ttyconsdev_select(string name) internal {}
    function pts_alloc(uint32 fflags, s_thread td, s_of fp) internal returns (uint8) {}
//    function pts_alloc_external(uint8 fd, s_thread td, s_of fp, s_cdev dev, string name) internal returns (uint8) {}

//#define	tty_makedev(tp, cred, fmt, ...) (void )tty_makedevf((tp), (cred), 0, (fmt), ## __VA_ARGS__)
//#define	tty_makealias(tp,fmt,...) make_dev_alias((tp)->t_dev, fmt, ## __VA_ARGS__)
}