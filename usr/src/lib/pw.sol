pragma ton-solidity >= 0.57.0;

import "er.sol";
import "libstring.sol";
struct s_passwd {
    string pw_name;
    uint16 pw_uid;
    uint16 pw_gid;
    string pw_gecos;
    string pw_dir;
    string pw_shell;
}

struct s_dbf {
    string name;
    string path;
    uint attr;
    string ls;
    string fs;
    uint8 n_fields;
    string format;
}

library pw {

    uint16 constant SUPER_USER  = 0;  // uid 0
    uint16 constant REG_USER    = 1000;
    uint16 constant GUEST_USER  = 10000;

    /*function get_dbf() internal returns (s_dbf) {
        return s_dbf("passwd", "/etc/passwd", 0, )
    }*/
    function parse_passwd_record(string line) internal returns (s_passwd) {
        (string[] fields, uint n_fields) = libstring.split(line, ":");
        if (n_fields > 6) {
            string pw_name = fields[0];
            uint16 pw_uid = str.toi(fields[2]);
            uint16 pw_gid = str.toi(fields[3]);
            string pw_gecos = fields[4];
            string pw_dir = fields[5];
            string pw_shell = fields[6];
            return s_passwd(pw_name, pw_uid, pw_gid, pw_gecos, pw_dir, pw_shell);
        }
    }

    function passwd_record(s_passwd record) internal returns (string) {
        (string pw_name, uint16 pw_uid, uint16 pw_gid, string pw_gecos, string pw_dir, string pw_shell) = record.unpack();
        return libstring.join_fields([pw_name, "x", str.toa(pw_uid), str.toa(pw_gid), pw_gecos, pw_dir, pw_shell], ":");
    }

    function putent(s_passwd p, string etc_passwd) internal returns (string) {
        (string cur_record, ) = getnam(p.pw_name, etc_passwd);
        string new_record = passwd_record(p);
        return cur_record.empty() ? (etc_passwd + new_record + "\n") : libstring.translate(etc_passwd, cur_record, new_record);
    }

    function getnam(string name, string etc_passwd) internal returns (string, s_passwd) {
        return getent(name + ":", etc_passwd);
    }

    function getgid(uint16 gid, string etc_passwd) internal returns (string, s_passwd) {
        return getent(":" + str.toa(gid) + ":", etc_passwd);
    }

    function getuid(uint16 uid, string etc_passwd) internal returns (string, s_passwd) {
        return getent(":" + str.toa(uid) + ":", etc_passwd);
    }

    function getent(string pattern, string file_contents) internal returns (string, s_passwd) {
        if (!file_contents.empty()) {
            (string[] lines, ) = libstring.split(file_contents, "\n");
            for (string line: lines)
                if (str.strstr(line, pattern) > 0)
                    return (line, parse_passwd_record(line));
        }
    }
}
