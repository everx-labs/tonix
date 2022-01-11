pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract losetup is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        out.append(_losetup(flags, args, inodes, data));      // 0
    }

    function _losetup(uint flags, string[] args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return("losetup", "set up and control loop devices", "[options]... [loopdev]",
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
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }


}
