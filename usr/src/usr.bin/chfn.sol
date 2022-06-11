pragma ton-solidity >= 0.61.0;

import "putil.sol";

contract chfn is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
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
