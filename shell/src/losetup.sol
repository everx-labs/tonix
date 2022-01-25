pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract losetup is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        out.append(_losetup(flags, args, inodes, data));      // 0
    }

    function _losetup(uint flags, string[] args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"losetup",
"[options]... [loopdev]",
"set up and control loop devices",
"Associate loop devices with regular files or block devices, to detach loop devices, and to query the status of a loop device.",
"-a      list all used devices\n\
-d      detach one or more devices\n\
-D      detach all used devices\n\
-f      find first unused device\n\
-j      list all devices associated with <file>\n\
-L      avoid possible conflict between devices\n\
-P      create a partitioned loop device\n\
-r      set up a read-only loop device\n\
-v      verbose mode\n\
-l      list info about all or specified (default)\n\
-n      don't print headings for --list output",
"",
"Written by Boris",
"",
"",
"0.01");
    }


}
