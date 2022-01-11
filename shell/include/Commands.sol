pragma ton-solidity >= 0.51.0;

    struct CmdInfoS {
        uint8 min_args;
        uint16 max_args;
        uint options;
        string name;
    }

/* Commands and option flags constant definitions and helpers */
abstract contract Commands {

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
    uint16 constant ACT_FILE_ACTION     = 12;
    uint16 constant ACT_RUN_SESSION     = 13;
    uint16 constant ACT_PARSE_INPUT     = 14;
    uint16 constant ACT_GET_OPTIONS     = 15;
    uint16 constant ACT_PRINT_USAGE     = 16;
    uint16 constant ACT_PRINT_VERSION   = 17;
    uint16 constant ACT_COMMAND_INFO    = 18;
    uint16 constant ACT_MAKE_FS         = 19;
    uint16 constant ACT_READ_FS         = 20;
    uint16 constant ACT_ALTER_FS        = 21;
    uint16 constant ACT_UPLOAD          = 22;
    uint16 constant ACT_DOWNLOAD        = 23;
    uint16 constant ACT_SHELL           = 24;

    uint16 constant ACT_UPDATE_NODES    = 32;
    uint16 constant ACT_UPDATE_DEVICES  = 64;
    uint16 constant ACT_UPDATE_LOGINS   = 128;
    uint16 constant ACT_HANDLE_ACTION   = 256;

    uint16 constant ACT_PIPE_OUT_TO_FILE = 512;

    uint16 constant ACT_PRINT_ERRORS    = 1024;
    uint16 constant ACT_IO_EVENT        = 2048;
    uint16 constant ACT_UA_EVENT        = 4096;

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
        return c == cp || c == cmp || c == dd || c == fallocate || c == ln || c == mkdir || c == mv || c == rm
            || c == rmdir || c == tar || c == touch || c == truncate;
    }

    function _op_file_action(uint8 c) internal pure returns (bool) {
        return c == cp || /*c == cmp || c == dd || */c == fallocate || c == ln || c == mkdir || c == mv || c == rm
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
