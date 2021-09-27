pragma ton-solidity >= 0.49.0;

import "ExportFS.sol";

/* Primary configuration files for a block device system initialization and error diagnostic data */
contract DataVolume is ExportFS {

    function _add_data_file(string name, string[] contents) internal {
        uint16 counter = _export_fs.ic++;
        _export_fs.inodes[counter] = _get_any_node(FT_REG_FILE, SUPER_USER, SUPER_USER_GROUP, name, contents);
    }

    function _init() internal override accept {
        _export_fs = _get_fs(1, "exportfs", ["errors", "etc"]);
        /* Exported to /usr */
        _add_data_file("reasons", [
            "missing operand",
            "cannot remove",
            "cannot stat",
            "cannot access",
            "cannot create directory",
            "cannot open",
            "invalid option",
            "extra operand",
            "failed to remove",
            "missing operand after",
            "missing file operand",
            "missing destination file operand after",
            "invalid group",
            "missing filename",
            "invalid mode",
            "invalid owner",
            "cannot touch",
            "cannot create regular file",
            "too many arguments",
            "too many operands",
            "Try '--help' for more information",
            "failed to access",
            "-r not specified; omitting directory",
            "cannot overwrite directory with non-directory",
            "command not found",
            "options -l and -s are incompatible",
            "target",
            "failed to create symbolic link",
            "failed to create hard link",
            "cannot make both hard and symbolic links",
            "hard link not allowed for directory",
            "mutually exclusive arguments: -c -n -r -z",
            "failed to locate login data",
            "not a block device"]);
        _add_data_file("status", [
            "No such file or directory",
            "File exists",
            "Not a directory",
            "Is a directory",
            "Permission denied",
            "Directory not empty",
            "Not owner",
            "Invalid argument",
            "Read-only file system",
            "Bad address",
            "Bad file number",
            "fd is not a valid open file descriptor",
            "Device busy", "Operation not applicable",
            "pathname is too long"]);
        _add_data_file("internal", [
            "direntry not found",
            "inode not found",
            "parent direntry not found",
            "child direntry not found",
            "invalid user id",
            "invalid working directory"]);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 3, 3, "/usr"));

        this.init2();
    }

    function init2() external accept {
        /* Exported to /etc */
        _add_data_file("command_list", [
            "account", "basename", "blkdiscard", "cat", "cd", "chfn", "chgrp", "chmod", "chown","cksum", "cmp", "colrm", "column", "cp", "cut",
            "dd", "df", "dirname", "du", "echo", "env", "expand", "fallocate", "file", "findfs", "findmnt", "finger", "fsck", "fstrim", "fuser",
            "getent", "getopt", "gpasswd", "grep", "groupadd", "groupdel", "groupmod", "head", "help", "hostname", "id", "last", "ln", "login",
            "logout", "look", "losetup", "ls", "lsblk", "lslogins", "lsof", "man", "mapfile", "mkdir", "mkfs", "mknod", "more", "mount", "mountpoint",
            "mv", "namei", "newgrp", "paste", "pathchk", "ping", "ps", "pwd", "readlink", "realpath", "reboot", "rename", "rev", "rm", "rmdir",
            "script", "stat", "tail", "tar", "touch", "tr", "truncate", "udevadm", "umount", "uname", "unexpand", "useradd", "userdel", "usermod",
            "utmpdump", "wc", "whatis", "whereis", "who", "whoami"]);
        _add_data_file("exports", [
            "BlockDevice\t/\t0\t1",
            "DataVolume\t/etc\t3\t2",
            "DataVolume\t/usr\t8\t1",
            "DeviceManager\t/sys/dev/block\t13\t1",
            "DeviceManager\t/sys/dev/char\t14\t2",
            "ManualCommands\t/bin\t1\t1",
            "ManualStatus\t/bin\t1\t1",
            "ManualSession\t/bin\t1\t1",
            "ManualUtility\t/bin\t1\t1"]);
        _add_data_file("fstab", [
            "/etc\tDataVolume\t1\t3\t2",
            "/usr\tDataVolume\t1\t8\t1",
            "/sys/dev/block\tDeviceManager\t1\t13\t1",
            "/sys/dev/char\tDeviceManager\t1\t14\t2"]);
        _add_data_file("fs_types", [
            "?unknown",
            "-regular file",
            "ddirectory",
            "ccharacter special file",
            "bblock special file",
            "pfifo",
            "ssocket",
            "lsymbolic link"]);
        _add_data_file("group", [
            "root\t0",
            "staff\t1000",
            "guest\t10000"]);
        _add_data_file("hostname", [
            "BlockDevice",
            "0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5"]);
        _add_data_file("hosts", [
            "0:47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40\tFileManager",
            "0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9\tStatusReader",
            "0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume",
            "0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice",
            "0:4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d\tSessionManager",
            "0:48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec\tPrintFormatted",
            "0:430dd570de5398dbc2319979f5ba4aa99d5254e5382d3c344b985733d141617b\tDeviceManager",
            "0:4a7cd37ce66473c7b383a245891502e5d05c626a69ca764165e2c7d6edd9e317\tAccessManager",
            "0:cc59225a037b56f2cc325c9ced611994e160c4485537fe01ab3787e5d92ddac3\tManualPages",
            "0:9bc7fdbdadc754e31918f29c22af4a949787e22e84052d94c05e23e9d6e74099\tPagesStatus",
            "0:5838d84e0998f90b98c6a8fa7e6727b9dc7fb7a1f686631bf929206d33a4fd30\tPagesCommands",
            "0:9fb67eacdcb4ef94f9c5c67787778a413328904fe7a3513fd921ee9881114632\tPagesSession",
            "0:379d5fffd72aa80b00e3f3dd73f0f748eeac311b5992de9b3cd3115b97cbb525\tPagesUtility",
            "0:694d24fe1aa0464859d21ce58a62875b80e16f6c36595f363e8b86b603bde7d4\tPagesAdmin",
            "0:9f1e5499529a00aad0990d2f7dd7d1bfd23e2d0939d4e739e2659dc27313819a\tStaticBackup"]);
        _add_data_file("legacy_hosts", [
            "0:4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981\tManualCommands",
            "0:41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420\tManualStatus",
            "0:41e37889496dce38efdeb5764cf088287171d72c523c370b37bb6b3621d1f93e\tManualSession",
            "0:4e5561b275d060ff0d0919ccc7e485d08c8e1fe9abd92af6cdf19ebfb2dd5421\tManualUtility",
            "0:650627a3165cea5c12558aaf9d38f791a33660792d41136e1a6dba48549ce89b\tManualAdmin"]);
        _add_data_file("magic", [
            "11"]);
        _add_data_file("motd", [
            "Welcome to Tonix.",
            "Type \"help\" to get a list of commands.",
            "\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.",
            "Some options for certain commands work as well.",
            "Feel free to navigate a pre-made file system using intuitive commands.",
            "Path resolution does not work yet, one step at a time please.",
            "Your feedback is greatly appreciated!",
            "Have fun :)"]);
        _add_data_file("mtab", [
            "/\tBlockDevice\t1\t1\t1"]);
        _add_data_file("passwd", [
            "root\t0\t0\troot\t/root",
            "boris\t1000\t1000\tstaff\t/home/boris",
            "ivan\t1001\t1000\tstaff\t/home/ivan",
            "guest\t10000\t10000\tguest\t/home/guest"]);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 3 + 3, 11, "/etc"));
    }
}
