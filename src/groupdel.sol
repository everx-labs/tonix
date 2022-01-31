pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract groupdel is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (, string[] params, string flags, ) = arg.get_env(args);

        string victim_group_name;
        if (params.length == 1)
            victim_group_name = params[0];
//        else
            // print usage

        (string etc_passwd, string etc_group, , uint16 etc_group_index) = fs.get_passwd_group(inodes, data);
        string victim_entry = uadmin.group_entry_by_name(victim_group_name, etc_group);
        if (victim_entry.empty())
            errors.push(Err(uadmin.E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist

        (, uint16 victim_group_id, ) = uadmin.parse_group_entry_line(victim_entry);
        string active_uid_entry = uadmin.passwd_entry_by_primary_gid(victim_group_id, etc_passwd);
        if (!active_uid_entry.empty()) {
            (string user_name, , , , ) = uadmin.parse_passwd_entry_line(active_uid_entry);
            errors.push(Err(8, 0, user_name)); // can't remove user's primary group
        }

        if (errors.empty())
            ars.push(Ar(IO_UPDATE_TEXT_DATA, FT_REG_FILE, etc_group_index, 0, "group", stdio.translate(etc_group, victim_entry + "\n", "")));
        else
            ec = EXECUTE_FAILURE;
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"groupdel",
"[options] GROUP",
"delete a group",
"Modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
"-f     delete group even if it is the primary group of a user",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
