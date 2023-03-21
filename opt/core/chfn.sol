pragma ton-solidity >= 0.62.0;

import "putil.sol";

contract chfn is putil {

    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
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
