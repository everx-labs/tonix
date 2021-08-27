pragma ton-solidity >= 0.49.0;

import "Base.sol";

abstract contract Commands is Base {

    uint8 constant account  = 1;
    uint8 constant basename = 2;
    uint8 constant cat      = 3;
    uint8 constant cd       = 4;
    uint8 constant chgrp    = 5;
    uint8 constant chmod    = 6;
    uint8 constant chown    = 7;
    uint8 constant cksum    = 8;
    uint8 constant cmp      = 9;
    uint8 constant column   = 10;
    uint8 constant cp       = 11;
    uint8 constant cut      = 12;
    uint8 constant dd       = 13;
    uint8 constant df       = 14;
    uint8 constant dirname  = 15;
    uint8 constant du       = 16;
    uint8 constant echo     = 17;
    uint8 constant file     = 18;
    uint8 constant findmnt  = 19;
    uint8 constant grep     = 20;
    uint8 constant help     = 21;
    uint8 constant id       = 22;
    uint8 constant ln       = 23;
    uint8 constant ls       = 24;
    uint8 constant lsblk    = 25;
    uint8 constant man      = 26;
    uint8 constant mkdir    = 27;
    uint8 constant mount    = 28;
    uint8 constant mv       = 29;
    uint8 constant paste    = 30;
    uint8 constant ping     = 31;
    uint8 constant pwd      = 32;
    uint8 constant rm       = 33;
    uint8 constant rmdir    = 34;
    uint8 constant stat     = 35;
    uint8 constant touch    = 36;
    uint8 constant uname    = 37;
    uint8 constant wc       = 38;
    uint8 constant whoami   = 39;

    uint8 constant CMD_NAME_LAST = whoami;
    uint8 constant CMD_UNKNOWN = 255;

    uint16 constant M = 0xFFFF;

    uint16 constant NO_ACTION       = 0;
    uint16 constant PRINT_STATUS    = 1;
    uint16 constant PROCESS_COMMAND = 2;
    uint16 constant ADD_NODES       = 4;
    uint16 constant UPDATE_NODES    = 8;
    uint16 constant IO_EVENT        = 128;
    uint16 constant CHECK_STATUS    = 512;
    uint16 constant OPEN_DIR        = 2048;
    uint16 constant CHANGE_DIR      = 4096;
    uint16 constant PIPE_OUT_TO_FILE= 8192;
    uint16 constant MOUNT_FS        = 16384;
    uint16 constant OPEN_FILE       = 32768;

    function _is_pure(uint8 c) internal pure returns (bool) {
        return c == basename || c == dirname || c == echo || c == uname;
    }

    function _op_stat(uint8 c) internal pure returns (bool) {
        return c == cat || c == cksum || c == du || c == file || c == ls || c == paste || c == stat || c == wc;
    }

    function _op_dev_stat(uint8 c) internal pure returns (bool) {
        return c == df || c == findmnt || c == lsblk;
    }

    function _op_access(uint8 c) internal pure returns (bool) {
        return c == chgrp || c == chmod || c == chown;
    }

    function _op_file(uint8 c) internal pure returns (bool) {
        return c == cp || c == ln || c == mkdir || c == mv || c == rm || c == rmdir || c == touch;
    }

    function _op_session(uint8 c) internal pure returns (bool) {
        return c == cd || c == id || c == pwd || c == whoami;
    }

    function _op_network(uint8 c) internal pure returns (bool) {
        return c == account || c == mount || c == ping;
    }

    function _op_file_read(uint8 c) internal pure returns (bool) {
        return c == cat || c == cmp || c == column || c == cut || c == grep || c == paste || c == wc;
    }

    function _reads_file_fixed(uint8 c) internal pure returns (bool) {
        return c == help || c == man;
    }

    function _log2(uint n) internal pure returns (uint res) {
        while (n > 0) {
            n >>= 1;
            res++;
        }
    }

    function _hob(uint n) internal pure returns (uint) {
        n |= (n >> 1);
        n |= (n >> 2);
        n |= (n >> 4);
        n |= (n >> 8);
        n |= (n >> 16);
        n |= (n >> 32);
        n |= (n >> 64);
        n |= (n >> 128);
        return n - (n >> 1);
    }

}
