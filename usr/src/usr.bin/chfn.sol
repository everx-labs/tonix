pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract chfn is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        out = "";
        err = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Not implemented",
"",
"",
"0.00");
    }
}
