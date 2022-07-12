pragma ton-solidity >= 0.62.0;

import "putil.sol";

contract whoami is putil {

    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        e.puts(e.env_value("USER"));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"whoami",
"OPTION...",
"print effective userid",
"Print the user name associated with the current effective user ID. Same as id -un.",
"",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
