pragma ton-solidity >= 0.51.0;

import "../include/Internal.sol";
//import "../lib/libpath.sol";
import "../lib/stdio.sol";

abstract contract libuadm is Internal {

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

    uint8 constant E_SUCCESS       = 0; // success
    uint8 constant E_USAGE         = 2; // invalid command syntax
    uint8 constant E_BAD_ARG       = 3; // invalid argument to option
    uint8 constant E_GID_IN_USE    = 4; // specified group doesn't exist <- copy/paste error
    uint8 constant E_NOTFOUND      = 6; // specified group doesn't exist
    uint8 constant E_NAME_IN_USE   = 9; // group name already in use
    uint8 constant E_GRP_UPDATE    = 10; // can't update group file
    uint8 constant E_CLEANUP_SERVICE = 11; // can't setup cleanup service
    uint8 constant E_PAM_USERNAME  = 12; // can't determine your username for use with pam
    uint8 constant E_PAM_ERROR     = 13; // pam returned an error, see syslog facility id groupmod for the PAM error message

    function _passwd_entry_line(string user_name, uint16 user_id, uint16 group_id, string group_name) internal pure returns (string) {
        return format("{}:x:{}:{}:{}:/home/{}:\n", user_name, user_id, group_id, group_name, user_name);
    }

    function _group_entry_line(string group_name, uint16 group_id) internal pure returns (string) {
        return format("{}:x:{}:\n", group_name, group_id);
    }

    function _parse_group_entry_line(string line) internal pure returns (string name, uint16 gid, string members) {
        (string[] fields, uint n_fields) = stdio.split(line, ":");
        if (n_fields > 2) {
            name = fields[0];
            gid = stdio.atoi(fields[2]);
            members = n_fields > 3 ? fields[3] : name;
        }
        if (gid == 0 && name != "root")
            gid = 10000;
    }

    function _user_groups(string user_name, string etc_group) internal pure returns (string primary, string[] supp) {
        (string[] lines, ) = stdio.split(etc_group, "\n");
        for (string line: lines) {
            (string group_name, , string member_list) = _parse_group_entry_line(line);
            if (user_name == group_name)
                primary = group_name;
            if (stdio.strstr(member_list, user_name) > 0)
                supp.push(group_name);
        }
    }

    function _login_def_flag(uint16 key) internal pure returns (bool) {
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

    function _login_def_value(uint16 key) internal pure returns (uint16) {
        mapping (uint16 => uint16) login_defs_uint16;

        login_defs_uint16[GID_MIN] = 1000; // Min/max values for automatic gid selection in groupadd
        login_defs_uint16[GID_MAX] = 20000;
        login_defs_uint16[SYS_GID_MIN] = 100;
        login_defs_uint16[SYS_GID_MAX] = 999;
        login_defs_uint16[UID_MIN] = 1000; // Min/max values for automatic gid selection in groupadd
        login_defs_uint16[UID_MAX] = 20000;
        login_defs_uint16[SYS_UID_MIN] = 100;
        login_defs_uint16[SYS_UID_MAX] = 999;
        login_defs_uint16[TTYPERM] = S_IRUSR + S_IWUSR;

        return login_defs_uint16[key];
    }

    function _login_def_string(uint16 key) internal pure returns (string) {
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

    function _get_file_info(uint16 index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (uint16 mode, uint16 owner_id, uint16 group_id, string owner_name, string group_name,
            uint32 modified_at, uint32 file_size) {
        if (inodes.exists(index)) {
            (mode, owner_id, group_id, , , , file_size, modified_at, , ) = inodes[index].unpack();
            owner_name = _get_user_name(owner_id, inodes, data);
            group_name = _get_group_name(group_id, inodes, data);
        }
    }

    function _get_counters(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (uint16 reg_users_counter, uint16 sys_users_counter, uint16 reg_groups_counter, uint16 sys_groups_counter) {
        mapping (uint16 => UserInfo) users = _get_login_info(inodes, data);
        mapping (uint16 => GroupInfo) groups = _get_group_info(inodes, data);
        uint16 uid_min = _login_def_value(UID_MIN);
        uint16 sys_uid_min = _login_def_value(SYS_UID_MIN);
        uint16 gid_min = _login_def_value(GID_MIN);
        uint16 sys_gid_min = _login_def_value(SYS_GID_MIN);

        reg_users_counter = uid_min;
        sys_users_counter = sys_uid_min;
        reg_groups_counter = gid_min;
        sys_groups_counter = sys_gid_min;

        for ((uint16 user_id, ): users) {
            if (user_id >= uid_min)
                reg_users_counter = user_id + 1;
            else if (user_id >= sys_uid_min)
                sys_users_counter = user_id + 1;
        }
        for ((uint16 group_id, ): groups) {
            if (group_id >= gid_min)
                reg_groups_counter = group_id + 1;
            else if (group_id >= sys_gid_min)
                sys_groups_counter = group_id + 1;
        }
    }

    function _get_user_name(uint16 uid, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        (string[] etc_passwd_contents, ) = stdio.split(_get_file_contents_at_path("/etc/passwd", inodes, data), "\n");
        string s_uid = stdio.itoa(uid);
        for (string s: etc_passwd_contents) {
            (string[] fields, uint n_fields) = stdio.split(s, ":");
            if (n_fields > 4)
                if (fields[2] == s_uid)
                    return fields[0];
        }
    }

    function _get_group_name(uint16 gid, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string) {
        (string[] etc_group_contents, ) = stdio.split(_get_file_contents_at_path("/etc/group", inodes, data), "\n");
        string s_gid = stdio.itoa(gid);
        for (string s: etc_group_contents) {
            (string[] fields, uint n_fields) = stdio.split(s, ":");
            if (n_fields > 2)
                if (fields[2] == s_gid)
                    return fields[0];
        }
    }

    /* User access helpers */
    function _get_login_info(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (mapping (uint16 => UserInfo) login_info) {
        (string[] etc_passwd_contents, ) = stdio.split(_get_file_contents_at_path("/etc/passwd", inodes, data), "\n");
        for (string s: etc_passwd_contents) {
            (string[] fields, uint n_fields) = stdio.split(s, ":");
            if (n_fields > 4) {
                optional(int) res = stoi(fields[2]);
                uint16 uid = res.hasValue() ? uint16(res.get()) : 10000;//GUEST_USER;
                res = stoi(fields[3]);
                login_info[uid] = UserInfo(res.hasValue() ? uint16(res.get()) : 10000, fields[0], fields.length > 4 ? fields[4] : "guest");
            }
        }
    }

    function _get_group_info(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (mapping (uint16 => GroupInfo) group_info) {
        (string[] etc_group_contents, ) = stdio.split(_get_file_contents_at_path("/etc/group", inodes, data), "\n");
        for (string s: etc_group_contents) {
            (string[] fields, uint n_fields) = stdio.split(s, ":");
            if (n_fields > 2) {
                optional(int) res = stoi(fields[2]);
                uint16 gid = res.hasValue() ? uint16(res.get()) : 10000;
                group_info[gid] = GroupInfo(fields[0], gid < 1000);
            }
        }
    }

}