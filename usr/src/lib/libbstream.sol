pragma ton-solidity >= 0.62.0;

// A buffered stream.  Like a FILE *, but with our own buffering and synchronization
struct BSTREAM {
    uint8 b_fd;
    string b_buffer; // The buffer that holds characters read.
    uint16 b_size;   // How big the buffer is.
    uint16 b_used;   // How much of the buffer we're using,
    uint8 b_flag;    // Flag values.
    uint16 b_inputp; // The input pointer, index into b_buffer.
}

library libbstream {

    uint8 constant B_EOF     = 0x01;
    uint8 constant B_ERROR   = 0x02;
    uint8 constant B_UNBUFF  = 0x04;
    uint8 constant B_WASBASHINPUT = 0x08;
    uint8 constant B_TEXT    = 0x10;
    uint8 constant B_SHAREDBUF = 0x20;	// shared input buffer

    function make_buffered_stream (BSTREAM[] bs, uint8 fd, string buffer, uint16 bufsize) internal returns (BSTREAM b) {
        b = BSTREAM(fd, buffer, bufsize, uint16(buffer.byteLength()), 0, 0);
        bs.push(b);
    }


    function fd_to_buffered_stream (BSTREAM[] bs, uint8 fd) internal returns (BSTREAM) {

    }

    function set_buffered_stream (BSTREAM[] bs, uint8, BSTREAM) internal returns (BSTREAM) {

    }

    function open_buffered_stream (BSTREAM[] bs, string) internal returns (BSTREAM) {

    }

    function free_buffered_stream (BSTREAM[] bs, BSTREAM ) internal {

    }

    function close_buffered_stream (BSTREAM[] bs, BSTREAM ) internal returns (uint8) {

    }

}