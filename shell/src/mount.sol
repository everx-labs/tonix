pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract mount is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }

        (out, file_action, ars, errors) = _mount(args, flags, session.wd, arg_list, _get_inode_count(inodes), inodes, data);
    }

    /* File manipulation operations - cp, ln and mv */
    function _mount(string[] args, uint flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
      return("mount", "mount a filesystem", "[-l]\t-a [-fnrvw]\t-[NTBM] <source> <directory>",
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
