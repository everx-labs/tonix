pragma ton-solidity >= 0.49.0;

import "Base.sol";

/* Commands and option flags constant definitions and helpers */
abstract contract Commands is Base {

    uint8 constant account  = 1;
    uint8 constant basename = 2;
    uint8 constant cat      = 3;
    uint8 constant cd       = 4;
    uint8 constant chfn     = 5;
    uint8 constant chgrp    = 6;
    uint8 constant chmod    = 7;
    uint8 constant chown    = 8;
    uint8 constant cksum    = 9;
    uint8 constant cmp      = 10;
    uint8 constant column   = 11;
    uint8 constant cp       = 12;
    uint8 constant cut      = 13;
    uint8 constant dd       = 14;
    uint8 constant df       = 15;
    uint8 constant dirname  = 16;
    uint8 constant du       = 17;
    uint8 constant echo     = 18;
    uint8 constant fallocate = 19;
    uint8 constant file     = 20;
    uint8 constant findmnt  = 21;
    uint8 constant finger   = 22;
    uint8 constant fuser    = 23;
    uint8 constant getent   = 24;
    uint8 constant groupadd = 25;
    uint8 constant groupdel = 26;
    uint8 constant groupmod = 27;
    uint8 constant gpasswd  = 28;
    uint8 constant grep     = 29;
    uint8 constant head     = 30;
    uint8 constant help     = 31;
    uint8 constant hostname = 32;
    uint8 constant id       = 33;
    uint8 constant ln       = 34;
    uint8 constant last     = 35;
    uint8 constant login    = 36;
    uint8 constant logout   = 37;
    uint8 constant losetup  = 38;
    uint8 constant look     = 39;
    uint8 constant ls       = 40;
    uint8 constant lsblk    = 41;
    uint8 constant lslogins = 42;
    uint8 constant lsof     = 43;
    uint8 constant man      = 44;
    uint8 constant mapfile  = 45;
    uint8 constant mkdir    = 46;
    uint8 constant mknod    = 47;
    uint8 constant mount    = 48;
    uint8 constant mv       = 49;
    uint8 constant namei    = 50;
    uint8 constant newgrp   = 51;
    uint8 constant paste    = 52;
    uint8 constant pathchk  = 53;
    uint8 constant ping     = 54;
    uint8 constant ps       = 55;
    uint8 constant pwd      = 56;
    uint8 constant readlink = 57;
    uint8 constant realpath = 58;
    uint8 constant rm       = 59;
    uint8 constant rmdir    = 60;
    uint8 constant script   = 61;
    uint8 constant stat     = 62;
    uint8 constant tail     = 63;
    uint8 constant tar      = 64;
    uint8 constant touch    = 65;
    uint8 constant truncate = 66;
    uint8 constant udevadm  = 67;
    uint8 constant umount   = 68;
    uint8 constant uname    = 69;
    uint8 constant useradd  = 70;
    uint8 constant userdel  = 71;
    uint8 constant usermod  = 72;
    uint8 constant utmpdump = 73;
    uint8 constant wc       = 74;
    uint8 constant whatis   = 75;
    uint8 constant whereis  = 76;
    uint8 constant who      = 77;
    uint8 constant whoami   = 78;
    uint8 constant CMD_NAME_LAST = whoami;
    uint8 constant CMD_UNKNOWN = 255;

    uint16 constant M = 0xFFFF;

    uint16 constant NO_ACTION       = 0;
    uint16 constant PRINT_STATUS    = 1;
    uint16 constant FILE_OP         = 2;
    uint16 constant WRITE_FILES     = 4;
    uint16 constant UPDATE_NODES    = 8;
    uint16 constant PROCESS_COMMAND = 16;
    uint16 constant FORMAT_TEXT     = 32;
    uint16 constant PRINT_ERRORS    = 64;
    uint16 constant IO_EVENT        = 128;
    uint16 constant READ_INDEX      = 256;
    uint16 constant CHECK_STATUS    = 512;
    uint16 constant DEVICE_STATUS   = 1024;
    uint16 constant UPDATE_DEVICES  = 2048;
    uint16 constant CHANGE_DIR      = 4096;
    uint16 constant PIPE_OUT_TO_FILE = 8192;
    uint16 constant MOUNT_FS        = 16384;
    uint16 constant OPEN_FILE       = 32768;

    uint constant _0 = 1 << 48;
    uint constant _1 = 1 << 49;
    uint constant _2 = 1 << 50;
    uint constant _3 = 1 << 51;
    uint constant _4 = 1 << 52;
    uint constant _5 = 1 << 53;
    uint constant _6 = 1 << 54;
    uint constant _7 = 1 << 55;
    uint constant _8 = 1 << 56;
    uint constant _9 = 1 << 57;

    uint constant _A = 1 << 65;
    uint constant _B = 1 << 66;
    uint constant _C = 1 << 67;
    uint constant _D = 1 << 68;
    uint constant _E = 1 << 69;
    uint constant _F = 1 << 70;
    uint constant _G = 1 << 71;
    uint constant _H = 1 << 72;
    uint constant _I = 1 << 73;
    uint constant _J = 1 << 74;
    uint constant _K = 1 << 75;
    uint constant _L = 1 << 76;
    uint constant _M = 1 << 77;
    uint constant _N = 1 << 78;
    uint constant _O = 1 << 79;
    uint constant _P = 1 << 80;
    uint constant _Q = 1 << 81;
    uint constant _R = 1 << 82;
    uint constant _S = 1 << 83;
    uint constant _T = 1 << 84;
    uint constant _U = 1 << 85;
    uint constant _V = 1 << 86;
    uint constant _W = 1 << 87;
    uint constant _X = 1 << 88;
    uint constant _Y = 1 << 89;
    uint constant _Z = 1 << 90;

    uint constant _a = 1 << 97;
    uint constant _b = 1 << 98;
    uint constant _c = 1 << 99;
    uint constant _d = 1 << 100;
    uint constant _e = 1 << 101;
    uint constant _f = 1 << 102;
    uint constant _g = 1 << 103;
    uint constant _h = 1 << 104;
    uint constant _i = 1 << 105;
    uint constant _j = 1 << 106;
    uint constant _k = 1 << 107;
    uint constant _l = 1 << 108;
    uint constant _m = 1 << 109;
    uint constant _n = 1 << 110;
    uint constant _o = 1 << 111;
    uint constant _p = 1 << 112;
    uint constant _q = 1 << 113;
    uint constant _r = 1 << 114;
    uint constant _s = 1 << 115;
    uint constant _t = 1 << 116;
    uint constant _u = 1 << 117;
    uint constant _v = 1 << 118;
    uint constant _w = 1 << 119;
    uint constant _x = 1 << 120;
    uint constant _y = 1 << 121;
    uint constant _z = 1 << 122;

    function _is_pure(uint8 c) internal pure returns (bool) {
        return c == basename || c == dirname || c == echo || c == pathchk || c == uname;
    }

    function _op_stat(uint8 c) internal pure returns (bool) {
        return c == cksum || c == du || c == file || c == ls || c == namei || c == stat;
    }

    function _op_format(uint8 c) internal pure returns (bool) {
        return c == cat || c == column || c == cut || c == grep || c == head || c == mapfile || c == paste || c == tail || c == wc;
    }

    function _op_fs_status(uint8 c) internal pure returns (bool) {
        return c == cksum || c == du || c == file || c == ls || c == stat;
    }

    function _op_dev_stat(uint8 c) internal pure returns (bool) {
        return c == df || c == findmnt || c == lsblk || c == ps || c == utmpdump;
    }

    function _op_dev_admin(uint8 c) internal pure returns (bool) {
        return c == losetup || c == mknod || c == mount || c == udevadm || c == umount;
    }

    function _op_access(uint8 c) internal pure returns (bool) {
        return c == chgrp || c == chmod || c == chown;
    }

    function _op_file(uint8 c) internal pure returns (bool) {
        return c == cp || c == cmp || c == fallocate || c == ln || c == mkdir || c == mv || c == rm || c == rmdir || c == tar || c == touch || c == truncate;
    }

    function _op_session(uint8 c) internal pure returns (bool) {
        return c == cd || c == id || c == login || c == logout || c == last || c == pwd || c == script || c == who || c == whoami;
    }

    function _op_network(uint8 c) internal pure returns (bool) {
        return c == account || c == mount || c == ping;
    }

    function _op_user_admin(uint8 c) internal pure returns (bool) {
        return c == gpasswd || c == groupadd || c == groupdel || c == groupmod || c == useradd || c == userdel || c == usermod;
    }

    function _reads_file_fixed(uint8 c) internal pure returns (bool) {
        return c == help || c == lslogins || c == man || c == whatis || c == whereis;
    }

}
