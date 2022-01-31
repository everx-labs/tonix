pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract umount is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        if (!argv.empty() && !inodes.empty() && !data.empty())
            out = "";
//        ( , string[] params, string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"umount",
"-a [-dflnrv] {directory|device}...",
"unmount file systems",
"Detaches the mentioned file system(s) from the file hierarchy.",
"-a      unmount all filesystems\n\
-A      unmount all mountpoints for the given device in the current namespace\n\
-c      don't canonicalize paths\n\
-d      if mounted loop device, also free this loop device\n\
-f      force unmount (in case of an unreachable NFS system)\n\
-n      don't write to /etc/mtab\n\
-l      detach the filesystem now, clean up things later\n\
-R      recursively unmount a target with all its children\n\
-r      in case unmounting fails, try to remount read-only\n\
-v      say what is being done\n\
-q      suppress 'not mounted' error messages",
"",
"Written by Boris",
"Not yet implemented",
"",
"0.01");
    }

}
