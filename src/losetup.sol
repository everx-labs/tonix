pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract losetup is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
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
