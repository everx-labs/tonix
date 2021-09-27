pragma ton-solidity >= 0.49.0;

import "Base.sol";

/* Commands and option flags constant definitions and helpers */
abstract contract Commands is Base {

    uint8 constant account  = 1;
    uint8 constant basename = 2;
    uint8 constant blkdiscard = 3;
    uint8 constant cat      = 4;
    uint8 constant cd       = 5;
    uint8 constant chfn     = 6;
    uint8 constant chgrp    = 7;
    uint8 constant chmod    = 8;
    uint8 constant chown    = 9;
    uint8 constant cksum    = 10;
    uint8 constant cmp      = 11;
    uint8 constant colrm    = 12;
    uint8 constant column   = 13;
    uint8 constant cp       = 14;
    uint8 constant cut      = 15;
    uint8 constant dd       = 16;
    uint8 constant df       = 17;
    uint8 constant dirname  = 18;
    uint8 constant du       = 19;
    uint8 constant echo     = 20;
    uint8 constant env      = 21;
    uint8 constant expand   = 22;
    uint8 constant fallocate = 23;
    uint8 constant file     = 24;
    uint8 constant findfs   = 25;
    uint8 constant findmnt  = 26;
    uint8 constant finger   = 27;
    uint8 constant fsck     = 28;
    uint8 constant fstrim   = 29;
    uint8 constant fuser    = 30;
    uint8 constant getent   = 31;
    uint8 constant getopt   = 32;
    uint8 constant gpasswd  = 33;
    uint8 constant grep     = 34;
    uint8 constant groupadd = 35;
    uint8 constant groupdel = 36;
    uint8 constant groupmod = 37;
    uint8 constant head     = 38;
    uint8 constant help     = 39;
    uint8 constant hostname = 40;
    uint8 constant id       = 41;
    uint8 constant last     = 42;
    uint8 constant ln       = 43;
    uint8 constant login    = 44;
    uint8 constant logout   = 45;
    uint8 constant look     = 46;
    uint8 constant losetup  = 47;
    uint8 constant ls       = 48;
    uint8 constant lsblk    = 49;
    uint8 constant lslogins = 50;
    uint8 constant lsof     = 51;
    uint8 constant man      = 52;
    uint8 constant mapfile  = 53;
    uint8 constant mkdir    = 54;
    uint8 constant mkfs     = 55;
    uint8 constant mknod    = 56;
    uint8 constant more     = 57;
    uint8 constant mount    = 58;
    uint8 constant mountpoint = 59;
    uint8 constant mv       = 60;
    uint8 constant namei    = 61;
    uint8 constant newgrp   = 62;
    uint8 constant paste    = 63;
    uint8 constant pathchk  = 64;
    uint8 constant ping     = 65;
    uint8 constant ps       = 66;
    uint8 constant pwd      = 67;
    uint8 constant readlink = 68;
    uint8 constant realpath = 69;
    uint8 constant reboot   = 70;
    uint8 constant rename   = 71;
    uint8 constant rev      = 72;
    uint8 constant rm       = 73;
    uint8 constant rmdir    = 74;
    uint8 constant script   = 75;
    uint8 constant stat     = 76;
    uint8 constant tail     = 77;
    uint8 constant tar      = 78;
    uint8 constant touch    = 79;
    uint8 constant tr       = 80;
    uint8 constant truncate = 81;
    uint8 constant udevadm  = 82;
    uint8 constant umount   = 83;
    uint8 constant uname    = 84;
    uint8 constant unexpand = 85;
    uint8 constant useradd  = 86;
    uint8 constant userdel  = 87;
    uint8 constant usermod  = 88;
    uint8 constant utmpdump = 89;
    uint8 constant wc       = 90;
    uint8 constant whatis   = 91;
    uint8 constant whereis  = 92;
    uint8 constant who      = 93;
    uint8 constant whoami   = 94;
    uint8 constant CMD_NAME_LAST = whoami;
    uint8 constant CMD_UNKNOWN = 255;

    uint16 constant M = 0xFFFF;

    uint16 constant ACT_NO_ACTION       = 0;
    uint16 constant ACT_PRINT_STATUS    = 1;
    uint16 constant ACT_FILE_OP         = 2;
    uint16 constant ACT_WRITE_FILES     = 3;
    uint16 constant ACT_PROCESS_COMMAND = 4;
    uint16 constant ACT_FORMAT_TEXT     = 5;
    uint16 constant ACT_DEVICE_STATUS   = 6;
    uint16 constant ACT_READ_INDEX      = 7;
    uint16 constant ACT_USER_ADMIN_OP   = 8;
    uint16 constant ACT_USER_STATS_OP   = 9;
    uint16 constant ACT_USER_ACCESS_OP  = 10;
    uint16 constant ACT_READ_PAGE       = 11;

    uint16 constant ACT_UPDATE_NODES    = 16;
    uint16 constant ACT_UPDATE_DEVICES  = 32;
    uint16 constant ACT_UPDATE_USERS    = 64;
    uint16 constant ACT_UPDATE_LOGINS   = 128;

    uint16 constant ACT_PIPE_OUT_TO_FILE = 512;

    uint16 constant ACT_PRINT_ERRORS    = 1024;
    uint16 constant ACT_IO_EVENT        = 2048;
    uint16 constant ACT_UA_EVENT        = 4096;

    uint8 constant ENOENT       = 1; // "No such file or directory" A component of pathname does not exist or is a dangling symbolic link; pathname is an empty string and AT_EMPTY_PATH was not specified in flags.
    uint8 constant EEXIST       = 2; // "File exists"
    uint8 constant ENOTDIR      = 3; //  "Not a directory" A component of the path prefix of pathname is not a directory.
    uint8 constant EISDIR       = 4; //"Is a directory"
    uint8 constant EACCES       = 5; // "Permission denied" Search permission is denied for one of the directories in the path prefix of pathname.  (See also path_resolution(7).)
    uint8 constant ENOTEMPTY    = 6; // "Directory not empty"
    uint8 constant EPERM        = 7; // "Not owner"
    uint8 constant EINVAL       = 8; //"Invalid argument"
    uint8 constant EROFS        = 9; //"Read-only file system"
    uint8 constant EFAULT       = 10; //Bad address.
    uint8 constant EBADF        = 11; // "Bad file number" fd is not a valid open file descriptor.
    uint8 constant EBUSY        = 12; // "Device busy"
    uint8 constant ENOSYS       = 13; // "Operation not applicable"
    uint8 constant ENAMETOOLONG = 14; // pathname is too long.

    uint8 constant ERR_MSG              = 0;
    uint8 constant invalid_option       = 7;
    uint8 constant extra_operand        = 8;
    uint8 constant missing_file_operand = 11;
    uint8 constant invalid_mode         = 15;
    uint8 constant invalid_owner        = 16;
    uint8 constant try_help_for_info    = 21;
    uint8 constant omitting_directory   = 23;
    uint8 constant cant_overwrite_dir   = 24;
    uint8 constant command_not_found    = 25;
    uint8 constant options_l_s_incompat = 26;
    uint8 constant ln_target            = 27;
    uint8 constant failed_symlink       = 28;
    uint8 constant failed_hardlink      = 29;
    uint8 constant hard_or_symlink      = 30;
    uint8 constant no_hardlink_on_dir   = 31;
    uint8 constant mutually_exclusive_options = 32;
    uint8 constant login_data_not_found = 33;
    uint8 constant not_a_block_device   = 34;

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
        return c == cat || c == colrm || c == column || c == cut || c == expand || c == grep || c == head || c == look
            || c == mapfile || c == more || c == paste || c == rev || c == tail || c == tr || c == unexpand || c == wc;
    }

    function _op_fs_status(uint8 c) internal pure returns (bool) {
        return c == cksum || c == du || c == file || c == ls || c == stat;
    }

    function _op_dev_stat(uint8 c) internal pure returns (bool) {
        return c == df || c == findmnt || c == lsblk || c == mountpoint || c == ps || c == utmpdump;
    }

    function _op_dev_admin(uint8 c) internal pure returns (bool) {
        return c == losetup || c == mknod || c == mount || c == udevadm || c == umount;
    }

    function _op_access(uint8 c) internal pure returns (bool) {
        return c == chgrp || c == chmod || c == chown;
    }

    function _op_file(uint8 c) internal pure returns (bool) {
        return c == cp || c == cmp || c == fallocate || c == ln || c == mkdir || c == mv || c == rm
            || c == rmdir || c == tar || c == touch || c == truncate;
    }

    function _op_session(uint8 c) internal pure returns (bool) {
        return c == cd || c == id || c == login || c == logout || c == last || c == pwd || c == script || c == who || c == whoami;
    }

    function _op_user_access(uint8 c) internal pure returns (bool) {
        return c == login || c == logout;
    }

    function _op_network(uint8 c) internal pure returns (bool) {
        return c == account || c == mount || c == ping;
    }

    function _op_user_admin(uint8 c) internal pure returns (bool) {
        return c == gpasswd || c == groupadd || c == groupdel || c == groupmod || c == useradd || c == userdel || c == usermod;
    }

    function _op_user_stats(uint8 c) internal pure returns (bool) {
        return c == finger || c == last || c == lslogins || c == utmpdump || c == who;
    }

    function _reads_file_fixed(uint8 c) internal pure returns (bool) {
        return c == help || c == man || c == whatis || c == whereis;
    }

}
