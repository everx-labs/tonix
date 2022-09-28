pragma ton-solidity >= 0.64.0;

library libpoll {
    uint16 constant POLLIN      = 0x0001;  // any readable data available
    uint16 constant POLLPRI	    = 0x0002;  // OOB/Urgent readable data
    uint16 constant POLLOUT	    = 0x0004;  // file descriptor is writeable
    uint16 constant POLLRDNORM  = 0x0040;  // non-OOB/URG data available
    uint16 constant POLLWRNORM  = POLLOUT; // no write type differentiation
    uint16 constant POLLRDBAND  = 0x0080;  // OOB/Urgent readable data
    uint16 constant POLLWRBAND  = 0x0100;  // OOB/Urgent data can be written

    // General FreeBSD extension (currently only supported for sockets):
    uint16 constant POLLINIGNEOF = 0x2000; // like POLLIN, except ignore EOF
    uint16 constant POLLRDHUP    = 0x4000; // half shut down

    // These events are set if they occur regardless of whether they were requested.
    uint8 constant POLLERR	= 0x08; // some poll error occurred
    uint8 constant POLLHUP	= 0x10; // file descriptor was "hung up"
    uint8 constant POLLNVAL = 0x20; // requested events "invalid"

}