pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract mount is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mount",
"[-l]\t-a [-fnrvw]\t-[NTBM] <source> <directory>",
"mount a filesystem",
"Attach the filesystem found on some device to the file tree",
"-a      mount all filesystems mentioned in fstab\n\
-c      don't canonicalize paths\n\
-f      dry run; skip the mount(2) syscall\n\
-T      alternative file to /etc/fstab\n\
-l      show also filesystem labels\n\
-n      don't write to /etc/mtab\n\
-r      mount the filesystem read-only\n\
-v      say what is being done\n\
-w      mount the filesystem read-write (default)\n\
-N      perform mount in another namespace\n\
-B      mount a subtree somewhere else\n\
-M      move a subtree to some other place",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
