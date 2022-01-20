pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract udevadm is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Action file_action, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = _get_env(args);
        Arg[] arg_list;
        for (string arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        (out, file_action, ars, errors) = _udevadm(params, flags, wd, arg_list, _get_inode_count(inodes), inodes, data);
        ec = EXECUTE_SUCCESS;
    }

    function _udevadm(string[] params, string flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
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
"not yet Written",
"",
"",
"0.00");
    }

}
