pragma ton-solidity >= 0.58.0;

import "er.sol";

struct s_group {
    string gr_name;
    uint16 gr_gid;
    string[] gr_mem;
}

library gr {

    using libstring for string;

    uint16 constant SUPER_USER_GROUP = 0;
    uint16 constant REG_USER_GROUP = 1000;

    function group_record(s_group record) internal returns (string) {
        (string gr_name, uint16 gr_gid, string[] members) = record.unpack();
        return libstring.join_fields([gr_name, "*", str.toa(gr_gid), libstring.join_fields(members, ",")], ":");
    }

    function parse_group_record(string line) internal returns (s_group) {
        (string[] fields, uint n_fields) = line.split(":");
        if (n_fields > 2) {
            string gr_name = fields[0];
            uint16 gr_gid = str.toi(fields[2]);
            string[] gr_mem;
            if (n_fields > 3) {
                string members = fields[3];
                if (!members.empty())
                    (gr_mem, ) = members.split(",");
            }
            return s_group(gr_name, gr_gid, gr_mem);
        }
    }

    function getnam(string name, string etc_group) internal returns (string, s_group) {
        return getent(name + ":", etc_group);
    }

    function getgid(uint16 gid, string etc_group) internal returns (string, s_group) {
        return getent(":" + str.toa(gid) + ":", etc_group);
    }

    function putent(s_group grp, string etc_group) internal returns (string) {
        (string cur_record, ) = getnam(grp.gr_name, etc_group);
        string new_record = group_record(grp);
        return cur_record.empty() ? etc_group + new_record + "\n" : libstring.translate(etc_group, cur_record, new_record);
    }

    function getent(string pattern, string file_contents) internal returns (string, s_group) {
        if (!file_contents.empty()) {
            (string[] lines, ) = file_contents.split("\n");
            for (string line: lines)
                if (str.strstr(line, pattern) > 0)
                    return (line, parse_group_record(line));
        }
    }

    function initgroups(string user, uint16 group_id, string etc_group) internal returns (string primary, string[] supp) {
        (string[] lines, ) = etc_group.split("\n");
        for (string line: lines) {
            s_group cur_grp = parse_group_record(line);
            (string gr_name, uint16 gr_gid, string[] gr_mem) = cur_grp.unpack();
            if (gr_gid == group_id)
                primary = gr_name;
            for (string member: gr_mem) {
                if (user == member)
                    supp.push(gr_name);
            }
        }
    }
}
