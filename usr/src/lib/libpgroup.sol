pragma ton-solidity >= 0.62.0;

import "proc_h.sol";

struct s_xsession {
    uint16 s_count;      // Ref cnt; pgrps in session - atomic.
    s_proc s_leader;     // Session leader.
    uint16 k_ttyp;        // Controlling tty.
    uint16 s_sid;        // Session ID.
    string s_login;      // Setlogin() name:
}
struct s_xpgrp {
    s_proc[] pg_members;   // Pointer to pgrp members.
    s_xsession pg_session;  // Pointer to session.
    uint16 pg_id;          // Process group id.
    uint16 pg_flags;       // PGRP_ flags
}

library libpgroup {

    function leader(s_xpgrp pg) internal returns (s_proc) {
        return pg.pg_session.s_leader;
    }

    function name(s_xpgrp pg) internal returns (string) {
        return pg.pg_session.s_login;
    }
}