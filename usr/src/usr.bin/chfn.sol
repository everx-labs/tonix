pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract chfn is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
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
