pragma ton-solidity >= 0.49.0;

import "ExportFS.sol";

/* Primary configuration files for a block device system initialization and error diagnostic data */
contract DataVolume is ExportFS {

    function _init() internal override accept {
        _fs = _get_fs(1, "exportfs", ["etc", "errors"]);
        _create_device(ROOT_DIR, DeviceInfo(BLK_DEVICE, _dc++, "DataVolume", 1024, 100, address(this)));

        /* Imported by an error printer */
        INodeS[] error_files = _files(
            ["reasons", "status", "internal"], [
            ["missing operand", "cannot remove", "cannot stat", "cannot access", "cannot create directory", "cannot open",
             "invalid option", "extra operand", "failed to remove", "missing operand after", "missing file operand",
             "missing destination file operand after", "invalid group", "missing filename", "invalid mode", "invalid owner",
             "cannot touch", "cannot create regular file", "too many arguments", "too many operands", "Try '--help' for more information",
             "failed to access", "-r not specified; omitting directory", "cannot overwrite directory with non-directory",
             "options -l and -s are incompatible", "target", "failed to create symbolic link", "failed to create hard link",
             "cannot make both hard and symbolic links", "hard link not allowed for directory",
             "mutually exclusive arguments: -c -n -r -z", "failed to locate login data"],
            ["No such file or directory", "File exists", "Not a directory", "Is a directory", "Permission denied",
             "Directory not empty", "Not owner", "Invalid argument", "Read-only file system", "Bad address", "Bad file number",
              "fd is not a valid open file descriptor", "Device busy", "Operation not applicable", "pathname is too long"],
            ["direntry not found", "inode not found", "parent direntry not found", "child direntry not found", "invalid user id", "invalid working directory"]]);
        _add_reg_files(ROOT_DIR + 2, error_files);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 4, uint16(error_files.length), "errors"));

        this.init2();
    }

    function init2() external accept {
        /* Inported to /etc by a block device system */
        INodeS[] etc_files = _files(["command_list", "exports", "fs_types", "mtab", "group", "hostname", "hosts", "magic", "motd", "passwd"], [
            ["account", "basename", "cat", "cd", "chgrp", "chmod", "chown","cksum", "cmp", "column", "cp", "cut", "dd", "df", "dirname",
             "du", "echo", "fallocate", "file", "findmnt", "fuser", "getent", "grep", "head", "help", "hostname", "id", "ln",
             "login", "logout", "ls", "lsblk", "lslogins", "lsof", "man", "mapfile", "mkdir", "mount", "mv", "namei", "paste", "ping",
             "ps", "pwd", "readlink", "realpath", "rm", "rmdir", "stat", "tail", "touch", "truncate", "uname", "wc", "whatis", "whoami"],
            ["SessionManager/usr/share/errors\t/usr/share/commands",
             "StatusReader\t/",
             "FileManager\t/"],
            ["?unknown",
             "-regular file",
             "ddirectory",
             "ccharacter special file",
             "bblock special file",
             "pfifo",
             "ssocket",
             "lsymbolic link"],
            ["DataVolume\t/usr/share/errors\t1\tdefaults",
             "ManualCommands\t/usr/share/commands\t1\tdefaults",
            "StatusManual\t/usr/share/commands\t1\tdefaults"],
            ["root\t0",
             "staff\t1000",
             "guest\t10000"],
            ["BlockDevice",
             "0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5"],
            ["0:47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40\tFileManager",
             "0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9\tStatusReader",
             "0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume",
             "0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice",
             "0:4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d\tSessionManager",
             "0:4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981\tManualCommands",
             "0:41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420\tManualStatus",
             "0:48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec\tPrintFormatted",
             "0:41e37889496dce38efdeb5764cf088287171d72c523c370b37bb6b3621d1f93e\tManualSession",
             "0:4e5561b275d060ff0d0919ccc7e485d08c8e1fe9abd92af6cdf19ebfb2dd5421\tManualUtility"],
            ["11"],
            ["Welcome to Tonix.",
             "Type \"help\" to get a list of commands.",
             "\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.",
             "Some options for certain commands work as well.",
             "Feel free to navigate a pre-made file system using intuitive commands.",
             "Path resolution does not work yet, one step at a time please.",
             "Your feedback is greatly appreciated!",
             "Have fun :)"],
            ["root\t0\t0\troot\t/root",
             "boris\t1000\t1000\tstaff\t/home/boris",
             "ivan\t1001\t1000\tstaff\t/home/ivan",
             "guest\t10000\t10000\tguest\t/home/guest"]]);
        _add_reg_files(ROOT_DIR + 1, etc_files);
        _sb_exports.push(_get_export_sb(ROOT_DIR + 4 + 3, uint16(etc_files.length), "etc"));
    }
}
