pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract umount is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }

        (out, file_action, ars, errors) = _umount(args, flags, session.wd, arg_list, sb.get_inode_count(inodes), inodes, data);
    }

    /* File manipulation operations - cp, ln and mv */
    function _umount(string[] args, uint flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
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
"",
"",
"0.01");
    }

}
