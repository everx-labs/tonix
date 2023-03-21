pragma ton-solidity >= 0.67.0;

import "putil_base.sol";
import "inode.sol";
import "udirent.sol";
import "fs.sol";

abstract contract putil_stat is putil_base {
    function main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (shell_env e) {
        if (e_in.opt_value("help").empty())
            e = _main(e_in, inodes, data);
        else {
            e = e_in;
            e.puts(libhelp.usage(_command_help()));
        }
    }
    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure virtual returns (shell_env e);
    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }
    function _command_help() internal pure virtual returns (CommandHelp);
}