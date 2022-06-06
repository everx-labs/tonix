pragma ton-solidity >= 0.57.0;

import "pw.sol";

library adm {

    uint16 constant FAILLOG_ENAB    = 1;
    uint16 constant LOG_UNKFAIL_ENAB = 2;
    uint16 constant LOG_OK_LOGINS   = 3;
    uint16 constant SYSLOG_SU_ENAB  = 4;
    uint16 constant SYSLOG_SG_ENAB  = 5;
    uint16 constant SULOG_FILE      = 6;
    uint16 constant FTMP_FILE       = 7;
    uint16 constant SU_NAME         = 8;
    uint16 constant ENV_SUPATH      = 9;
    uint16 constant ENV_PATH        = 10;
    uint16 constant TTYGROUP        = 11;
    uint16 constant TTYPERM         = 12;
    uint16 constant UID_MIN         = 13; // Min/max values for automatic uid selection in useradd
    uint16 constant UID_MAX         = 14;
    uint16 constant SYS_UID_MIN     = 15;
    uint16 constant SYS_UID_MAX     = 16;
    uint16 constant GID_MIN         = 17; // Min/max values for automatic gid selection in groupadd
    uint16 constant GID_MAX         = 18;
    uint16 constant SYS_GID_MIN     = 19;
    uint16 constant SYS_GID_MAX     = 20;
    uint16 constant CHFN_RESTRICT   = 21;
    uint16 constant DEFAULT_HOME    = 22;
    uint16 constant USERGROUPS_ENAB = 23;
    uint16 constant CONSOLE_GROUPS  = 24;
    uint16 constant CREATE_HOME     = 25;

    function get_counters(string etc_passwd) internal returns (uint16 reg_users_counter, uint16 sys_users_counter, uint16 reg_groups_counter, uint16 sys_groups_counter) {
        uint16 uid_min = login_def_value(UID_MIN);
        uint16 sys_uid_min = login_def_value(SYS_UID_MIN);
        uint16 gid_min = login_def_value(GID_MIN);
        uint16 sys_gid_min = login_def_value(SYS_GID_MIN);

        reg_users_counter = uid_min;
        sys_users_counter = sys_uid_min;
        reg_groups_counter = gid_min;
        sys_groups_counter = sys_gid_min;

        (string[] lines, ) = libstring.split(etc_passwd, "\n");
        for (string line: lines) {
            (, uint16 user_id, uint16 group_id, , , ) = pw.parse_passwd_record(line).unpack();
            if (user_id >= uid_min)
                reg_users_counter = user_id + 1;
            else if (user_id >= sys_uid_min)
                sys_users_counter = user_id + 1;
            if (group_id >= gid_min)
                reg_groups_counter = group_id + 1;
            else if (group_id >= sys_gid_min)
                sys_groups_counter = group_id + 1;
        }
    }

    function login_def_flag(uint16 key) internal returns (bool) {
        mapping (uint16 => bool) login_defs_bool;

        login_defs_bool[FAILLOG_ENAB] = true;
        login_defs_bool[LOG_UNKFAIL_ENAB] = true;
        login_defs_bool[LOG_OK_LOGINS] = true;
        login_defs_bool[SYSLOG_SU_ENAB] = true;
        login_defs_bool[SYSLOG_SG_ENAB] = true;
        login_defs_bool[DEFAULT_HOME] = true;
        login_defs_bool[USERGROUPS_ENAB] = true;

        return login_defs_bool[key];
    }

    function login_def_value(uint16 key) internal returns (uint16) {
        mapping (uint16 => uint16) login_defs_uint16;

        login_defs_uint16[GID_MIN] = 1000; // Min/max values for automatic gid selection in groupadd
        login_defs_uint16[GID_MAX] = 20000;
        login_defs_uint16[SYS_GID_MIN] = 100;
        login_defs_uint16[SYS_GID_MAX] = 999;
        login_defs_uint16[UID_MIN] = 1000; // Min/max values for automatic gid selection in groupadd
        login_defs_uint16[UID_MAX] = 20000;
        login_defs_uint16[SYS_UID_MIN] = 100;
        login_defs_uint16[SYS_UID_MAX] = 999;
        login_defs_uint16[TTYPERM] = 384; // S_IRUSR + S_IWUSR;

        return login_defs_uint16[key];
    }

    function login_def_string(uint16 key) internal returns (string) {
        mapping (uint16 => string) login_defs_string;
        login_defs_string[SULOG_FILE] = "/var/log/sulog";
        login_defs_string[FTMP_FILE] = "/var/log/btmp";
        login_defs_string[SU_NAME] = "su";
        login_defs_string[ENV_SUPATH] = "PATH=/bin";
        login_defs_string[ENV_PATH] = "PATH=/bin";
        login_defs_string[TTYGROUP] = "tty";
        login_defs_string[CHFN_RESTRICT] = "rwh";
        login_defs_string[CONSOLE_GROUPS] = "floppy:audio:cdrom";

        return login_defs_string[key];
    }
}
