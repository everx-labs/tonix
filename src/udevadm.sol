pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract udevadm is Utility {

    function uadm(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            arg_list.push(Arg(s_arg, ft, index, parent, dir_index));
        }
        (out, ars, errors) = _udevadm(params, flags, wd, arg_list, sb.get_inode_count(inodes), inodes, data);
        ec = EXECUTE_SUCCESS;
    }

    function _udevadm(string[] params, string flags, uint16 wd, Arg[] arg_list, uint16 ic, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Ar[] ars, Err[] errors) {
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
