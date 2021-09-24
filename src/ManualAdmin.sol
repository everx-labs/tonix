pragma ton-solidity >= 0.49.0;

import "Manual.sol";

/* Session management commands manual */
contract ManualAdmin is Manual {

    function _init1() internal override accept {
        _add_page("chfn", "change real user name and information", "[options] [LOGIN]", "Changes user fullname for a user account.",
            "f", 1, 2, [
            "change the user's full name"]);
        _add_page("gpasswd", "administer /etc/group and /etc/gshadow", "[option] group", "administer /etc/group, and /etc/gshadow. Every group can have administrators, members and a password.",
            "adrRAM", 1, M, [
            "add the user to the named group",
            "remove the user from the named group",
            "remove the password from the named group. The group password will be empty. Only group members will be allowed to use newgrp tojoin the named group",
            "restrict the access to the named group. The group password is set to \"!\". Only group members with a password will be allowed to use newgrp to join the named group",
            "set the list of administrative users",
            "set the list of group members"]);
        /*_add_page("", "", "", "",
            "", 1, M, [
            "",
            "",
            "",
            ""]);*/
    }

    function init2() external override accept {
        _add_page("groupadd", "create a new group", "[options] group", "creates a new group account using the default values from the system.",
            "fgr", 1, M, [
            "exit with success status if the specified group already exists. When used with -g, and the specified GID already exists, another (unique) GID is chosen",
            "create a group with the specified numerical value. The default is to use the smallest ID value greater than or equal to GID_MIN and greater than every other group",
            "create a system group"]);
        _add_page("groupdel", "delete a group", "[options] GROUP", "modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
            "f", 1, 1, ["delete group even if it is the primary group of a user"]);
        _add_page("groupmod", "modify a group definition on the system", "[options] GROUP", "modifies the definition of the specified GROUP by modifying the appropriate entry in the group database.",
            "gn", 1, M, [
            "the group ID of the given GROUP will be changed to GID",
            "the name of the group will be changed from GROUP to NEW_GROUP name"]);
    }

    function init3() external override accept {
        _add_page("useradd", "create a new user or update default new user information", "[options] LOGIN", "low level utility for adding users",
            "gGlmMNrU", 1, M, [
            "the group name or number of the user's initial login group. The group name must exist. A group number must refer to an already existing group",
            "a list of supplementary groups which the user is also a member of",
            "do not add the user to the lastlog and faillog databases",
            "create the user's home directory if it does not exist. By default, if this option is not specified and CREATE_HOME is not enabled, no home directories are created",
            "do no create the user's home directory, even if the system wide setting from /etc/login.defs (CREATE_HOME) is set to yes",
            "do not create a group with the same name as the user, but add the user to the group specified by the -g option or by the GROUP variable in /etc/default/useradd",
            "create a system account",
            "create a group with the same name as the user, and add the user to this group"]);
        _add_page("userdel", "delete a user account and related files", "[options] LOGIN", "a low level utility for removing users",
            "fr", 1, 1, [
            "forces the removal of the user account, even if the user is still logged in. It also forces userdel to remove the user's home directory.  If USERGROUPS_ENAB is defined to yes in /etc/login.defs and if a group exists with the same name as the deleted user, then this group will be removed, even if it is still the primary group of another user",
            "files in the user's home directory will be removed along with the home directory itself"]);
        _add_page("usermod", "modify a user account", "[options] LOGIN", "modifies the system account files to reflect the changes that are specified on the command line.",
            "agG", 1, M, [
            "add the user to the supplementary group(s). Use only with the -G option",
            "the group name or number of the user's new initial login group. The group must exist",
            "a list of supplementary groups which the user is also a member of. Each group is separated from the next by a comma, with no intervening whitespace. The groups are subject to the same restrictions as the group given with the -g option"]);
        _write_export_sb();
    }
}
