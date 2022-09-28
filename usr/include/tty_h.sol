pragma ton-solidity >= 0.62.0;

import "cv_h.sol";
import "select_h.sol";
import "signal_h.sol";
import "proc_h.sol";
struct s_ttyinq {
    string[] ti_blocks;
    string ti_firstblock;
    string ti_startblock;
    string ti_reprintblock;
    string ti_lastblock;
    uint8 ti_begin;
    uint8 ti_linestart;
    uint8 ti_reprint;
    uint8 ti_end;
    uint8 ti_nblocks;
    uint8 ti_quota;
}
struct s_ttyoutq {
    string[] to_blocks;
    string to_firstblock;
    string to_lastblock;
    uint8 to_begin;
    uint8 to_end;
    uint8 to_nblocks;
    uint8 to_quota;
}

struct s_tty {
    uint32 t_flags;     // Terminal option flags
    uint8 t_revokecnt;  // revoke() count
    s_ttyinq t_inq;     // Input queue
    uint8 t_inlow;      // Input low watermark
    s_ttyoutq t_outq;   // Output queue
    uint8 t_outlow;     // Output low watermark
    s_cv t_inwait;      // Input wait queue
    s_cv t_outwait;     // Output wait queue
    s_cv t_outserwait;  // Serial output wait queue
    s_cv t_bgwait;      // Background wait queue
    s_cv t_dcdwait;     // Carrier Detect wait queue
    s_selinfo t_inpoll; // Input poll queue
    s_selinfo t_outpoll;// Output poll queue
    s_sigio t_sigio;    // Asynchronous I/O
    s_winsize t_winsize;// Window size
    uint8 t_column;     // Current cursor position
    uint8 t_writepos;   // Where input was interrupted
    uint32 t_compatflags;// COMPAT_43TTY flags
    s_pgrp t_pgrp;      // Foreground process group
    s_session t_session;// Associated session
    uint8 t_sessioncnt; // Backpointing sessions
    uint8 t_prbufsz;    // SIGINFO buffer size
    string t_prbuf;     // SIGINFO buffer
}

struct s_xtty {
    uint8 xt_size;    // Structure size
    uint8 xt_insize;  // Input queue size
    uint8 xt_incc;    // Canonicalized characters
    uint8 xt_inlc;    // Input line charaters
    uint8 xt_inlow;   // Input low watermark
    uint8 xt_outsize; // Output queue size
    uint8 xt_outcc;   // Output queue usage
    uint8 xt_outlow;  // Output low watermark
    uint8 xt_column;  // Current column position
    uint16 xt_pgid;   // Foreground process group
    uint16 xt_sid;    // Session
    uint32 xt_flags;  // Terminal option flags
    uint32 xt_dev;    // Userland device. XXXKIB truncate
}

// Window/terminal size structure.  This information is stored by the kernel
// in order to provide a consistent interface, but is not used by the kernel.
struct s_winsize {
    uint16 ws_row;    // rows, in characters
    uint16 ws_col;    // columns, in characters
    uint16 ws_xpixel; // horizontal size, pixels
    uint16 ws_ypixel; // vertical size, pixels
}
