pragma ton-solidity >= 0.62.0;

struct s_sockaddr {
    uint8 sa_family;
    string sa_data;
}
struct s_sockaddr_in {
    uint8 sin_family;
    uint16 sin_port;
    uint sin_addr;
}

struct s_xsockbuf {
    uint32 sb_cc;
    uint32 sb_hiwat;
    uint32 sb_mbcnt;
    uint32 sb_mcnt;
    uint32 sb_ccnt;
    uint32 sb_mbmax;
    int32 sb_lowat;
    int32 sb_timeo;
    int16 sb_flags;
}
//  Structure to export socket from kernel to utilities, via sysctl(3).
struct s_xsocket {
//    ksize xso_len; // length of this structure
    uint16 xso_so;   // kernel address of struct socket
    uint16 so_pcb;   // kernel address of struct inpcb
    uint64 so_oobmark;
    int32  xso_protocol;
    int32  xso_family;
    uint32 so_qlen;
    uint32 so_incqlen;
    uint32 so_qlimit;
    uint16 so_pgid;
    uint16 so_uid;
    int16 so_type;
    int16 so_options;
    int16 so_linger;
    int16 so_state;
    int16 so_timeo;
    uint16 so_error;
    s_xsockbuf so_rcv;
    s_xsockbuf so_snd;
}
