pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract udevadm is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }

        (out, file_action, ars, errors) = _udevadm(args, flags, session.wd, arg_list, _get_inode_count(inodes), inodes, data);
    }

    /* File manipulation operations - cp, ln and mv */
    function _udevadm(string[] args, uint flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        string[] empty;
        return("udevadm", "udev management tool", "info [options] [devpath]",
            "Expects a command and command specific options.",
            "", 1, M, empty);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"udevadm",
"info [options] [devpath]",
"udev management tool",
"Expects a command and command specific options.",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
