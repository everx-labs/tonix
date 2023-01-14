pragma ton-solidity >= 0.64.0;
struct s_sbuf {
    bytes buf;       // storage buffer
    uint8 error;     // current error code
    uint32 size;     // size of storage buffer
    uint16 len;      // current length of string
    uint32 flags;    // flags
    uint16 sect_len; // current length of section
    uint32 rec_off;  // current record start offset
}