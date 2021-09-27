pragma ton-solidity >= 0.49.0;

import "Pages.sol";

/* Session management commands manual */
contract PagesAdmin is Pages {

    function _init1() internal override view accept {
        _add_page("blkdiscard", "discard sectors on a device", "[options] [-o offset] [-l length] device",
            "Discard device sectors.",
            "olszv", 1, M, [
            "offset in bytes to discard from",
            "length of bytes to discard from the offset",
            "perform secure discard",
            "zero-fill rather than discard",
            "print aligned length and offset"]);
        _add_page("chfn", "change real user name and information", "[options] [LOGIN]",
            "Changes user fullname for a user account.",
            "f", 1, 2, [
            "change the user's full name"]);
        _add_page("findfs", "find a filesystem by label or UUID", "NAME=value",
            "Search the block devices in the system looking for a filesystem or partition with specified tag.",
            "", 1, M, [""]);
        _add_page("fsck", "check and repair a Tonix filesystem", "[-lsAVRTMNP] [-r [fd]] [-C [fd]] [-t fstype] [filesystem...]",
            "Check and optionally repair one or more Tonix filesystems.",
            "AlMNPRrsTV", 1, M, [
            "check all filesystems",
            "lock the device to guarantee exclusive access",
            "do not check mounted filesystems",
            "do not execute, just show what would be done",
            "check filesystems in parallel, including root",
            "skip root filesystem; useful only with '-A'",
            "report statistics for each device checked",
            "serialize the checking operations",
            "do not show the title on startup",
            "explain what is being done"]);
        _add_page("fstrim", "discard unused blocks on a mounted filesystem", "[-Aa] [-o offset] [-l length] [-v] mountpoint",
            "Used on a mounted filesystem to discard (or \"trim\") blocks which are not in use by the filesystem.",
            "aAolvn", 1, M, [
            "trim all supported mounted filesystems",
            "trim all supported mounted filesystems from /etc/fstab",
            "the offset in bytes to start discarding from",
            "the number of bytes to discard",
            "print number of discarded bytes",
            "does everything, but trim"]);
    }

    function init2() external override view accept {
        _add_page("gpasswd", "administer /etc/group and /etc/gshadow", "[option] group",
            "Administer /etc/group, and /etc/gshadow. Every group can have administrators, members and a password.",
            "adrRAM", 1, M, [
            "add the user to the named group",
            "remove the user from the named group",
            "remove the GROUP's password",
            "restrict access to GROUP to its members",
            "set the list of administrative users",
            "set the list of group members"]);
        _add_page("groupadd", "create a new group", "[options] group",
            "Creates a new group account using the default values from the system.",
            "fgr", 1, M, [
            "exit successfully if the group already exists, and cancel -g if the GID is already used",
            "use GID for the new group",
            "create a system group"]);
        _add_page("groupdel", "delete a group", "[options] GROUP",
            "Modifies the system account files, deleting all entries that refer to GROUP. The named group must exist.",
            "f", 1, 1, ["delete group even if it is the primary group of a user"]);
        _add_page("groupmod", "modify a group definition on the system", "[options] GROUP",
            "Modifies the definition of the specified GROUP by modifying the appropriate entry in the group database.",
            "gn", 1, M, [
            "the group ID of the given GROUP will be changed to GID",
            "the name of the group will be changed from GROUP to NEW_GROUP name"]);
        _add_page("losetup", "set up and control loop devices", "[options]... [loopdev]",
            "Associate loop devices with regular files or block devices, to detach loop devices, and to query the status of a loop device.",
            "adDfjLPrvln", 1, M, [
            "list all used devices",
            "detach one or more devices",
            "detach all used devices",
            "find first unused device",
            "list all devices associated with <file>",
            "avoid possible conflict between devices",
            "create a partitioned loop device",
            "set up a read-only loop device",
            "verbose mode",
            "list info about all or specified (default)",
            "don't print headings for --list output"]);
        _add_page("mkfs", "build a Tonix filesystem", "[options] [fs-options] device [size]",
            "Used to build a Tonix filesystem on a device.",
            "", 1, M, [""]);
       _add_page("mknod", "make block or character special files", "[OPTION]... NAME TYPE [MAJOR MINOR]",
            "Create the special file NAME of the given TYPE.",
            "m", 1, M, [
            "set file permission bits to MODE, not a=rw - umask"]);
        _add_page("mount", "mount a filesystem", "[-l]\t-a [-fnrvw]\t-[NTBM] <source> <directory>",
            "Attach the filesystem found on some device to the file tree",
            "acfTlnrvwNBM", 0, 3, [
            "mount all filesystems mentioned in fstab",
            "don't canonicalize paths",
            "dry run; skip the mount(2) syscall",
            "alternative file to /etc/fstab",
            "show also filesystem labels",
            "don't write to /etc/mtab",
            "mount the filesystem read-only",
            "say what is being done",
            "mount the filesystem read-write (default)",
            "perform mount in another namespace",
            "mount a subtree somewhere else",
            "move a subtree to some other place"]);
       _add_page("reboot", "reboot the machine", "[OPTIONS...]",
            "Reboot the machine.",
            "pfwd", 1, M, [
            "switch off the machine",
            "force immediate reboot",
            "don't halt/power-off/reboot, just write wtmp record",
            "don't write wtmp record"]);
    }

    function init3() external override view accept {
        _add_page("udevadm", "udev management tool", "info [options] [devpath]",
            "Expects a command and command specific options.",
            "", 1, M, [""]);
        _add_page("umount", "unmount file systems", "-a [-dflnrv] {directory|device}...",
            "Detaches the mentioned file system(s) from the file hierarchy.",
            "aAcdfnlRrvq", 1, M, [
            "unmount all filesystems",
            "unmount all mountpoints for the given device in the current namespace",
            "don't canonicalize paths",
            "if mounted loop device, also free this loop device",
            "force unmount (in case of an unreachable NFS system)",
            "don't write to /etc/mtab",
            "detach the filesystem now, clean up things later",
            "recursively unmount a target with all its children",
            "in case unmounting fails, try to remount read-only",
            "say what is being done",
            "suppress 'not mounted' error messages"]);
        _add_page("useradd", "create a new user or update default new user information", "[options] LOGIN",
            "A low level utility for adding users.",
            "gGlmMNrU", 1, M, [
            "name or ID of the primary group of the new account",
            "a list of supplementary groups which the user is also a member of",
            "do not add the user to the lastlog and faillog databases",
            "create the user's home directory",
            "do no create the user's home directory",
            "do not create a group with the same name as the user",
            "create a system account",
            "create a group with the same name as the user"]);
        _add_page("userdel", "delete a user account and related files", "[options] LOGIN",
            "A low level utility for removing users.",
            "fr", 1, 1, [
            "force removal of files, even if not owned by user",
            "remove the user's home directory"]);
        _add_page("usermod", "modify a user account", "[options] LOGIN",
            "Modifies the system account files to reflect the changes that are specified on the command line.",
            "agG", 1, M, [
            "add the user to the supplementary groups mentioned by the -G option",
            "force use GROUP as new primary group",
            "a list of supplementary groups separated from the next by a comma"]);
        _add_page("utmpdump", "dump UTMP and WTMP files in raw format", "[options] [filename]",
            "Dump UTMP and WTMP files in raw format, so they can be examined.",
            "ro", 1, 1, [
            "write back dumped data into utmp file",
            "write to file instead of standard output"]);
        _add_page("whereis", "locate the binary, source, and manual page files for a command", "[options] name...",
            "Locates the binary, source and manual files for the specified command names.",
            "bmsul", 1, M, [
            "search only for binaries",
            "search only for manuals and infos",
            "search only for sources",
            "search for unusual entries",
            "output effective lookup paths"]);
    }
}
